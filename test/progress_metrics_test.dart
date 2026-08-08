import 'package:flutter_test/flutter_test.dart';
import 'package:kilife/models/progress_metrics.dart';
import 'package:kilife/services/completion_repository.dart';

CompletionRecord record(DateTime day, String period, {bool complete = true}) =>
    CompletionRecord(day: day, period: period, complete: complete);

void main() {
  test('calendar classifies complete partial missed and pending days', () {
    final today = DateTime(2026, 8, 7);
    final progress = buildDayProgress(
      <CompletionRecord>[
        record(DateTime(2026, 8, 4), 'am'),
        record(DateTime(2026, 8, 4), 'pm'),
        record(DateTime(2026, 8, 5), 'am'),
      ],
      start: DateTime(2026, 8, 4),
      end: DateTime(2026, 8, 7),
      today: today,
    );

    expect(progress[DateTime(2026, 8, 4)]!.state, DayCompletionState.complete);
    expect(progress[DateTime(2026, 8, 5)]!.state, DayCompletionState.partial);
    expect(progress[DateTime(2026, 8, 6)]!.state, DayCompletionState.missed);
    expect(progress[DateTime(2026, 8, 7)]!.state, DayCompletionState.pending);
  });

  test('today in progress does not break the current full-day streak', () {
    final today = DateTime(2026, 8, 7);
    final records = <CompletionRecord>[];
    for (final day in <DateTime>[
      DateTime(2026, 8, 4),
      DateTime(2026, 8, 5),
      DateTime(2026, 8, 6),
    ]) {
      records
        ..add(record(day, 'am'))
        ..add(record(day, 'pm'));
    }
    records.add(record(today, 'am'));

    final metrics = calculateStreakMetrics(records, today: today);
    expect(metrics.current, 3);
    expect(metrics.longest, 3);
    expect(metrics.nextMilestone, 7);
  });

  test('a completed today extends the streak', () {
    final today = DateTime(2026, 8, 7);
    final records = <CompletionRecord>[];
    for (final day in <DateTime>[
      DateTime(2026, 8, 5),
      DateTime(2026, 8, 6),
      DateTime(2026, 8, 7),
    ]) {
      records
        ..add(record(day, 'am'))
        ..add(record(day, 'pm'));
    }

    expect(calculateStreakMetrics(records, today: today).current, 3);
  });
}
