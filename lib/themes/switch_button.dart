import 'package:demo/themes/switch_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeSwitch>(context);

    return IconButton(
      onPressed: () => themeProvider.swicthTheme(),
      icon: Icon(
        themeProvider.isDarkMode? Icons.light_mode:Icons.dark_mode,
        color: themeProvider.isDarkMode?Colors.white:Colors.black,
      ),
    );
  }
}