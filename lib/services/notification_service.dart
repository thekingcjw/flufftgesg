import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/routine_schedule.dart';
import 'preferences_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'routine_reminders',
      'Routine reminders',
      channelDescription: 'Morning and evening skincare reminders.',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final current = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(current.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> reschedule(AppSettings settings) async {
    await _cancelRoutineNotifications();

    if (settings.morningEnabled) {
      await _plugin.zonedSchedule(
        id: 1000,
        title: 'Good morning — skincare time',
        body: compactNotificationBody(morningRoutine),
        scheduledDate: _nextDaily(settings.morningTime),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'am',
      );
    }

    if (settings.eveningEnabled) {
      for (var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++) {
        final routine = eveningRoutineForWeekday(weekday);
        await _plugin.zonedSchedule(
          id: 2000 + weekday,
          title: '${weekdayName(weekday)} — ${routine.title}',
          body: compactNotificationBody(routine),
          scheduledDate: _nextWeekday(weekday, settings.eveningTime),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'pm',
        );
      }
    }

    if (settings.followUpEnabled && settings.eveningEnabled) {
      final followUpTime = _addMinutes(settings.eveningTime, 60);
      await _plugin.zonedSchedule(
        id: 3000,
        title: 'Routine check-in',
        body: 'Still need to finish tonight’s skincare routine?',
        scheduledDate: _nextDaily(followUpTime),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'follow_up',
      );
    }
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      id: 9999,
      title: 'SkinFlow notifications are working',
      body: 'Your skincare reminders are ready.',
      notificationDetails: _details,
      payload: 'test',
    );
  }

  Future<void> _cancelRoutineNotifications() async {
    await _plugin.cancel(id: 1000);
    await _plugin.cancel(id: 3000);
    for (var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++) {
      await _plugin.cancel(id: 2000 + weekday);
    }
  }

  tz.TZDateTime _nextDaily(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextWeekday(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final total = (time.hour * 60 + time.minute + minutes) % (24 * 60);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }
}
