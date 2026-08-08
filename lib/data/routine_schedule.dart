import 'package:flutter/material.dart';

import '../models/routine.dart';

const RoutinePlan morningRoutine = RoutinePlan(
  kind: RoutineKind.morning,
  title: 'Morning routine',
  description: 'Cleanse, hydrate, moisturize, and protect.',
  steps: <RoutineStep>[
    RoutineStep(
      title: 'Superfood Antioxidant Cleanser',
      subtitle: 'Cleanse',
      icon: Icons.water_drop_outlined,
      note: '1–2 pumps',
    ),
    RoutineStep(
      title: 'Superfood Skin Drip Smooth + Glow Serum',
      subtitle: 'Hydrate',
      icon: Icons.opacity_outlined,
      note: '1 pump to start; increase to 2 only if desired and well tolerated',
    ),
    RoutineStep(
      title: 'Air-Whip Moisture Cream',
      subtitle: 'Moisturize',
      icon: Icons.spa_outlined,
      note: 'Dime-size amount',
    ),
    RoutineStep(
      title: 'Youthscreen SPF 60',
      subtitle: 'Protect',
      icon: Icons.wb_sunny_outlined,
      note: 'About 2 finger-lengths for face + neck',
    ),
  ],
);

const RoutinePlan retinalRoutine = RoutinePlan(
  kind: RoutineKind.retinal,
  title: 'Night routine',
  typeLabel: 'Retinal',
  description: 'Skin-renewal night. Keep the routine simple.',
  steps: <RoutineStep>[
    RoutineStep(
      title: 'Superfood Antioxidant Cleanser',
      subtitle: 'Cleanse',
      icon: Icons.water_drop_outlined,
      note: '1–2 pumps',
    ),
    RoutineStep(
      title: 'Retinal + Niacinamide Youth Serum',
      subtitle: 'Treat',
      icon: Icons.science_outlined,
      note: 'Pea-size for the whole face; apply as a thin film',
    ),
    RoutineStep(
      title: 'Air-Whip Moisture Cream',
      subtitle: 'Moisturize',
      icon: Icons.spa_outlined,
      note: 'Dime-size amount',
    ),
  ],
);

const RoutinePlan exfoliationRoutine = RoutinePlan(
  kind: RoutineKind.exfoliation,
  title: 'Night routine',
  typeLabel: 'Exfoliation + Dream Mask',
  description: 'Exfoliate gently, then finish with extra hydration.',
  steps: <RoutineStep>[
    RoutineStep(
      title: 'Superfruit Gentle Exfoliating Cleanser',
      subtitle: 'Exfoliate',
      icon: Icons.auto_awesome_outlined,
      note: 'Dime-size amount',
    ),
    RoutineStep(
      title: 'Air-Whip Moisture Cream',
      subtitle: 'Moisturize',
      icon: Icons.spa_outlined,
      note: 'Dime-size amount',
    ),
    RoutineStep(
      title: 'Superberry Hydrate + Glow Dream Mask',
      subtitle: 'Overnight mask',
      icon: Icons.bedtime_outlined,
      note: 'Nickel-size amount / thin even layer',
    ),
  ],
);

const RoutinePlan recoveryRoutine = RoutinePlan(
  kind: RoutineKind.recovery,
  title: 'Night routine',
  typeLabel: 'Recovery',
  description: 'Hydrate and support your skin barrier without actives.',
  steps: <RoutineStep>[
    RoutineStep(
      title: 'Superfood Antioxidant Cleanser',
      subtitle: 'Cleanse',
      icon: Icons.water_drop_outlined,
      note: '1–2 pumps',
    ),
    RoutineStep(
      title: 'Superfood Skin Drip Smooth + Glow Serum',
      subtitle: 'Hydrate',
      icon: Icons.opacity_outlined,
      note: '1 pump to start; increase to 2 only if desired and well tolerated',
    ),
    RoutineStep(
      title: 'Air-Whip Moisture Cream',
      subtitle: 'Moisturize',
      icon: Icons.spa_outlined,
      note: 'Dime-size amount',
    ),
  ],
);

RoutinePlan eveningRoutineForWeekday(int weekday) {
  switch (weekday) {
    case DateTime.monday:
    case DateTime.wednesday:
    case DateTime.friday:
      return retinalRoutine;
    case DateTime.tuesday:
    case DateTime.saturday:
      return exfoliationRoutine;
    case DateTime.thursday:
    case DateTime.sunday:
      return recoveryRoutine;
    default:
      throw ArgumentError.value(weekday, 'weekday', 'Must be 1 through 7.');
  }
}

String weekdayName(int weekday) {
  const names = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[weekday - 1];
}

String compactNotificationBody(RoutinePlan routine) {
  return routine.steps.map((step) => step.subtitle).join(' → ');
}
