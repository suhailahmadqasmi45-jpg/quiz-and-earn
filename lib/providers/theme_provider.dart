import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode get themeMode => ThemeMode.light;

  bool get isDarkMode => false;
  bool get isLightMode => true;
  bool get isSystemMode => false;

  Future<void> init() async {}

  Future<void> setThemeMode(ThemeMode mode) async {}
}
