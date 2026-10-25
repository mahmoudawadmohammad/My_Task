import 'package:flutter/material.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/settings_service.dart';

class AppProvider extends ChangeNotifier {
  final SettingsService _settingsService;

  AppProvider(this._settingsService) {
    // نحمّل الإعدادات المحفوظة عند البدء
    _themeMode = _settingsService.getThemeMode();
    _locale = _settingsService.getLocale();
    _notificationsEnabled = _settingsService.getNotificationsEnabled();
  }

  // ==================== الوضع (Theme) ====================
  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _settingsService.setThemeMode(mode);
  }

  // ==================== اللغة (Locale) ====================
  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    await _settingsService.setLocale(locale);
  }

  // ============ الإشعارات ============
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> setNotificationsEnabled(bool enabled) async {
    // 1. تحديث الحالة المحلية
    _notificationsEnabled = enabled;
    notifyListeners();

    // 2. حفظ في SharedPreferences
    await _settingsService.setNotificationsEnabled(enabled);

    // 3. إذا ألغى التفعيل → نلغي كل الإشعارات المجدولة فوراً
    if (!enabled) {
      await NotificationService().cancelAllNotifications();
      print('🔕 Notifications disabled - all scheduled notifications cancelled');
    } else {
      print('🔔 Notifications enabled');
    }
  }
}