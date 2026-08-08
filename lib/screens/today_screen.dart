import 'package:flutter/material.dart';

import '../data/routine_schedule.dart';
import '../services/completion_repository.dart';
import '../theme/skinflow_theme.dart';
import '../widgets/routine_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _history = CompletionRepository.instance;
  bool _loading = true;
  bool _morningComplete = false;
  bool _eveningComplete = false;
  int _weeklyCompleted = 0;

  DateTime get _today => DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _history.isComplete(_today, 'am'),
        _history.isComplete(_today, 'pm'),
        _history.completedCountForWeek(_today),
      ]);
      if (!mounted) return;
      setState(() {
        _morningComplete = results[0] as bool;
        _eveningComplete = results[1] as bool;
        _weeklyCompleted = results[2] as int;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn’t load routine history. Pull down to retry.'),
          ),
        );
      });
    }
  }

  Future<void> _setComplete(String period, bool value) async {
    final previousMorning = _morningComplete;
    final previousEvening = _eveningComplete;
    final previousCount = _weeklyCompleted;
    setState(() {
      if (period == 'am') {
        _morningComplete = value;
      } else {
        _eveningComplete = value;
      }
      _weeklyCompleted =
          (_weeklyCompleted + (value ? 1 : -1)).clamp(0, 14).toInt();
    });

    try {
      await _history.setComplete(_today, period, value);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _morningComplete = previousMorning;
        _eveningComplete = previousEvening;
        _weeklyCompleted = previousCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t update progress. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final eveningRoutine = eveningRoutineForWeekday(_today.weekday);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Text(
            weekdayName(_today.weekday),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: SkinFlowColors.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Today’s routine is ready.',
            style: TextStyle(
              color: SkinFlowColors.secondaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _ProgressCard(completed: _weeklyCompleted),
          const SizedBox(height: 12),
          RoutineCard(
            routine: morningRoutine,
            complete: _morningComplete,
            onChanged: (value) => _setComplete('am', value),
          ),
          const SizedBox(height: 12),
          RoutineCard(
            routine: eveningRoutine,
            complete: _eveningComplete,
            onChanged: (value) => _setComplete('pm', value),
          ),
          const SizedBox(height: 12),
          const _SafetyNote(),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed});

  final int completed;

  @override
  Widget build(BuildContext context) {
    const total = 14;
    final progress = completed / total;
    return SizedBox(
      height: 100,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text(
                    'This week',
                    style: TextStyle(
                      color: SkinFlowColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completed / $total',
                    style: const TextStyle(
                      color: SkinFlowColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress.clamp(0.0, 1.0).toDouble(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '!',
                style: TextStyle(
                  color: SkinFlowColors.safety,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Never use the retinal serum and exfoliating cleanser in the same routine.',
                  style: TextStyle(
                    color: SkinFlowColors.primaryText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
