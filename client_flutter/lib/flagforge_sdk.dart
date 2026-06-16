import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'sdk/models.dart';

class FlagForgeClient extends ChangeNotifier {
  final String host; // e.g. 'localhost:8000'

  // Internal memory cache as requested by the specification
  final Map<String, dynamic> _flags = {};
  final Map<String, dynamic> _configs = {};

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isInitialized = false;
  bool _isDisposed = false;

  FlagForgeClient({
    this.host = 'localhost:8000',
  });

  bool get isInitialized => _isInitialized;

  // Clean getter for evaluated flags
  bool isEnabled(String key, {bool defaultValue = false}) {
    final flag = _flags[key];
    if (flag == null) return defaultValue;
    if (flag is bool) return flag;
    if (flag is Map<String, dynamic>) {
      return flag['is_enabled'] as bool? ?? defaultValue;
    }
    if (flag is FeatureFlag) {
      return flag.isEnabled;
    }
    return defaultValue;
  }

  // Clean getter for evaluated configurations
  dynamic getConfigValue(String key, {dynamic defaultValue}) {
    final config = _configs[key];
    if (config == null) return defaultValue;
    if (config is RemoteConfig) {
      return config.typedValue;
    }
    if (config is Map<String, dynamic>) {
      final value = config['value']?.toString() ?? '';
      final valueType = config['value_type'] as String? ?? 'string';
      switch (valueType.toLowerCase()) {
        case 'boolean':
          return value.toLowerCase() == 'true' || value == '1';
        case 'number':
          return num.tryParse(value) ?? value;
        case 'string':
        default:
          return value;
      }
    }
    return config;
  }

  // Bridging methods to retrieve typed lists for visual rendering in main.dart
  List<FeatureFlag> getAllFlags() {
    return _flags.values.map((item) {
      if (item is FeatureFlag) return item;
      return FeatureFlag.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  List<RemoteConfig> getAllConfigs() {
    return _configs.values.map((item) {
      if (item is RemoteConfig) return item;
      return RemoteConfig.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  /// REST Hydration and WebSocket startup
  Future<void> initialize(int projectId) async {
    if (_isInitialized) return;

    final hostClean = host.replaceAll('http://', '').replaceAll('https://', '');

    try {
      // 1. Fetch baseline flags
      final flagsUrl = Uri.parse('http://$hostClean/api/flags/?project_id=$projectId');
      final flagsResponse = await http.get(flagsUrl);
      if (flagsResponse.statusCode == 200) {
        final List<dynamic> flagsJson = jsonDecode(flagsResponse.body);
        _flags.clear();
        for (var item in flagsJson) {
          final map = item as Map<String, dynamic>;
          final key = map['key'] as String;
          _flags[key] = map;
        }
      } else {
        throw Exception('Failed to load baseline flags: Status ${flagsResponse.statusCode}');
      }

      // 2. Fetch baseline configurations
      final configsUrl = Uri.parse('http://$hostClean/api/configs/?project_id=$projectId');
      final configsResponse = await http.get(configsUrl);
      if (configsResponse.statusCode == 200) {
        final List<dynamic> configsJson = jsonDecode(configsResponse.body);
        _configs.clear();
        for (var item in configsJson) {
          final map = item as Map<String, dynamic>;
          final key = map['key'] as String;
          _configs[key] = map;
        }
      } else {
        throw Exception('Failed to load baseline configs: Status ${configsResponse.statusCode}');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('FlagForgeClient warning: initial hydration failed: $e');
      _isInitialized = true; // Fallback initialization
      notifyListeners();
    }

    // Immediately establish WebSocket stream link
    _connectWebSocket(projectId);
  }

  /// Connects to real-time updates via WebSocket stream
  void _connectWebSocket(int projectId) {
    if (_isDisposed) return;

    final hostClean = host.replaceAll('http://', '').replaceAll('https://', '');
    final wsUri = Uri.parse('ws://$hostClean/api/stream/$projectId');

    print('FlagForgeClient: Establishing real-time link at $wsUri');

    try {
      _channel = WebSocketChannel.connect(wsUri);
      _subscription = _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('FlagForgeClient WebSocket error: $error');
          _reconnect(projectId);
        },
        onDone: () {
          print('FlagForgeClient WebSocket disconnected');
          _reconnect(projectId);
        },
      );
    } catch (e) {
      print('FlagForgeClient WebSocket connect exception: $e');
      _reconnect(projectId);
    }
  }

  void _reconnect(int projectId) {
    if (_isDisposed) return;
    _subscription?.cancel();
    _channel = null;

    Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        print('FlagForgeClient: Reconnecting to stream...');
        _connectWebSocket(projectId);
      }
    });
  }

  /// Processes raw incoming string updates and updates the local cache
  void _handleWebSocketMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message as String);
      final String? type = data['type'] as String?;
      final String? key = data['key'] as String?;
      final String? action = data['action'] as String?;

      if (key == null || type == null) return;

      if (type == 'flag') {
        final isEnabled = data['is_enabled'] as bool? ?? false;
        if (action == 'update') {
          final existing = _flags[key];
          if (existing is Map<String, dynamic>) {
            final updated = Map<String, dynamic>.from(existing);
            updated['is_enabled'] = isEnabled;
            updated['updated_at'] = DateTime.now().toIso8601String();
            _flags[key] = updated;
          } else {
            _flags[key] = {
              'key': key,
              'is_enabled': isEnabled,
              'description': 'Real-time updated flag',
              'project_id': 0,
            };
          }
        }
      } else if (type == 'config') {
        final val = data['value']?.toString() ?? '';
        final valTypeStr = data['value_type'] as String? ?? 'string';

        if (action == 'update') {
          final existing = _configs[key];
          if (existing is Map<String, dynamic>) {
            final updated = Map<String, dynamic>.from(existing);
            updated['value'] = val;
            updated['value_type'] = valTypeStr;
            updated['updated_at'] = DateTime.now().toIso8601String();
            _configs[key] = updated;
          } else {
            _configs[key] = {
              'key': key,
              'value': val,
              'value_type': valTypeStr,
              'description': 'Real-time updated config',
              'project_id': 0,
            };
          }
        } else if (action == 'delete') {
          _configs.remove(key);
        }
      }

      // Notify the widgets that build or listen to this ChangeNotifier
      notifyListeners();
    } catch (e) {
      print('FlagForgeClient warning: error parsing incoming frame: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
