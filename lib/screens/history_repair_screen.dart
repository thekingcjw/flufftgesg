import 'package:flutter/material.dart';

import '../models/progress_metrics.dart';
import '../services/completion_repository.dart';
import '../theme/skinflow_theme.dart';

class HistoryRepairScreen extends StatefulWidget {
  const HistoryRepairScreen({super.key});

  @override
  State<HistoryRepairScreen> createState() => _HistoryRepairScreenState();
}

class _HistoryRepairScreenState extends State<HistoryRepairScreen> {
  final CompletionRepository _history = CompletionRepository.instance;
  bool _loading = true;
  String? _error;
  final Map<DateTime, Map<String, bool>> _values =
      <DateTime, Map<String, bool>>{};
  final Set<String> _saving = <String>{};

  List<DateTime> get _days {
    final today = dayOnly(DateTime.now());
    return <DateTime>[
      for (var offset = 13; offset >= 0; offset--)
        today.subtract(Duration(days: offset)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await _history.allEntries();
      final values = <DateTime, Map<String, bool>>{};
      for (final day in _days) {
        values[day] = <String, bool>{'am': false, 'pm': false};
      }
      for (final record in records) {
        final day = dayOnly(record.day);
        final dayValues = values[day];
        if (dayValues != null && record.complete) {
          dayValues[record.period] = true;
        }
      }
      if (!mounted) return;
      setState(() {
        _values
          ..clear()
          ..addAll(values);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Routine history could not be loaded.';
      });
    }
  }

  Future<void> _setComplete(
    DateTime day,
    String period,
    bool value,
  ) async {
    final key = '${day.toIso8601String()}-$period';
    final previous = _values[day]?[period] ?? false;
    setState(() {
      _values[day]![period] = value;
      _saving.add(key);
    });

    try {
      await _history.setComplete(day, period, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _values[day]![period] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save that history change.')),
      );
    } finally {
      if (mounted) setState(() => _saving.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit routine history')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text(_error!),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit routine history')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SkinFlowColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Restore or correct recent history',
                  style: TextStyle(
                    color: SkinFlowColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Use these switches to restore AM and PM completions from an older install or correct a past day. Changes update Calendar, Week, and Streak immediately.',
                  style: TextStyle(
                    color: SkinFlowColors.secondaryText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final day in _days) ...<Widget>[
            _HistoryDayCard(
              day: day,
              morningComplete: _values[day]!['am']!,
              eveningComplete: _values[day]!['pm']!,
              morningSaving: _saving.contains('${day.toIso8601String()}-am'),
              eveningSaving: _saving.contains('${day.toIso8601String()}-pm'),
              onMorningChanged: (value) => _setComplete(day, 'am', value),
              onEveningChanged: (value) => _setComplete(day, 'pm', value),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _HistoryDayCard extends StatelessWidget {
  const _HistoryDayCard({
    required this.day,
    required this.morningComplete,
    required this.eveningComplete,
    required this.morningSaving,
    required this.eveningSaving,
    required this.onMorningChanged,
    required this.onEveningChanged,
  });

  final DateTime day;
  final bool morningComplete;
  final bool eveningComplete;
  final bool morningSaving;
  final bool eveningSaving;
  final ValueChanged<bool> onMorningChanged;
  final ValueChanged<bool> onEveningChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: SkinFlowColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              _dateLabel(day),
              style: const TextStyle(
                color: SkinFlowColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _HistorySwitch(
            label: 'Morning',
            value: morningComplete,
            saving: morningSaving,
            onChanged: onMorningChanged,
          ),
          _HistorySwitch(
            label: 'Evening',
            value: eveningComplete,
            saving: eveningSaving,
            onChanged: onEveningChanged,
          ),
        ],
      ),
    );
  }
}

class _HistorySwitch extends StatelessWidget {
  const _HistorySwitch({
    required this.label,
    required this.value,
    required this.saving,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool saving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SkinFlowColors.secondaryText,
                fontSize: 14,
              ),
            ),
          ),
          if (saving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Switch(value: value, onChanged: saving ? null : onChanged),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime day) {
  const weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
}
