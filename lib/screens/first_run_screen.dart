import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../theme/skinflow_theme.dart';

class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  bool _working = false;

  Future<void> _enableNotifications() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final granted = await NotificationService.instance.requestPermission();
      if (granted) {
        final settings = await PreferencesService.instance.loadSettings();
        await NotificationService.instance.reschedule(settings);
        await NotificationService.instance.showTestNotification();
      }
      await PreferencesService.instance.markFirstRunComplete();
      if (mounted) widget.onFinished();
    } catch (_) {
      if (!mounted) return;
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t finish notification setup. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  '✦  SkinFlow',
                  style: TextStyle(
                    color: SkinFlowColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 96),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SkinFlowColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: SkinFlowColors.subtleBorder),
                  ),
                  child: const Text(
                    'S',
                    style: TextStyle(
                      color: Color(0xFF3B255A),
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Stay on track',
                  style: TextStyle(
                    color: SkinFlowColors.primaryText,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: SizedBox(
                  width: 340,
                  child: Text(
                    'Get gentle reminders for your morning and evening routines. SkinFlow never shares your routine data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SkinFlowColors.secondaryText,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _NotificationPreview(),
              const SizedBox(height: 24),
              Center(
                child: FilledButton(
                  onPressed: _working ? null : _enableNotifications,
                  child: _working
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enable notifications'),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'You can change this later in Settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SkinFlowColors.secondaryText,
                    fontSize: 14,
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

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SkinFlowColors.cardEmphasized,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SkinFlowColors.card,
              border: Border.all(color: SkinFlowColors.primary),
            ),
            child: const Text(
              '✦',
              style: TextStyle(
                color: SkinFlowColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SkinFlow notifications are working',
                  style: TextStyle(
                    color: SkinFlowColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your skincare reminders are ready.',
                  style: TextStyle(
                    color: SkinFlowColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
