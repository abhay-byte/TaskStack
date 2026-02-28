import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = 0, // 0=system, 1=light, 2=dark
    this.accentColorArgb,
    this.weekStartsSunday = true,
    this.use24HourTime = false,
    this.defaultNotificationOffsetMinutes = 5,
    this.isFirstLaunch = true,
  });

  final int themeMode;
  final int? accentColorArgb;
  final bool weekStartsSunday;
  final bool use24HourTime;
  final int defaultNotificationOffsetMinutes;
  final bool isFirstLaunch;

  AppSettings copyWith({
    int? themeMode,
    int? accentColorArgb,
    bool? weekStartsSunday,
    bool? use24HourTime,
    int? defaultNotificationOffsetMinutes,
    bool? isFirstLaunch,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColorArgb: accentColorArgb ?? this.accentColorArgb,
      weekStartsSunday: weekStartsSunday ?? this.weekStartsSunday,
      use24HourTime: use24HourTime ?? this.use24HourTime,
      defaultNotificationOffsetMinutes: defaultNotificationOffsetMinutes ??
          this.defaultNotificationOffsetMinutes,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _kTheme = 'theme_mode';
  static const _kAccent = 'accent_color';
  static const _kWeekSun = 'week_starts_sun';
  static const _k24h = 'use_24h';
  static const _kNotifOffset = 'notif_offset';
  static const _kFirstLaunch = 'first_launch';

  void _load() {
    state = AppSettings(
      themeMode: _prefs.getInt(_kTheme) ?? 0,
      accentColorArgb: _prefs.getInt(_kAccent),
      weekStartsSunday: _prefs.getBool(_kWeekSun) ?? true,
      use24HourTime: _prefs.getBool(_k24h) ?? false,
      defaultNotificationOffsetMinutes: _prefs.getInt(_kNotifOffset) ?? 5,
      isFirstLaunch: _prefs.getBool(_kFirstLaunch) ?? true,
    );
  }

  Future<void> setThemeMode(int mode) async {
    await _prefs.setInt(_kTheme, mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setAccentColor(int? argb) async {
    if (argb == null) {
      await _prefs.remove(_kAccent);
    } else {
      await _prefs.setInt(_kAccent, argb);
    }
    state = state.copyWith(accentColorArgb: argb);
  }

  Future<void> setWeekStartsSunday(bool v) async {
    await _prefs.setBool(_kWeekSun, v);
    state = state.copyWith(weekStartsSunday: v);
  }

  Future<void> setUse24HourTime(bool v) async {
    await _prefs.setBool(_k24h, v);
    state = state.copyWith(use24HourTime: v);
  }

  Future<void> setDefaultNotificationOffset(int minutes) async {
    await _prefs.setInt(_kNotifOffset, minutes);
    state = state.copyWith(defaultNotificationOffsetMinutes: minutes);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_kFirstLaunch, false);
    state = state.copyWith(isFirstLaunch: false);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
