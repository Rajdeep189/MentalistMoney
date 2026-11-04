import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for budget alerts, bill reminders and
/// daily logging nudges. Everything is scheduled locally (no network).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    tzdata.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    await _requestPermissions();
    _initialised = true;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'moneyman_reminders',
          'Reminders',
          channelDescription: 'Budget alerts, bill reminders and daily logging nudges',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

  Future<void> showNow(int id, String title, String body) async {
    await init();
    await _plugin.show(id, title, body, _details);
  }

  Future<void> scheduleAt(int id, String title, String body, DateTime when) async {
    await init();
    if (when.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Daily repeating reminder (e.g. "Log today's expenses").
  Future<void> scheduleDaily(int id, String title, String body, int hour, int minute) async {
    await init();
    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Weekly Monday report reminder.
  Future<void> scheduleWeekly(int id, String title, String body, int weekday, int hour, int minute) async {
    await init();
    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute, weekday: weekday),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (weekday != null) {
      while (scheduled.weekday != weekday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      if (weekday != null) {
        while (scheduled.weekday != weekday) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
      }
    }
    return scheduled;
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Budget threshold alert.
  Future<void> notifyBudgetThreshold(String budgetName, double percent) async {
    await showNow(
      9000 + budgetName.hashCode % 500,
      'Budget alert: $budgetName',
      'You have used ${percent.toStringAsFixed(0)}% of this budget.',
    );
  }

  /// Bill due reminder 1 day before and on the due date.
  Future<void> scheduleBillReminder({
    required int billId,
    required String name,
    required double amountText,
    required DateTime dueDate,
  }) async {
    await init();
    await _plugin.cancel(billId);
    final dayBefore = DateTime(dueDate.year, dueDate.month, dueDate.day, 9)
        .subtract(const Duration(days: 1));
    if (dayBefore.isAfter(DateTime.now())) {
      await scheduleAt(
        billId,
        'Bill due tomorrow',
        '$name · ₹$amountText is due tomorrow.',
        dayBefore,
      );
    }
    final onDue = DateTime(dueDate.year, dueDate.month, dueDate.day, 9);
    if (onDue.isAfter(DateTime.now())) {
      await scheduleAt(
        billId + 100000,
        'Bill due today',
        '$name · ₹$amountText is due today.',
        onDue,
      );
    }
  }
}
