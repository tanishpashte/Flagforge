import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'models.dart';

class FlagForgeClient {
  final String host; // e.g., 'localhost:8000' or '10.0.2.2:8000'
  final int projectId;
  final bool useHttps;

  final Map<String, FeatureFlag> _flags = {};
  final Map<String, RemoteConfig> _configs = {};

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Stream for notifying the example application of live config or flag updates
  final StreamController<void> _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  FlagForgeClient({
    required this.host,
    required this.projectId,
    this.useHttps = false,
  });

  bool get isInitialized => _isInitialized;

  String get _httpScheme => useHttps ? 'https' : 'http';
  String get _wsScheme => useHttps ? 'wss' : 'ws';

  /// Hydrates the local cache via REST API, then establishes a persistent WebSocket connection.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _hydrateCache();
      _isInitialized = true;
      _connectWebSocket();
    } catch (e) {
      // Print or handle error. The client will still try to establish WebSocket and function.
      print('FlagForgeClient: Initialization warning/error: $e');
      _isInitialized = true; // Mark initialized so app doesn't hang, even if offline
      _connectWebSocket();
    }
  }

  /// REST data hydration
  Future<void> _hydrateCache() async {
    final flagsUrl = Uri(
      scheme: _httpScheme,
      host: host.contains(':') ? host.split(':').first : host,
      port: host.contains(':') ? int.tryParse(host.split(':').last) : null,
      path: '/api/flags/',
      queryParameters: {'project_id': projectId.toString()},
    );

    final configsUrl = Uri(
      scheme: _httpScheme,
      host: host.contains(':') ? host.split(':').first : host,
      port: host.contains(':') ? int.tryParse(host.split(':').last) : null,
      path: '/api/configs/',
      queryParameters: {'project_id': projectId.toString()},
    );

    // Fetch flags
    final flagsResponse = await http.get(flagsUrl);
    if (flagsResponse.statusCode == 200) {
      final List<dynamic> flagsJson = jsonDecode(flagsResponse.body);
      _flags.clear();
      for (var item in flagsJson) {
        final flag = FeatureFlag.fromJson(item as Map<String, dynamic>);
        _flags[flag.key] = flag;
      }
    } else {
      throw Exception('Failed to load flags: Status Code ${flagsResponse.statusCode}');
    }

    // Fetch configs
    final configsResponse = await http.get(configsUrl);
    if (configsResponse.statusCode == 200) {
      final List<dynamic> configsJson = jsonDecode(configsResponse.body);
      _configs.clear();
      for (var item in configsJson) {
        final config = RemoteConfig.fromJson(item as Map<String, dynamic>);
        _configs[config.key] = config;
      }
    } else {
      throw Exception('Failed to load remote configs: Status Code ${configsResponse.statusCode}');
    }
  }

  /// Persistent real-time subscription via WebSockets
  void _connectWebSocket() {
    if (_isDisposed) return;

    final wsUri = Uri(
      scheme: _wsScheme,
      host: host.contains(':') ? host.split(':').first : host,
      port: host.contains(':') ? int.tryParse(host.split(':').last) : null,
      path: '/api/stream/$projectId',
    );

    print('FlagForgeClient: Connecting to stream at $wsUri');

    try {
      _wsChannel = WebSocketChannel.connect(wsUri);
      _wsSubscription = _wsChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('FlagForgeClient: WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: () {
          print('FlagForgeClient: WebSocket connection closed');
          _reconnectWebSocket();
        },
      );
    } catch (e) {
      print('FlagForgeClient: WebSocket connection exception: $e');
      _reconnectWebSocket();
    }
  }

  /// Reconnection logic with dynamic delay
  void _reconnectWebSocket() {
    if (_isDisposed) return;
    _wsSubscription?.cancel();
    _wsChannel = null;

    Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        print('FlagForgeClient: Attempting to reconnect to WebSocket...');
        _connectWebSocket();
      }
    });
  }

  /// Parse WebSocket incoming frames and update local cache
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
          if (existing != null) {
            _flags[key] = existing.copyWith(isEnabled: isEnabled, updatedAt: DateTime.now());
          } else {
            _flags[key] = FeatureFlag(
              key: key,
              isEnabled: isEnabled,
              projectId: projectId,
              updatedAt: DateTime.now(),
            );
          }
        }
      } else if (type == 'config') {
        final val = data['value']?.toString() ?? '';
        final valTypeStr = data['value_type'] as String? ?? 'string';
        final valType = ConfigType.fromString(valTypeStr);

        if (action == 'update') {
          final existing = _configs[key];
          if (existing != null) {
            _configs[key] = existing.copyWith(
              value: val,
              valueType: valType,
              updatedAt: DateTime.now(),
            );
          } else {
            _configs[key] = RemoteConfig(
              key: key,
              value: val,
              valueType: valType,
              projectId: projectId,
              updatedAt: DateTime.now(),
            );
          }
        } else if (action == 'delete') {
          _configs.remove(key);
        }
      }

      // Trigger change notification to rendering application
      _updateController.add(null);
    } catch (e) {
      print('FlagForgeClient: Error handling WebSocket frame: $e');
    }
  }

  // SDK Evaluation API methods

  /// Get the boolean status of a feature flag
  bool isEnabled(String key, {bool defaultValue = false}) {
    final flag = _flags[key];
    return flag != null ? flag.isEnabled : defaultValue;
  }

  /// Get the parsed value of a remote configuration
  dynamic getConfigValue(String key, {dynamic defaultValue}) {
    final config = _configs[key];
    return config != null ? config.typedValue : defaultValue;
  }

  /// Gets all active feature flags in the cache
  List<FeatureFlag> getAllFlags() => _flags.values.toList();

  /// Gets all active remote configurations in the cache
  List<RemoteConfig> getAllConfigs() => _configs.values.toList();

  /// Releases resources
  void dispose() {
    _isDisposed = true;
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    _updateController.close();
  }
}
