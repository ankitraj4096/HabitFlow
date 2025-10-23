import 'package:demo/themes/dark_mode.dart';
import 'package:demo/themes/light_mode.dart';
import 'package:flutter/material.dart';

class ThemeSwitch extends ChangeNotifier {
  ThemeData _themeData = darkMode;
  ThemeData get themeData => _themeData;
  bool get isDarkMode => _themeData == darkMode;
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void swicthTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}