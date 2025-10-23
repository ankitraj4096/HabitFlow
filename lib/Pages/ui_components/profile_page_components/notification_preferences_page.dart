import 'package:demo/services/notification_preferences.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  final NotificationPreferences _prefs = NotificationPreferences();

  ProgressBarStyle _selectedStyle = ProgressBarStyle.thickBlocks;
  bool _showPercentage = true;
  bool _showElapsedTime = false;
  bool _showTotalTime = false;
  bool _showSystemProgressBar = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final style = await _prefs.getProgressBarStyle();
    final showPercent = await _prefs.getShowPercentage();
    final showElapsed = await _prefs.getShowElapsedTime();
    final showTotal = await _prefs.getShowTotalTime();
    final showSystem = await _prefs.getShowSystemProgressBar();

    setState(() {
      _selectedStyle = style;
      _showPercentage = showPercent;
      _showElapsedTime = showElapsed;
      _showTotalTime = showTotal;
      _showSystemProgressBar = showSystem;
    });
  }

  Future<void> _savePreferences() async {
    await _prefs.setProgressBarStyle(_selectedStyle);
    await _prefs.setShowPercentage(_showPercentage);
    await _prefs.setShowElapsedTime(_showElapsedTime);
    await _prefs.setShowTotalTime(_showTotalTime);
    await _prefs.setShowSystemProgressBar(_showSystemProgressBar);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification preferences saved!'),
          backgroundColor: context.read<TierThemeProvider>().primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Style'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tierProvider.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Progress Bar Style Section
            _buildSectionTitle('Progress Bar Style'),
            _buildProgressBarOptions(tierProvider),

            const SizedBox(height: 24),

            // Display Options Section
            _buildSectionTitle('Display Options'),
            _buildDisplayOptions(tierProvider),

            const SizedBox(height: 24),

            // Preview Section
            _buildSectionTitle('Preview'),
            _buildPreview(tierProvider),

            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(tierProvider),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildProgressBarOptions(TierThemeProvider tierProvider) {
    return Column(
      children: ProgressBarStyle.values.map((style) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedStyle == style
                  ? tierProvider.primaryColor
                  : Colors.grey.shade300,
              width: _selectedStyle == style ? 2 : 1,
            ),
            color: _selectedStyle == style
                ? tierProvider.primaryColor.withValues(alpha: 0.05)
                : Colors.white,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tierProvider.gradientColors
                      .map((c) => c.withValues(alpha: 0.15))
                      .toList(),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _selectedStyle == style
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: tierProvider.primaryColor,
              ),
            ),
            title: Text(
              _getStyleName(style),
              style: TextStyle(
                fontWeight: _selectedStyle == style
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              _getStylePreview(style, 60),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'monospace',
                letterSpacing: 0,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedStyle = style;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplayOptions(TierThemeProvider tierProvider) {
    return Column(
      children: [
        _buildSwitchTile(
          tierProvider,
          title: 'Show Percentage',
          subtitle: 'Display completion percentage',
          value: _showPercentage,
          onChanged: (value) => setState(() => _showPercentage = value),
        ),
        _buildSwitchTile(
          tierProvider,
          title: 'Show Elapsed Time',
          subtitle: 'Display time already passed',
          value: _showElapsedTime,
          onChanged: (value) => setState(() => _showElapsedTime = value),
        ),
        _buildSwitchTile(
          tierProvider,
          title: 'Show Total Duration',
          subtitle: 'Display total timer duration',
          value: _showTotalTime,
          onChanged: (value) => setState(() => _showTotalTime = value),
        ),
        _buildSwitchTile(
          tierProvider,
          title: 'System Progress Bar',
          subtitle: 'Show Android\'s blue progress bar',
          value: _showSystemProgressBar,
          onChanged: (value) => setState(() => _showSystemProgressBar = value),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    TierThemeProvider tierProvider, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        value: value,
        onChanged: onChanged,
        activeColor: tierProvider.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPreview(TierThemeProvider tierProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tierProvider.gradientColors
              .map((c) => c.withValues(alpha: 0.1))
              .toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierProvider.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: tierProvider.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Morning Exercise',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '10:00 remaining',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            _getStylePreview(_selectedStyle, 60),
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'monospace',
              letterSpacing: 0,
            ),
          ),
          if (_showPercentage) ...[
            const SizedBox(height: 4),
            Text('33% complete', style: TextStyle(color: Colors.grey.shade600)),
          ],
          if (_showElapsedTime) ...[
            const SizedBox(height: 4),
            Text(
              '⏱️ Elapsed: 05:00',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          if (_showTotalTime) ...[
            const SizedBox(height: 4),
            Text(
              '🎯 Total: 15:00',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          if (_showSystemProgressBar) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.33,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                tierProvider.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(TierThemeProvider tierProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: tierProvider.gradientColors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: _savePreferences,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Save Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getStyleName(ProgressBarStyle style) {
    switch (style) {
      case ProgressBarStyle.squareBlocks:
        return 'Square Blocks';
      case ProgressBarStyle.circles:
        return 'Circles';
      case ProgressBarStyle.triangles:
        return 'Triangles';
      case ProgressBarStyle.squares:
        return 'Filled Squares';
      case ProgressBarStyle.diamonds:
        return 'Diamonds';
      case ProgressBarStyle.arrows:
        return 'Arrows';
      case ProgressBarStyle.thickBlocks:
        return 'Thick Blocks';
      case ProgressBarStyle.dots:
        return 'Dots';
    }
  }

  String _getStylePreview(ProgressBarStyle style, int percent) {
    final filled = (percent / 5).round();
    final empty = 20 - filled;

    switch (style) {
      case ProgressBarStyle.squareBlocks:
        return '▓' * filled + '░' * empty;
      case ProgressBarStyle.circles:
        return '●' * filled + '○' * empty;
      case ProgressBarStyle.triangles:
        return '▶' * filled + '▷' * empty;
      case ProgressBarStyle.squares:
        return '■' * filled + '□' * empty;
      case ProgressBarStyle.diamonds:
        return '◆' * filled + '◇' * empty;
      case ProgressBarStyle.arrows:
        return '▸' * filled + '▹' * empty;
      case ProgressBarStyle.thickBlocks:
        return '█' * filled + '░' * empty;
      case ProgressBarStyle.dots:
        return '⬤' * filled + '○' * empty;
    }
  }
}
