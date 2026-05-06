import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static const int _reviewId = 100;

  /// Call this once at app start (before any schedule).
  static Future<void> init() async {
    if (_initialized) return;

    // Ensure bindings so plugin channels are ready
    WidgetsFlutterBinding.ensureInitialized();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher'); // placeholder icon
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    // Initialize plugin
    await _plugin.initialize(settings);

    // Initialize timezones and set a deterministic local zone
    tz.initializeTimeZones();
    // If you want device local zone dynamically, you can integrate flutter_native_timezone.
    // For now, set a fixed zone to avoid LateInitializationError on tz.local.
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    _initialized = true;
  }

  /// Schedule a reminder after [days]. If [days] <= 0, cancels (Off).
  static Future<void> scheduleReviewReminderPeriodDays(int days) async {
    await init(); // make sure we're initialized

    // Always cancel any previous one
    await _plugin.cancel(_reviewId);

    if (days <= 0) return; // Off

    final when = tz.TZDateTime.now(tz.local).add(Duration(days: days));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'review_channel',
        'Review Reminders',
        channelDescription: 'Reminders to review due questions in ShorkariIQ',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _reviewId,
      'Time to Review',
      'You have review questions waiting — open ShorkariIQ.',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'review',
    );
  }

  static Future<void> cancelReviewReminder() async {
    await init();
    await _plugin.cancel(_reviewId);
  }
}
