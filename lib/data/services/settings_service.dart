import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // ============ المفاتيح ============
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLocale = 'locale';
  static const String _keyNotifications = 'notifications_enabled';

  late SharedPreferences _prefs;

  // ============ التهيئة (تُستدعى مرة عند بدء التطبيق) ============
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== الوضع (Theme) ====================
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await _prefs.setString(_keyThemeMode, value);
  }

  // ==================== اللغة (Locale) ====================
  /// null = لغة الجهاز
  Locale? getLocale() {
    final value = _prefs.getString(_keyLocale);
    if (value == null || value.isEmpty || value == 'system') {
      return null;
    }
    return Locale(value);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.setString(_keyLocale, 'system');
    } else {
      await _prefs.setString(_keyLocale, locale.languageCode);
    }
  }

  // ==================== الإشعارات ====================
  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotifications) ?? true; // الافتراضي: مفعّل
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotifications, enabled);
  }

  // ==================== مسح كل الإعدادات ====================
  Future<void> clearAll() async {
    await _prefs.remove(_keyThemeMode);
    await _prefs.remove(_keyLocale);
    await _prefs.remove(_keyNotifications);
  }
}