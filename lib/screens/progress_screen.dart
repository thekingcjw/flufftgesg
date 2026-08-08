import 'package:flutter/material.dart';

import '../models/progress_metrics.dart';
import '../services/completion_repository.dart';
import '../theme/skinflow_theme.dart';

enum _ProgressView { calendar, week, streak }

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final CompletionRepository _history = CompletionRepository.instance;
  late Stream<List<CompletionRecord>> _stream;
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  _ProgressView _view = _ProgressView.calendar;

  @override
  void initState() {
    super.initState();
    final today = dayOnly(DateTime.now());
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDay = today;
    _stream = _history.watchAllEntries();
  }

  void _retry() {
    setState(() => _stream = _history.watchAllEntries());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Routine history',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDay = dayOnly(picked);
      _visibleMonth = DateTime(picked.year, picked.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CompletionRecord>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ProgressStateCard(
            icon: Icons.error_outline,
            title: 'Progress couldn’t load',
            body: 'Your routine history is still on this device. Try again.',
            actionLabel: 'Retry',
            onPressed: _retry,
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!;
        if (records.isEmpty) {
          return const _ProgressStateCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Your progress starts here',
            body: 'Complete a morning or evening routine to begin building your history.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Text(
              'Progress',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: SkinFlowColors.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitleFor(_view),
              style: const TextStyle(
                color: SkinFlowColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<_ProgressView>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<_ProgressView>>[
                    ButtonSegment(
                      value: _ProgressView.calendar,
                      label: Text('Calendar', maxLines: 1, softWrap: false),
                    ),
                    ButtonSegment(
                      value: _ProgressView.week,
                      label: Text('Week', maxLines: 1, softWrap: false),
                    ),
                    ButtonSegment(
                      value: _ProgressView.streak,
                      label: Text('Streak', maxLines: 1, softWrap: false),
                    ),
                  ],
                  selected: <_ProgressView>{_view},
                  onSelectionChanged: (selection) {
                    setState(() => _view = selection.first);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_view == _ProgressView.calendar)
              _CalendarView(
                records: records,
                visibleMonth: _visibleMonth,
                selectedDay: _selectedDay,
                onMonthChanged: (month) {
                  setState(() => _visibleMonth = month);
                },
                onDaySelected: (day) {
                  setState(() => _selectedDay = day);
                },
                onPickDate: _pickDate,
              )
            else if (_view == _ProgressView.week)
              _WeekView(records: records)
            else
              _StreakView(records: records),
          ],
        );
      },
    );
  }

  String _subtitleFor(_ProgressView view) {
    switch (view) {
      case _ProgressView.calendar:
        return 'Your routine history, day by day.';
      case _ProgressView.week:
        return '14 sessions. One clear weekly view.';
      case _ProgressView.streak:
        return 'Build consistency one full day at a time.';
    }
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView({
    required this.records,
    required this.visibleMonth,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onPickDate,
  });

  final List<CompletionRecord> records;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month);
    final last = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);
    final progress = buildDayProgress(
      records,
      start: first,
      end: last,
      today: DateTime.now(),
    );
    final leadingEmpty = first.weekday % 7;
    final totalCells = ((leadingEmpty + last.day + 6) ~/ 7) * 7;

    return Column(
      children: <Widget>[
        Container(
          width: 360,
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 12),
          decoration: BoxDecoration(
            color: SkinFlowColors.cardEmphasized,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Routine history',
                  style: TextStyle(
                    color: SkinFlowColors.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _longDate(selectedDay),
                        style: const TextStyle(
                          color: SkinFlowColors.primaryText,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onPickDate,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _monthYear(visibleMonth),
                        style: const TextStyle(
                          color: SkinFlowColors.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onMonthChanged(
                        DateTime(visibleMonth.year, visibleMonth.month - 1),
                      ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: () => onMonthChanged(
                        DateTime(visibleMonth.year, visibleMonth.month + 1),
                      ),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Center(child: Text('S'))),
                    Expanded(child: Center(child: Text('M'))),
                    Expanded(child: Center(child: Text('T'))),
                    Expanded(child: Center(child: Text('W'))),
                    Expanded(child: Center(child: Text('T'))),
                    Expanded(child: Center(child: Text('F'))),
                    Expanded(child: Center(child: Text('S'))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: 48,
                  ),
                  itemBuilder: (context, index) {
                    final number = index - leadingEmpty + 1;
                    if (number < 1 || number > last.day) {
                      return const SizedBox.shrink();
                    }
                    final day = DateTime(
                      visibleMonth.year,
                      visibleMonth.month,
                      number,
                    );
                    return _CalendarDay(
                      day: day,
                      progress: progress[day]!,
                      selected: dayOnly(selectedDay) == day,
                      onTap: () => onDaySelected(day),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _CompletionLegend(),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.progress,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final DayProgress progress;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color background = Colors.transparent;
    Color foreground = SkinFlowColors.primaryText;
    Color? border;

    switch (progress.state) {
      case DayCompletionState.complete:
        background = SkinFlowColors.primary;
        foreground = const Color(0xFF3B2850);
        break;
      case DayCompletionState.partial:
        border = SkinFlowColors.primary;
        break;
      case DayCompletionState.missed:
        background = const Color(0xFF4C474F);
        foreground = SkinFlowColors.secondaryText;
        break;
      case DayCompletionState.pending:
        if (dayOnly(DateTime.now()) == day) {
          border = SkinFlowColors.primary;
        }
        break;
    }
    if (selected && progress.state != DayCompletionState.complete) {
      border = SkinFlowColors.primary;
    }

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: border == null ? null : Border.all(color: border),
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(color: foreground, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _CompletionLegend extends StatelessWidget {
  const _CompletionLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _LegendItem(label: 'Complete', fill: SkinFlowColors.primary),
        _LegendItem(label: 'Partial', border: SkinFlowColors.primary),
        _LegendItem(label: 'Missed', fill: SkinFlowColors.missed),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, this.fill, this.border});

  final String label;
  final Color? fill;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: border == null ? null : Border.all(color: border!),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: SkinFlowColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.records});

  final List<CompletionRecord> records;

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final progress = buildDayProgress(
      records,
      start: monday,
      end: sunday,
      today: today,
    );
    final days = <DayProgress>[
      for (var offset = 0; offset < 7; offset++)
        progress[monday.add(Duration(days: offset))]!,
    ];
    final completed = days.fold<int>(
      0,
      (sum, day) => sum + day.completedSessions,
    );

    return Column(
      children: <Widget>[
        _WeeklySummaryCard(completed: completed),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final day in days)
                  SizedBox(width: width, child: _WeekDayCard(day: day)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.completed});

  final int completed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  '$completed / 14',
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
                value: (completed / 14).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  const _WeekDayCard({required this.day});

  final DayProgress day;

  @override
  Widget build(BuildContext context) {
    final complete = day.state == DayCompletionState.complete;
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: complete ? SkinFlowColors.selectedContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            _weekday(day.day.weekday),
            style: const TextStyle(
              color: SkinFlowColors.primaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.completedSessions} of 2 · ${_stateLabel(day.state)}',
            style: const TextStyle(
              color: SkinFlowColors.secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakView extends StatelessWidget {
  const _StreakView({required this.records});

  final List<CompletionRecord> records;

  @override
  Widget build(BuildContext context) {
    final metrics = calculateStreakMetrics(records, today: DateTime.now());
    final progress = metrics.nextMilestone == 0
        ? 0.0
        : (metrics.current / metrics.nextMilestone).clamp(0.0, 1.0).toDouble();
    final remaining = metrics.daysToMilestone;

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SkinFlowColors.primaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Current full-day streak',
                style: TextStyle(
                  color: SkinFlowColors.onPrimaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    '${metrics.current}',
                    style: const TextStyle(
                      color: SkinFlowColors.onPrimaryContainer,
                      fontSize: 57,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'days',
                    style: TextStyle(
                      color: SkinFlowColors.onPrimaryContainer,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                metrics.current == 0
                    ? 'Complete AM + PM to start a full-day streak.'
                    : 'AM + PM completed ${_numberWord(metrics.current)} days in a row',
                style: const TextStyle(
                  color: SkinFlowColors.onPrimaryContainer,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                label: 'Longest streak',
                value: '${metrics.longest} days',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'This month',
                value: '${metrics.fullDaysThisMonth} full days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Next milestone · ${metrics.nextMilestone} days',
                        style: const TextStyle(
                          color: SkinFlowColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$remaining ${remaining == 1 ? 'day' : 'days'} left',
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
                  child: LinearProgressIndicator(value: progress, minHeight: 8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.stars_outlined,
            color: SkinFlowColors.primaryText,
          ),
          title: Text(
            'Today is still in progress',
            style: TextStyle(color: SkinFlowColors.primaryText),
          ),
          subtitle: Text(
            'Only a finished incomplete day breaks it.',
            style: TextStyle(color: SkinFlowColors.secondaryText),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SkinFlowColors.selectedContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: SkinFlowColors.primaryText,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: SkinFlowColors.secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStateCard extends StatelessWidget {
  const _ProgressStateCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SkinFlowColors.card,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: SkinFlowColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SkinFlowColors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SkinFlowColors.secondaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onPressed != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton(onPressed: onPressed, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _weekday(int weekday) {
  return const <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];
}

String _stateLabel(DayCompletionState state) {
  switch (state) {
    case DayCompletionState.complete:
      return 'Complete';
    case DayCompletionState.partial:
      return 'Partial';
    case DayCompletionState.missed:
      return 'Missed';
    case DayCompletionState.pending:
      return 'Pending';
  }
}

String _monthYear(DateTime date) {
  return '${_months[date.month - 1]} ${date.year}';
}

String _longDate(DateTime date) {
  return '${_shortWeekdays[date.weekday % 7]}, ${_shortMonths[date.month - 1]} ${date.day}';
}

String _numberWord(int value) {
  switch (value) {
    case 1:
      return 'one';
    case 2:
      return 'two';
    case 3:
      return 'three';
    case 4:
      return 'four';
    case 5:
      return 'five';
    case 6:
      return 'six';
    case 7:
      return 'seven';
    default:
      return '$value';
  }
}

const List<String> _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _shortMonths = <String>[
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

const List<String> _shortWeekdays = <String>[
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];