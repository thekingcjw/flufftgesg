import '../data/app_database.dart';
import 'preferences_service.dart';

class CompletionRecord {
  const CompletionRecord({
    required this.day,
    required this.period,
    required this.complete,
  });

  final DateTime day;
  final String period;
  final bool complete;
}

class LegacyCompletionRecord {
  const LegacyCompletionRecord({
    required this.day,
    required this.period,
    required this.complete,
  });

  final DateTime day;
  final String period;
  final bool complete;
}

class CompletionRepository {
  CompletionRepository({
    AppDatabase? database,
    PreferencesService? preferences,
  })  : _database = database ?? AppDatabase.instance,
        _preferences = preferences ?? PreferencesService.instance;

  static final CompletionRepository instance = CompletionRepository();

  final AppDatabase _database;
  final PreferencesService _preferences;

  Future<void> initialize() => migrateLegacyHistory();

  Future<void> migrateLegacyHistory() async {
    if (await _preferences.isHistoryMigrationComplete()) return;

    final legacyValues = await _preferences.legacyCompletionValues();
    for (final entry in parseLegacyCompletionValues(legacyValues)) {
      await _database.setCompletion(entry.day, entry.period, entry.complete);
    }
    await _preferences.markHistoryMigrationComplete();
  }

  Future<bool> isComplete(DateTime day, String period) async {
    final row = await _database.completionFor(day, period);
    if (row != null) return row.complete;
    return _preferences.isComplete(day, period);
  }

  Future<void> setComplete(
    DateTime day,
    String period,
    bool complete,
  ) async {
    await _database.setCompletion(day, period, complete);
    await _preferences.setComplete(day, period, complete);
  }

  Future<int> completedCountForWeek(DateTime day) async {
    final monday = AppDatabase.normalizeDay(
      day.subtract(Duration(days: day.weekday - DateTime.monday)),
    );
    final sunday = monday.add(const Duration(days: 6));
    final entries = await entriesBetween(monday, sunday);
    return entries.where((entry) => entry.complete).length;
  }

  Future<List<CompletionRecord>> entriesBetween(
    DateTime start,
    DateTime end,
  ) async => _mapRows(await _database.entriesBetween(start, end));

  Stream<List<CompletionRecord>> watchEntriesBetween(
    DateTime start,
    DateTime end,
  ) => _database.watchEntriesBetween(start, end).map(_mapRows);

  Future<List<CompletionRecord>> allEntries() async =>
      _mapRows(await _database.allEntries());

  Stream<List<CompletionRecord>> watchAllEntries() =>
      _database.watchAllEntries().map(_mapRows);

  static List<CompletionRecord> _mapRows(List<CompletionEntry> rows) => rows
      .map(
        (row) => CompletionRecord(
          day: row.day,
          period: row.period,
          complete: row.complete,
        ),
      )
      .toList(growable: false);

  static List<LegacyCompletionRecord> parseLegacyCompletionValues(
    Map<String, bool> values,
  ) {
    final pattern = RegExp(
      r'^completion_(\d{4})_(\d{2})_(\d{2})_(am|pm)$',
    );
    final records = <LegacyCompletionRecord>[];

    for (final entry in values.entries) {
      final match = pattern.firstMatch(entry.key);
      if (match == null) continue;
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final parsed = DateTime(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        continue;
      }
      records.add(
        LegacyCompletionRecord(
          day: parsed,
          period: match.group(4)!,
          complete: entry.value,
        ),
      );
    }

    records.sort((a, b) {
      final dayCompare = a.day.compareTo(b.day);
      if (dayCompare != 0) return dayCompare;
      return a.period.compareTo(b.period);
    });
    return records;
  }
}
