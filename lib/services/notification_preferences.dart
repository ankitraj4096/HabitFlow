
import 'package:shared_preferences/shared_preferences.dart';

enum ProgressBarStyle {
  squareBlocks,
  circles,
  triangles,
  squares,
  diamonds,
  arrows,
  thickBlocks,
  dots,
}

class NotificationPreferences {
  static const String _keyProgressBarStyle = 'notification_progress_bar_style';
  static const String _keyShowPercentage = 'notification_show_percentage';
  static const String _keyShowElapsedTime = 'notification_show_elapsed_time';
  static const String _keyShowTotalTime = 'notification_show_total_time';
  static const String _keyShowSystemProgressBar = 'notification_show_system_progress_bar';

  // Get Progress Bar Style
  Future<ProgressBarStyle> getProgressBarStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyProgressBarStyle) ?? ProgressBarStyle.thickBlocks.index;
    return ProgressBarStyle.values[index];
  }

  // Set Progress Bar Style
  Future<void> setProgressBarStyle(ProgressBarStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyProgressBarStyle, style.index);
  }

  // Get Show Percentage
  Future<bool> getShowPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowPercentage) ?? true;
  }

  // Set Show Percentage
  Future<void> setShowPercentage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPercentage, value);
  }

  // Get Show Elapsed Time
  Future<bool> getShowElapsedTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowElapsedTime) ?? false;
  }

  // Set Show Elapsed Time
  Future<void> setShowElapsedTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowElapsedTime, value);
  }

  // Get Show Total Time
  Future<bool> getShowTotalTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowTotalTime) ?? false;
  }

  // Set Show Total Time
  Future<void> setShowTotalTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTotalTime, value);
  }

  // Get Show System Progress Bar
  Future<bool> getShowSystemProgressBar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowSystemProgressBar) ?? false;
  }

  // Set Show System Progress Bar
  Future<void> setShowSystemProgressBar(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowSystemProgressBar, value);
  }

  // Get progress bar characters based on style
  String getProgressBarChars(ProgressBarStyle style, int percent) {
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
