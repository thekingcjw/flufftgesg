import 'package:flutter_test/flutter_test.dart';
import 'package:kilife/data/routine_schedule.dart';
import 'package:kilife/models/routine.dart';

void main() {
  test('morning routine matches the authoritative four-step order', () {
    expect(morningRoutine.title, 'Morning routine');
    expect(morningRoutine.typeLabel, isNull);
    expect(
      morningRoutine.steps.map((step) => step.title).toList(),
      <String>[
        'Superfood Antioxidant Cleanser',
        'Superfood Skin Drip Smooth + Glow Serum',
        'Air-Whip Moisture Cream',
        'Youthscreen SPF 60',
      ],
    );
  });

  test('evening plans use Night routine with a specific routine type label', () {
    expect(retinalRoutine.title, 'Night routine');
    expect(retinalRoutine.typeLabel, 'Retinal');
    expect(exfoliationRoutine.title, 'Night routine');
    expect(exfoliationRoutine.typeLabel, 'Exfoliation + Dream Mask');
    expect(recoveryRoutine.title, 'Night routine');
    expect(recoveryRoutine.typeLabel, 'Recovery');
  });

  test('recovery routine includes Skin Drip between cleanser and moisturizer', () {
    expect(
      recoveryRoutine.steps.map((step) => step.title).toList(),
      <String>[
        'Superfood Antioxidant Cleanser',
        'Superfood Skin Drip Smooth + Glow Serum',
        'Air-Whip Moisture Cream',
      ],
    );
  });

  test('Skin Drip is not scheduled on retinal or exfoliation nights', () {
    for (final routine in <RoutinePlan>[retinalRoutine, exfoliationRoutine]) {
      expect(
        routine.steps.any((step) => step.title.contains('Skin Drip')),
        isFalse,
      );
    }
  });

  test('evening weekday schedule remains MWF retinal, TuSa exfoliation, ThSu recovery', () {
    expect(eveningRoutineForWeekday(DateTime.monday).kind, RoutineKind.retinal);
    expect(eveningRoutineForWeekday(DateTime.tuesday).kind, RoutineKind.exfoliation);
    expect(eveningRoutineForWeekday(DateTime.wednesday).kind, RoutineKind.retinal);
    expect(eveningRoutineForWeekday(DateTime.thursday).kind, RoutineKind.recovery);
    expect(eveningRoutineForWeekday(DateTime.friday).kind, RoutineKind.retinal);
    expect(eveningRoutineForWeekday(DateTime.saturday).kind, RoutineKind.exfoliation);
    expect(eveningRoutineForWeekday(DateTime.sunday).kind, RoutineKind.recovery);
  });

  test('retinal and exfoliating cleanser are never scheduled together', () {
    for (var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++) {
      final routine = eveningRoutineForWeekday(weekday);
      final hasRetinal = routine.steps.any(
        (step) => step.title.contains('Retinal + Niacinamide'),
      );
      final hasExfoliatingCleanser = routine.steps.any(
        (step) => step.title.contains('Superfruit Gentle Exfoliating Cleanser'),
      );
      expect(hasRetinal && hasExfoliatingCleanser, isFalse);
    }
  });

  test('Dream Mask appears only on exfoliation nights', () {
    for (var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++) {
      final routine = eveningRoutineForWeekday(weekday);
      final hasDreamMask = routine.steps.any(
        (step) => step.title.contains('Dream Mask'),
      );
      expect(hasDreamMask, routine.kind == RoutineKind.exfoliation);
    }
  });

  test('routine step notes preserve the recommended starting amounts', () {
    expect(morningRoutine.steps[0].note, '1–2 pumps');
    expect(
      morningRoutine.steps[1].note,
      '1 pump to start; increase to 2 only if desired and well tolerated',
    );
    expect(morningRoutine.steps[2].note, 'Dime-size amount');
    expect(
      morningRoutine.steps[3].note,
      'About 2 finger-lengths for face + neck',
    );
    expect(
      retinalRoutine.steps[1].note,
      'Pea-size for the whole face; apply as a thin film',
    );
    expect(exfoliationRoutine.steps[0].note, 'Dime-size amount');
    expect(
      exfoliationRoutine.steps[2].note,
      'Nickel-size amount / thin even layer',
    );
  });
}
