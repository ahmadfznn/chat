import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String themeKey = 'themeMode';
  Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    loadThemeMode();
  }

  void loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mode = prefs.getString(themeKey);
    if (mode == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (mode == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
    }
  }

  void setThemeMode(String mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mode == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (mode == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
      mode = 'auto';
    }
    await prefs.setString(themeKey, mode);
  }

  String get currentModeString {
    switch (themeMode.value) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'auto';
    }
  }
}
