import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilife/data/app_database.dart';

void main() {
  test('completion rows upsert and remain unique by day and period', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final day = DateTime(2026, 8, 7);
    await database.setCompletion(day, 'am', true);
    await database.setCompletion(day, 'am', false);
    await database.setCompletion(day, 'pm', true);

    final rows = await database.entriesBetween(day, day);
    expect(rows, hasLength(2));
    expect(
      rows.singleWhere((row) => row.period == 'am').complete,
      isFalse,
    );
    expect(
      rows.singleWhere((row) => row.period == 'pm').complete,
      isTrue,
    );
  });
}
