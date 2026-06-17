import 'package:flutter/material.dart';

void main() {
  runApp(const FlagForgeExampleApp());
}

class FlagForgeExampleApp extends StatefulWidget {
  const FlagForgeExampleApp({super.key});

  @override
  State<FlagForgeExampleApp> createState() => _FlagForgeExampleAppState();
}

class _FlagForgeExampleAppState extends State<FlagForgeExampleApp> {
  // Local state representing mock flags and configs (No networking / no state management)
  bool _darkMode = true;
  bool _premiumTheme = false;
  bool _showBanner = true;
  String _bannerMessage = 'Welcome to FlagForge Static Preview!';
  String _accentColorHex = '#89B4FA';

  // Local state updates
  void _toggleDarkMode() {
    setState(() {
      _darkMode = !_darkMode;
    });
  }

  void _togglePremiumTheme() {
    setState(() {
      _premiumTheme = !_premiumTheme;
    });
  }

  void _toggleShowBanner() {
    setState(() {
      _showBanner = !_showBanner;
    });
  }

  void _updateBannerMessage(String msg) {
    setState(() {
      _bannerMessage = msg;
    });
  }

  void _updateAccentColor(String hex) {
    setState(() {
      _accentColorHex = hex;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically parse hex color
    Color accentColor = const Color(0xFF89B4FA);
    try {
      final hex = _accentColorHex.replaceAll('#', '');
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
        brightness: _darkMode ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: _darkMode ? Brightness.dark : Brightness.light,
          surface: _darkMode ? const Color(0xFF0F0F1A) : const Color(0xFFF4F5FA),
        ),
        fontFamily: 'Outfit',
      ),
      home: DashboardScreen(
        darkMode: _darkMode,
        premiumTheme: _premiumTheme,
        showBanner: _showBanner,
        bannerMessage: _bannerMessage,
        accentColor: accentColor,
        accentColorHex: _accentColorHex,
        onToggleDarkMode: _toggleDarkMode,
        onTogglePremiumTheme: _togglePremiumTheme,
        onToggleShowBanner: _toggleShowBanner,
        onUpdateBannerMessage: _updateBannerMessage,
        onUpdateAccentColor: _updateAccentColor,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final bool darkMode;
  final bool premiumTheme;
  final bool showBanner;
  final String bannerMessage;
  final Color accentColor;
  final String accentColorHex;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onTogglePremiumTheme;
  final VoidCallback onToggleShowBanner;
  final ValueChanged<String> onUpdateBannerMessage;
  final ValueChanged<String> onUpdateAccentColor;

  const DashboardScreen({
    super.key,
    required this.darkMode,
    required this.premiumTheme,
    required this.showBanner,
    required this.bannerMessage,
    required this.accentColor,
    required this.accentColorHex,
    required this.onToggleDarkMode,
    required this.onTogglePremiumTheme,
    required this.onToggleShowBanner,
    required this.onUpdateBannerMessage,
    required this.onUpdateAccentColor,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

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
                  'STATIC SKELETON',
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
                    '📍 Offline Sandbox Instructions',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This is a static visual skeleton layout. Navigate to the Feature Flags or Configs tabs at the bottom to toggle styles locally and preview changes in real time.',
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
          onChanged: (_) => widget.onToggleDarkMode(),
        ),
        const Divider(),
        _buildSwitchTile(
          title: 'premium_theme',
          description: 'Enables high-fidelity purple gradient background on card.',
          value: widget.premiumTheme,
          onChanged: (_) => widget.onTogglePremiumTheme(),
        ),
        const Divider(),
        _buildSwitchTile(
          title: 'show_banner',
          description: 'Toggle visibility of the dynamic top campaign banner.',
          value: widget.showBanner,
          onChanged: (_) => widget.onToggleShowBanner(),
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
    final textController = TextEditingController(text: widget.bannerMessage);
    final colorController = TextEditingController(text: widget.accentColorHex);

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
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'banner_message (string)',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => widget.onUpdateBannerMessage(val),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: colorController,
          decoration: const InputDecoration(
            labelText: 'theme_accent_color (string hex)',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => widget.onUpdateAccentColor(val),
        ),
      ],
    );
  }
}
