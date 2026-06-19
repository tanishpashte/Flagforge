import 'dart:async';
import 'package:flutter/material.dart';
import 'flagforge_sdk.dart';

void main() {
  runApp(const FlagForgeExampleApp());
}

class FlagForgeExampleApp extends StatefulWidget {
  const FlagForgeExampleApp({super.key});

  @override
  State<FlagForgeExampleApp> createState() => _FlagForgeExampleAppState();
}

class _FlagForgeExampleAppState extends State<FlagForgeExampleApp> {
  // Instantiate FlagForgeClient
  final FlagForgeClient _client = FlagForgeClient();
  Timer? _mockUpdateTimer;

  @override
  void initState() {
    super.initState();
    // Default mock data to populate client cache map
    _client.setFlag('dark_mode', true);
    _client.setFlag('premium_theme', false);
    _client.setFlag('show_banner', true);
    _client.setConfig('banner_message', 'Welcome to FlagForge Client-Side Cache Injection!');
    _client.setConfig('theme_accent_color', '#89B4FA');

    // Simulate real-time local update to verify visual transformations
    _mockUpdateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _client.setFlag('premium_theme', true);
        _client.setConfig(
          'banner_message',
          'UI successfully transformed via local client state update!',
        );
      }
    });
  }

  @override
  void dispose() {
    _mockUpdateTimer?.cancel();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _client,
      builder: (context, child) {
        final darkMode = _client.isEnabled('dark_mode', defaultValue: true);
        final premiumTheme = _client.isEnabled('premium_theme', defaultValue: false);
        final showBanner = _client.isEnabled('show_banner', defaultValue: true);
        final bannerMessage = _client.getConfigValue('banner_message', defaultValue: 'Welcome to FlagForge Static Preview!');
        final accentColorHex = _client.getConfigValue('theme_accent_color', defaultValue: '#89B4FA');

        // Dynamically parse hex color
        Color accentColor = const Color(0xFF89B4FA);
        try {
          final hex = accentColorHex.replaceAll('#', '');
          if (hex.length == 6) {
            accentColor = Color(int.parse('FF$hex', radix: 16));
          } else if (hex.length == 8) {
            accentColor = Color(int.parse(hex, radix: 16));
          }
        } catch (_) {}

        return MaterialApp(
          title: 'FlagForge SDK Shell',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: darkMode ? Brightness.dark : Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: accentColor,
              brightness: darkMode ? Brightness.dark : Brightness.light,
              surface: darkMode ? const Color(0xFF0F0F1A) : const Color(0xFFF4F5FA),
            ),
            fontFamily: 'Outfit',
          ),
          home: DashboardScreen(
            client: _client,
            darkMode: darkMode,
            premiumTheme: premiumTheme,
            showBanner: showBanner,
            bannerMessage: bannerMessage,
            accentColor: accentColor,
            accentColorHex: accentColorHex,
          ),
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final FlagForgeClient client;
  final bool darkMode;
  final bool premiumTheme;
  final bool showBanner;
  final String bannerMessage;
  final Color accentColor;
  final String accentColorHex;

  const DashboardScreen({
    super.key,
    required this.client,
    required this.darkMode,
    required this.premiumTheme,
    required this.showBanner,
    required this.bannerMessage,
    required this.accentColor,
    required this.accentColorHex,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late final TextEditingController _textController;
  late final TextEditingController _colorController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.bannerMessage);
    _colorController = TextEditingController(text: widget.accentColorHex);
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bannerMessage != _textController.text && !_textController.value.isComposingRangeValid) {
      final oldSelection = _textController.selection;
      _textController.text = widget.bannerMessage;
      if (oldSelection.isValid && oldSelection.end <= widget.bannerMessage.length) {
        _textController.selection = oldSelection;
      }
    }
    if (widget.accentColorHex != _colorController.text && !_colorController.value.isComposingRangeValid) {
      final oldSelection = _colorController.selection;
      _colorController.text = widget.accentColorHex;
      if (oldSelection.isValid && oldSelection.end <= widget.accentColorHex.length) {
        _colorController.selection = oldSelection;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.darkMode ? const Color(0xFFE2E4F0) : const Color(0xFF2E303F);
    final subtitleColor = widget.darkMode ? const Color(0xFF8A8DAB) : const Color(0xFF6E7191);

    final pages = [
      _buildOverviewTab(textColor, subtitleColor),
      _buildFlagsTab(textColor, subtitleColor),
      _buildConfigsTab(textColor, subtitleColor),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFFFB600), size: 28),
            const SizedBox(width: 6),
            Text(
              'FLAGFORGE SHELL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: textColor,
              ),
            ),
          ],
        ),
        backgroundColor: widget.darkMode ? const Color(0xFF0A0A12) : const Color(0xFFEBEBFF),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26), // 0.1 opacity
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withAlpha(77), width: 1), // 0.3 opacity
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE SDK CLIENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue[300] ?? Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.toggle_on_rounded),
            label: 'Feature Flags',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Configs',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Color textColor, Color subtitleColor) {
    final isDark = widget.darkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner preview if enabled
          if (widget.showBanner) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.accentColor, widget.accentColor.withAlpha(179)], // 0.7 opacity
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withAlpha(77), // 0.3 opacity
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Color(0xFF11111B), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.bannerMessage,
                      style: const TextStyle(
                        color: Color(0xFF11111B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Visual Sandbox Wrapper representing the dynamic styles
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.premiumTheme
                    ? [const Color(0xFF302B63), const Color(0xFF240B36)]
                    : isDark
                        ? [const Color(0xFF1B1B2F), const Color(0xFF252545)]
                        : [Colors.white, const Color(0xFFECEBFF)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.premiumTheme
                    ? const Color(0xFFFFD54F)
                    : widget.accentColor.withAlpha(77), // 0.3 opacity
                width: widget.premiumTheme ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.premiumTheme
                      ? const Color(0xFFFFD54F).withAlpha(38) // 0.15 opacity
                      : Colors.black.withAlpha(10), // 0.04 opacity
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.premiumTheme ? '💎 PREMIUM CLIENT CARD' : '📱 STANDARD CLIENT CARD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: widget.premiumTheme ? const Color(0xFFFFD54F) : textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Evaluates mock flag states locally',
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                      ],
                    ),
                    if (widget.premiumTheme)
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 32),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: textColor.withAlpha(10), // 0.04 opacity
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIndicator(
                        title: 'premium_theme',
                        active: widget.premiumTheme,
                        icon: Icons.palette_rounded,
                      ),
                      _buildIndicator(
                        title: 'show_banner',
                        active: widget.showBanner,
                        icon: Icons.announcement_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Overview status message card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Local Cache Active',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This screen is connected directly to the FlagForgeClient local cache map. Navigate to the Feature Flags or Configs tabs to toggle styles, modify configurations, and see updates instantly reflected.',
                    style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required String title, required bool active, required IconData icon}) {
    final color = active ? const Color(0xFF00C853) : Colors.grey[500];

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              active ? 'TRUE' : 'FALSE',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlagsTab(Color textColor, Color subtitleColor) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          ' Feature Flags (Mock)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
        ),
        const SizedBox(height: 8),
        Text(
          'Tapping toggles their state in the layout instantly.',
          style: TextStyle(fontSize: 12, color: subtitleColor),
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          title: 'dark_mode',
          description: 'Alters global layout theme to dark.',
          value: widget.darkMode,
          onChanged: (val) => widget.client.setFlag('dark_mode', val),
        ),
        const Divider(),
        _buildSwitchTile(
          title: 'premium_theme',
          description: 'Enables high-fidelity purple gradient background on card.',
          value: widget.premiumTheme,
          onChanged: (val) => widget.client.setFlag('premium_theme', val),
        ),
        const Divider(),
        _buildSwitchTile(
          title: 'show_banner',
          description: 'Toggle visibility of the dynamic top campaign banner.',
          value: widget.showBanner,
          onChanged: (val) => widget.client.setFlag('show_banner', val),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildConfigsTab(Color textColor, Color subtitleColor) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          '⚙ Remote Configs (Mock)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
        ),
        const SizedBox(height: 8),
        Text(
          'Update remote configuration mock values below.',
          style: TextStyle(fontSize: 12, color: subtitleColor),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'banner_message (string)',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => widget.client.setConfig('banner_message', val),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _colorController,
          decoration: const InputDecoration(
            labelText: 'theme_accent_color (string hex)',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => widget.client.setConfig('theme_accent_color', val),
        ),
      ],
    );
  }
}
