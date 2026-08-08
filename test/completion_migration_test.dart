import 'package:flutter_test/flutter_test.dart';
import 'package:kilife/services/completion_repository.dart';

void main() {
  test('legacy completion keys are parsed without changing their values', () {
    final records = CompletionRepository.parseLegacyCompletionValues(
      <String, bool>{
        'completion_2026_08_05_am': true,
        'completion_2026_08_05_pm': false,
        'settings_morning_enabled': true,
        'completion_2026_99_99_am': true,
      },
    );

    expect(records, hasLength(2));
    expect(records[0].day, DateTime(2026, 8, 5));
    expect(records[0].period, 'am');
    expect(records[0].complete, isTrue);
    expect(records[1].period, 'pm');
    expect(records[1].complete, isFalse);
  });
}
