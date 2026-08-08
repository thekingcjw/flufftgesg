import '../services/completion_repository.dart';

enum DayCompletionState { complete, partial, missed, pending }

class DayProgress {
  const DayProgress({
    required this.day,
    required this.amComplete,
    required this.pmComplete,
    required this.state,
  });

  final DateTime day;
  final bool amComplete;
  final bool pmComplete;
  final DayCompletionState state;

  int get completedSessions => (amComplete ? 1 : 0) + (pmComplete ? 1 : 0);
}

class StreakMetrics {
  const StreakMetrics({
    required this.current,
    required this.longest,
    required this.fullDaysThisMonth,
    required this.nextMilestone,
  });

  final int current;
  final int longest;
  final int fullDaysThisMonth;
  final int nextMilestone;

  int get daysToMilestone {
    final remaining = nextMilestone - current;
    if (remaining < 0) return 0;
    if (remaining > nextMilestone) return nextMilestone;
    return remaining;
  }
}

DateTime dayOnly(DateTime value) => DateTime(value.year, value.month, value.day);

Map<DateTime, DayProgress> buildDayProgress(
  Iterable<CompletionRecord> records, {
  required DateTime start,
  required DateTime end,
  required DateTime today,
}) {
  final normalizedToday = dayOnly(today);
  final completion = <DateTime, Set<String>>{};
  for (final record in records) {
    if (!record.complete) continue;
    completion.putIfAbsent(dayOnly(record.day), () => <String>{}).add(record.period);
  }

  final result = <DateTime, DayProgress>{};
  var cursor = dayOnly(start);
  final last = dayOnly(end);
  while (!cursor.isAfter(last)) {
    final periods = completion[cursor] ?? const <String>{};
    final am = periods.contains('am');
    final pm = periods.contains('pm');
    final state = switch ((am, pm)) {
      (true, true) => DayCompletionState.complete,
      (true, false) || (false, true) => DayCompletionState.partial,
      (false, false) when cursor.isBefore(normalizedToday) =>
        DayCompletionState.missed,
      _ => DayCompletionState.pending,
    };
    result[cursor] = DayProgress(
      day: cursor,
      amComplete: am,
      pmComplete: pm,
      state: state,
    );
    cursor = cursor.add(const Duration(days: 1));
  }
  return result;
}

StreakMetrics calculateStreakMetrics(
  Iterable<CompletionRecord> records, {
  required DateTime today,
}) {
  final normalizedToday = dayOnly(today);
  final periodsByDay = <DateTime, Set<String>>{};
  for (final record in records) {
    if (!record.complete) continue;
    periodsByDay
        .putIfAbsent(dayOnly(record.day), () => <String>{})
        .add(record.period);
  }

  bool full(DateTime day) {
    final periods = periodsByDay[day];
    return periods != null && periods.contains('am') && periods.contains('pm');
  }

  var cursor = full(normalizedToday)
      ? normalizedToday
      : normalizedToday.subtract(const Duration(days: 1));
  var current = 0;
  while (full(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final fullDays = periodsByDay.keys.where(full).toList()..sort();
  var longest = 0;
  var run = 0;
  DateTime? previous;
  for (final day in fullDays) {
    if (previous != null && _dayOrdinal(day) - _dayOrdinal(previous) == 1) {
      run++;
    } else {
      run = 1;
    }
    if (run > longest) longest = run;
    previous = day;
  }

  final fullDaysThisMonth = fullDays
      .where(
        (day) =>
            day.year == normalizedToday.year &&
            day.month == normalizedToday.month,
      )
      .length;

  const milestones = <int>[3, 7, 14, 30, 60, 90, 180, 365];
  var nextMilestone = current + 30;
  for (final milestone in milestones) {
    if (milestone > current) {
      nextMilestone = milestone;
      break;
    }
  }

  return StreakMetrics(
    current: current,
    longest: longest,
    fullDaysThisMonth: fullDaysThisMonth,
    nextMilestone: nextMilestone,
  );
}

int _dayOrdinal(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
