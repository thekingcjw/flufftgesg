import 'package:flutter/material.dart';

import '../models/routine.dart';
import '../theme/skinflow_theme.dart';

class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    required this.routine,
    required this.complete,
    required this.onChanged,
  });

  final RoutinePlan routine;
  final bool complete;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(routine.kind);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SkinFlowColors.cardEmphasized,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_iconFor(routine.kind), color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        routine.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: SkinFlowColors.primaryText,
                            ),
                      ),
                      if (routine.typeLabel != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          routine.typeLabel!,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        routine.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: SkinFlowColors.secondaryText,
                              height: 1.25,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (var index = 0; index < routine.steps.length; index++) ...<Widget>[
              _StepRow(step: routine.steps[index], accent: accent),
              if (index != routine.steps.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
            Center(
              child: FilledButton(
                onPressed: () => onChanged(!complete),
                child: Text(complete ? 'Completed' : 'Mark complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentFor(RoutineKind kind) {
    return switch (kind) {
      RoutineKind.morning => SkinFlowColors.morning,
      RoutineKind.retinal => SkinFlowColors.retinal,
      RoutineKind.exfoliation => SkinFlowColors.exfoliation,
      RoutineKind.recovery => SkinFlowColors.recovery,
    };
  }

  IconData _iconFor(RoutineKind kind) {
    return switch (kind) {
      RoutineKind.morning => Icons.wb_sunny_rounded,
      RoutineKind.retinal => Icons.circle,
      RoutineKind.exfoliation => Icons.auto_awesome,
      RoutineKind.recovery => Icons.shield_outlined,
    };
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.accent});

  final RoutineStep step;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SkinFlowColors.cardEmphasized,
              shape: BoxShape.circle,
              border: Border.all(color: accent),
            ),
            alignment: Alignment.center,
            child: Icon(step.icon, color: accent, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  step.subtitle.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SkinFlowColors.primaryText,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
                if (step.note != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    step.note!,
                    style: const TextStyle(
                      color: SkinFlowColors.secondaryText,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
