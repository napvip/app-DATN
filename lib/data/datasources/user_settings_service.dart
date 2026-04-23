import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsService {
  UserSettingsService._();
  static final UserSettingsService _instance = UserSettingsService._();
  factory UserSettingsService() => _instance;

  static const _alarmDurationKey = 'alarm_duration_seconds';
  static const _alertCooldownKey = 'alert_cooldown_seconds';

  // Alarm duration: bao nhiêu giây chuông phát (5–120s, mặc định 30s)
  Future<int> getAlarmDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_alarmDurationKey) ?? 30;
  }

  Future<void> setAlarmDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_alarmDurationKey, seconds.clamp(5, 120));
  }

  // Alert cooldown: bao lâu mới cảnh báo tiếp (3–600s, mặc định 5s)
  Future<int> getAlertCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_alertCooldownKey) ?? 5;
  }

  Future<void> setAlertCooldown(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_alertCooldownKey, seconds.clamp(3, 600));
  }
}
