import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.morningEnabled,
    required this.eveningEnabled,
    required this.followUpEnabled,
    required this.morningTime,
    required this.eveningTime,
  });

  final bool morningEnabled;
  final bool eveningEnabled;
  final bool followUpEnabled;
  final TimeOfDay morningTime;
  final TimeOfDay eveningTime;

  AppSettings copyWith({
    bool? morningEnabled,
    bool? eveningEnabled,
    bool? followUpEnabled,
    TimeOfDay? morningTime,
    TimeOfDay? eveningTime,
  }) {
    return AppSettings(
      morningEnabled: morningEnabled ?? this.morningEnabled,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      followUpEnabled: followUpEnabled ?? this.followUpEnabled,
      morningTime: morningTime ?? this.morningTime,
      eveningTime: eveningTime ?? this.eveningTime,
    );
  }
}

class PreferencesService {
  PreferencesService._();

  static final PreferencesService instance = PreferencesService._();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _morningEnabledKey = 'settings_morning_enabled';
  static const String _eveningEnabledKey = 'settings_evening_enabled';
  static const String _followUpEnabledKey = 'settings_follow_up_enabled';
  static const String _morningTimeKey = 'settings_morning_time';
  static const String _eveningTimeKey = 'settings_evening_time';
  static const String _historyMigrationKey =
      'skinflow_v02_completion_history_migrated';
  static const String _firstRunCompleteKey = 'skinflow_first_run_complete';

  Future<AppSettings> loadSettings() async {
    return AppSettings(
      morningEnabled: await _prefs.getBool(_morningEnabledKey) ?? true,
      eveningEnabled: await _prefs.getBool(_eveningEnabledKey) ?? true,
      followUpEnabled: await _prefs.getBool(_followUpEnabledKey) ?? false,
      morningTime: _decodeTime(await _prefs.getString(_morningTimeKey)) ??
          const TimeOfDay(hour: 4, minute: 30),
      eveningTime: _decodeTime(await _prefs.getString(_eveningTimeKey)) ??
          const TimeOfDay(hour: 20, minute: 0),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await Future.wait(<Future<void>>[
      _prefs.setBool(_morningEnabledKey, settings.morningEnabled),
      _prefs.setBool(_eveningEnabledKey, settings.eveningEnabled),
      _prefs.setBool(_followUpEnabledKey, settings.followUpEnabled),
      _prefs.setString(_morningTimeKey, _encodeTime(settings.morningTime)),
      _prefs.setString(_eveningTimeKey, _encodeTime(settings.eveningTime)),
    ]);
  }

  Future<bool> isComplete(DateTime date, String period) async {
    return await _prefs.getBool(completionKey(date, period)) ?? false;
  }

  Future<void> setComplete(
    DateTime date,
    String period,
    bool isComplete,
  ) async {
    await _prefs.setBool(completionKey(date, period), isComplete);
  }

  Future<int> completedCountForWeek(DateTime date) async {
    final DateTime monday = date.subtract(Duration(days: date.weekday - 1));
    var count = 0;
    for (var offset = 0; offset < 7; offset++) {
      final day = monday.add(Duration(days: offset));
      if (await isComplete(day, 'am')) count++;
      if (await isComplete(day, 'pm')) count++;
    }
    return count;
  }

  Future<bool> shouldShowFirstRun() async {
    if (await _prefs.getBool(_firstRunCompleteKey) ?? false) return false;

    final keys = await _prefs.getKeys();
    final hasLegacyAppData = keys.any(
      (key) => key.startsWith('completion_') || key.startsWith('settings_'),
    );
    if (hasLegacyAppData) {
      await markFirstRunComplete();
      return false;
    }
    return true;
  }

  Future<void> markFirstRunComplete() =>
      _prefs.setBool(_firstRunCompleteKey, true);

  Future<bool> isHistoryMigrationComplete() async =>
      await _prefs.getBool(_historyMigrationKey) ?? false;

  Future<void> markHistoryMigrationComplete() =>
      _prefs.setBool(_historyMigrationKey, true);

  Future<Map<String, bool>> legacyCompletionValues() async {
    final keys = await _prefs.getKeys();
    final completionKeys = keys.where((key) => key.startsWith('completion_'));
    final result = <String, bool>{};
    for (final key in completionKeys) {
      final value = await _prefs.getBool(key);
      if (value != null) result[key] = value;
    }
    return result;
  }

  String completionKey(DateTime date, String period) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'completion_${y}_${m}_${d}_$period';
  }

  String _encodeTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _decodeTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
