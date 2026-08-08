import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CompletionEntries extends Table {
  DateTimeColumn get day => dateTime()();
  TextColumn get period => text()();
  BoolColumn get complete => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{day, period};
}

@DriftDatabase(tables: <Type>[CompletionEntries])
final class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'skinflow'));

  static final AppDatabase instance = AppDatabase();

  @override
  int get schemaVersion => 1;

  Future<void> setCompletion(
    DateTime day,
    String period,
    bool complete,
  ) async {
    _validatePeriod(period);
    final normalized = normalizeDay(day);
    await into(completionEntries).insertOnConflictUpdate(
      CompletionEntriesCompanion.insert(
        day: normalized,
        period: period,
        complete: Value<bool>(complete),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  Future<CompletionEntry?> completionFor(
    DateTime day,
    String period,
  ) {
    _validatePeriod(period);
    final normalized = normalizeDay(day);
    return (select(completionEntries)
          ..where(
            (row) =>
                row.day.equals(normalized) & row.period.equals(period),
          ))
        .getSingleOrNull();
  }

  Future<List<CompletionEntry>> entriesBetween(
    DateTime start,
    DateTime end,
  ) {
    final normalizedStart = normalizeDay(start);
    final normalizedEnd = normalizeDay(end);
    return (select(completionEntries)
          ..where(
            (row) =>
                row.day.isBiggerOrEqualValue(normalizedStart) &
                row.day.isSmallerOrEqualValue(normalizedEnd),
          )
          ..orderBy(<OrderClauseGenerator<CompletionEntries>>[
            (row) => OrderingTerm.asc(row.day),
            (row) => OrderingTerm.asc(row.period),
          ]))
        .get();
  }

  Stream<List<CompletionEntry>> watchEntriesBetween(
    DateTime start,
    DateTime end,
  ) {
    final normalizedStart = normalizeDay(start);
    final normalizedEnd = normalizeDay(end);
    return (select(completionEntries)
          ..where(
            (row) =>
                row.day.isBiggerOrEqualValue(normalizedStart) &
                row.day.isSmallerOrEqualValue(normalizedEnd),
          )
          ..orderBy(<OrderClauseGenerator<CompletionEntries>>[
            (row) => OrderingTerm.asc(row.day),
            (row) => OrderingTerm.asc(row.period),
          ]))
        .watch();
  }

  Future<List<CompletionEntry>> allEntries() {
    return (select(completionEntries)
          ..orderBy(<OrderClauseGenerator<CompletionEntries>>[
            (row) => OrderingTerm.asc(row.day),
            (row) => OrderingTerm.asc(row.period),
          ]))
        .get();
  }

  Stream<List<CompletionEntry>> watchAllEntries() {
    return (select(completionEntries)
          ..orderBy(<OrderClauseGenerator<CompletionEntries>>[
            (row) => OrderingTerm.asc(row.day),
            (row) => OrderingTerm.asc(row.period),
          ]))
        .watch();
  }

  static DateTime normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static void _validatePeriod(String period) {
    if (period != 'am' && period != 'pm') {
      throw ArgumentError.value(period, 'period', 'Expected am or pm.');
    }
  }
}
