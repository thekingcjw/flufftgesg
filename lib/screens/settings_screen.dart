import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../theme/skinflow_theme.dart';
import 'history_repair_screen.dart';

enum _NotificationFeedback { none, granted, denied }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _preferences = PreferencesService.instance;
  final _notifications = NotificationService.instance;

  AppSettings? _settings;
  bool _saving = false;
  _NotificationFeedback _feedback = _NotificationFeedback.none;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _preferences.loadSettings();
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _update(AppSettings settings) async {
    setState(() {
      _settings = settings;
      _saving = true;
    });
    try {
      await _preferences.saveSettings(settings);
      await _notifications.reschedule(settings);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime({required bool morning}) async {
    final settings = _settings;
    if (settings == null) return;
    final selected = await showTimePicker(
      context: context,
      initialTime: morning ? settings.morningTime : settings.eveningTime,
      helpText: morning ? 'Morning reminder' : 'Evening reminder',
    );
    if (selected == null) return;
    await _update(
      settings.copyWith(
        morningTime: morning ? selected : null,
        eveningTime: morning ? null : selected,
      ),
    );
  }

  Future<void> _enableAndTest() async {
    final settings = _settings;
    if (settings == null) return;
    final granted = await _notifications.requestPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _feedback = _NotificationFeedback.denied);
      return;
    }
    await _notifications.reschedule(settings);
    await _notifications.showTestNotification();
    if (!mounted) return;
    setState(() => _feedback = _NotificationFeedback.granted);
  }

  void _openHistoryRepair() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const HistoryRepairScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feedback == _NotificationFeedback.granted) {
      return _FeedbackPanel(
        success: true,
        title: 'Notifications enabled',
        body: 'Your skincare reminders are ready.',
        onPressed: () => setState(() => _feedback = _NotificationFeedback.none),
      );
    }
    if (_feedback == _NotificationFeedback.denied) {
      return _FeedbackPanel(
        success: false,
        title: 'Permission not granted',
        body: 'Enable notifications in Android settings to receive reminders.',
        actionLabel: 'Back to settings',
        onPressed: () => setState(() => _feedback = _NotificationFeedback.none),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Notifications',
                style: TextStyle(
                  color: SkinFlowColors.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_saving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose when SkinFlow reminds you to care for your skin.',
          style: TextStyle(
            color: SkinFlowColors.secondaryText,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _ReminderCard(
          title: 'Morning reminder',
          subtitle: settings.morningTime.format(context),
          enabled: settings.morningEnabled,
          onEnabledChanged: (value) =>
              _update(settings.copyWith(morningEnabled: value)),
          timeLabel: 'Morning time',
          timeValue: settings.morningTime.format(context),
          onTimePressed: settings.morningEnabled
              ? () => _pickTime(morning: true)
              : null,
        ),
        const SizedBox(height: 14),
        _ReminderCard(
          title: 'Evening reminder',
          subtitle: settings.eveningTime.format(context),
          enabled: settings.eveningEnabled,
          onEnabledChanged: (value) => _update(
            settings.copyWith(
              eveningEnabled: value,
              followUpEnabled: value ? null : false,
            ),
          ),
          timeLabel: 'Evening time',
          timeValue: settings.eveningTime.format(context),
          onTimePressed: settings.eveningEnabled
              ? () => _pickTime(morning: false)
              : null,
        ),
        const SizedBox(height: 14),
        _ReminderCard(
          title: 'Follow-up reminder',
          subtitle: 'One hour after the evening reminder.',
          enabled: settings.followUpEnabled && settings.eveningEnabled,
          onEnabledChanged: settings.eveningEnabled
              ? (value) => _update(settings.copyWith(followUpEnabled: value))
              : null,
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: SkinFlowColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: const Icon(Icons.history_outlined),
            title: const Text(
              'Edit routine history',
              style: TextStyle(color: SkinFlowColors.primaryText),
            ),
            subtitle: const Text(
              'Restore recent AM/PM completions or correct a past day.',
              style: TextStyle(
                color: SkinFlowColors.secondaryText,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openHistoryRepair,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            color: SkinFlowColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Reminder times and routine history stay on this device.',
            style: TextStyle(
              color: SkinFlowColors.secondaryText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton(
            onPressed: _saving ? null : _enableAndTest,
            child: const Text('Enable and test notifications'),
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onEnabledChanged,
    this.timeLabel,
    this.timeValue,
    this.onTimePressed,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool>? onEnabledChanged;
  final String? timeLabel;
  final String? timeValue;
  final VoidCallback? onTimePressed;

  @override
  Widget build(BuildContext context) {
    final hasTime = timeLabel != null && timeValue != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SkinFlowColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 52,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: SkinFlowColors.primaryText,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SkinFlowColors.secondaryText,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: onEnabledChanged),
              ],
            ),
          ),
          if (hasTime) ...<Widget>[
            const Divider(),
            InkWell(
              onTap: onTimePressed,
              child: SizedBox(
                height: 40,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        timeLabel!,
                        style: TextStyle(
                          color: onTimePressed == null
                              ? SkinFlowColors.secondaryText
                              : SkinFlowColors.primaryText,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      timeValue!,
                      style: const TextStyle(
                        color: SkinFlowColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.success,
    required this.title,
    required this.body,
    required this.onPressed,
    this.actionLabel,
  });

  final bool success;
  final String title;
  final String body;
  final VoidCallback onPressed;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final accent = success ? SkinFlowColors.morning : SkinFlowColors.safety;
    return Center(
      child: InkWell(
        onTap: success ? onPressed : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 360,
          constraints: const BoxConstraints(minHeight: 260),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SkinFlowColors.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SkinFlowColors.cardEmphasized,
                  border: Border.all(color: accent),
                ),
                child: Text(
                  success ? '✓' : '×',
                  style: TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SkinFlowColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SkinFlowColors.secondaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null) ...<Widget>[
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onPressed,
                  style: !success
                      ? FilledButton.styleFrom(
                          backgroundColor: SkinFlowColors.safety,
                          foregroundColor: const Color(0xFF601410),
                        )
                      : null,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
