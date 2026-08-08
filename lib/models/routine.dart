import 'package:flutter/material.dart';

enum RoutineKind { morning, retinal, exfoliation, recovery }

class RoutineStep {
  const RoutineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.note,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? note;
}

class RoutinePlan {
  const RoutinePlan({
    required this.kind,
    required this.title,
    required this.description,
    required this.steps,
    this.typeLabel,
  });

  final RoutineKind kind;
  final String title;
  final String? typeLabel;
  final String description;
  final List<RoutineStep> steps;
}
