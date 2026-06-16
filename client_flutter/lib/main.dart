import 'dart:async';
import 'package:flutter/material.dart';
import 'flagforge_sdk.dart';
import 'sdk/models.dart';

void main() {
  runApp(const FlagForgeExampleApp());
}

class FlagForgeExampleApp extends StatelessWidget {
  const FlagForgeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlagForge SDK Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF89B4FA),
          brightness: Brightness.dark,
          background: const Color(0xFF181825),
          surface: const Color(0xFF1E1E2E),
        ),
        fontFamily: 'Outfit',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _hostController = TextEditingController(text: 'localhost:8000');
  final TextEditingController _projectIdController = TextEditingController(text: '1');

  FlagForgeClient? _client;
  bool _isConnecting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _connectSDK();
  }

  Future<void> _connectSDK() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting...';
    });

    // Clean up existing client connection
    if (_client != null) {
      _client!.removeListener(_onClientUpdate);
      _client!.dispose();
    }

    final host = _hostController.text.trim();
    final projectId = int.tryParse(_projectIdController.text.trim()) ?? 1;

    _client = FlagForgeClient(
      host: host,
    );

    try {
      await _client!.initialize(projectId);
      _client!.addListener(_onClientUpdate);

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Connected';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  void _onClientUpdate() {
    if (mounted) {
      setState(() {
        _statusMessage = 'Updated: ${DateTime.now().toLocal().toString().split('.').first.split(' ').last}';
      });
    }
  }

  @override
  void dispose() {
    _client?.removeListener(_onClientUpdate);
    _client?.dispose();
    _hostController.dispose();
    _projectIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasClient = _client != null;
    final List<FeatureFlag> flags = hasClient ? _client!.getAllFlags() : [];
    final List<RemoteConfig> configs = hasClient ? _client!.getAllConfigs() : [];

    // Evaluate live SDK parameters for dynamic UI styling
    final bool enablePremiumTheme = _client?.isEnabled('premium_theme', defaultValue: false) ?? false;
    final bool enableBanner = _client?.isEnabled('show_banner', defaultValue: false) ?? false;
    final String bannerText = _client?.getConfigValue('banner_message', defaultValue: 'Welcome to FlagForge!') ?? '';
    final String dynamicThemeColorStr = _client?.getConfigValue('theme_accent_color', defaultValue: '#89B4FA') ?? '#89B4FA';
    
    // Parse hex color dynamically
    Color accentColor = const Color(0xFF89B4FA);
    try {
      final hex = dynamicThemeColorStr.replaceAll('#', '');
      if (hex.length == 6) {
        accentColor = Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        accentColor = Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFF9E2AF)),
            const SizedBox(width: 8),
            const Text(
              'FLAGFORGE SDK SHELL',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF11111B),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnecting
                  ? Colors.amber.withOpacity(0.15)
                  : _statusMessage?.startsWith('Error') == true
                      ? Colors.red.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isConnecting
                    ? Colors.amber
                    : _statusMessage?.startsWith('Error') == true
                        ? Colors.red
                        : Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnecting
                        ? Colors.amber
                        : _statusMessage?.startsWith('Error') == true
                            ? Colors.red
                            : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusMessage ?? 'Disconnected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isConnecting
                        ? Colors.amber
                        : _statusMessage?.startsWith('Error') == true
                            ? Colors.red[300]
                            : Colors.green[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Setup & Connection Panel
              Card(
                color: const Color(0xFF1E1E2E),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF313244)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔌 Connection Setup',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _hostController,
                              decoration: InputDecoration(
                                labelText: 'Backend Host',
                                hintText: 'localhost:8000',
                                prefixIcon: const Icon(Icons.dns),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _projectIdController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Project ID',
                                hintText: '1',
                                prefixIcon: const Icon(Icons.tag),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isConnecting ? null : _connectSDK,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF89B4FA),
                              foregroundColor: const Color(0xFF11111B),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.sync),
                            label: const Text('Connect'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Preview Box affected by current flag evaluations
              if (enableBanner) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign, color: Color(0xFF11111B), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bannerText,
                          style: const TextStyle(
                            color: Color(0xFF11111B),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Application Simulated Visual Sandbox
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: enablePremiumTheme
                        ? [const Color(0xFF302b63), const Color(0xFF240b36)]
                        : [const Color(0xFF181825), const Color(0xFF1e1e2e)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: enablePremiumTheme ? const Color(0xFFF9E2AF) : const Color(0xFF313244),
                    width: enablePremiumTheme ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enablePremiumTheme ? '💎 PREMIUM CLIENT UI' : '📱 STANDARD CLIENT UI',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: enablePremiumTheme ? const Color(0xFFF9E2AF) : Colors.white,
                                ),
                              ),
                              const Text(
                                'Evaluates values straight from the SDK cache',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          if (enablePremiumTheme)
                            const Icon(Icons.workspace_premium, color: Color(0xFFF9E2AF), size: 28),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildEvaluationIndicator(
                              title: 'premium_theme',
                              isActive: enablePremiumTheme,
                              icon: Icons.palette,
                            ),
                            _buildEvaluationIndicator(
                              title: 'show_banner',
                              isActive: enableBanner,
                              icon: Icons.announcement,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Section: Lists of currently stored Flags and Configs
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature Flags List Panel
                  Expanded(
                    child: _buildSectionCard(
                      title: ' Feature Flags (${flags.length})',
                      child: flags.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No feature flags active', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: flags.length,
                              separatorBuilder: (_, __) => const Divider(color: Color(0xFF313244)),
                              itemBuilder: (context, index) {
                                final flag = flags[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    flag.key,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  subtitle: flag.description != null && flag.description!.isNotEmpty
                                      ? Text(flag.description!, style: const TextStyle(fontSize: 12, color: Colors.grey))
                                      : null,
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: flag.isEnabled
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      flag.isEnabled ? 'ON' : 'OFF',
                                      style: TextStyle(
                                        color: flag.isEnabled ? Colors.greenAccent : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Remote Configurations List Panel
                  Expanded(
                    child: _buildSectionCard(
                      title: '⚙ Remote Configs (${configs.length})',
                      child: configs.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No remote configs active', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: configs.length,
                              separatorBuilder: (_, __) => const Divider(color: Color(0xFF313244)),
                              itemBuilder: (context, index) {
                                final cfg = configs[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    cfg.key,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    'Type: ${cfg.valueType.name}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        cfg.value,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '(${cfg.typedValue.runtimeType})',
                                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationIndicator({
    required String title,
    required bool isActive,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFFA6E3A1) : Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
            Text(
              isActive ? 'EVALUATES TRUE' : 'EVALUATES FALSE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFFA6E3A1) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      color: const Color(0xFF1E1E2E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF313244)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCDD6F4),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
