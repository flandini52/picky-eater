import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsRepository {
  static const _keyEnabled = 'notifications_enabled';
  static const _keyThresholdDays = 'notifications_threshold_days';
  static const _defaultThresholdDays = 7;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  Future<int> getThresholdDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyThresholdDays) ?? _defaultThresholdDays;
  }

  Future<void> setThresholdDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThresholdDays, days);
  }
}
