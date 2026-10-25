import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// معالج إشعارات الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'task_reminders_channel';
  static const String _channelName = 'Task Reminders';
  static const String _channelDesc =
      'Notifications for task reminders and deadlines';

  // 👇 لحفظ الـ Timers عشان نقدر نلغيها
  final Map<int, Timer> _scheduledHistoryTimers = {};

  bool _initialized = false;

  // ============ التهيئة ============
  Future<void> initialize() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermissions();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Damascus'));
    await _initializeLocalNotifications();
    _setupForegroundListener();

    _initialized = true;
    print('✅ NotificationService initialized');
  }

  Future<void> _requestPermissions() async {
    final settings =
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    print('🔔 FCM Permission: ${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        // ✅ فقط نطبع الـ payload، ما نحفظ هنا لأن NotificationResponse
        // ما فيه title/body. الحفظ يتم في _scheduleNotification
        print('👆 Notification tapped: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  // ============ حفظ الإشعار في السجل ============
  Future<void> _saveNotificationToHistory({
    required String title,
    required String body,
    DateTime? timestamp,
    String? taskId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history =
          prefs.getStringList('notification_history') ?? [];

      final notification = {
        'title': title,
        'body': body,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        'taskId': taskId,
      };

      history.insert(0, jsonEncode(notification));

      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      await prefs.setStringList('notification_history', history);
      print('📝 Notification saved to history: $title');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // ============ عرض إشعار فوري ============
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    // ✅ الإشعارات الفورية تنحفظ فوراً
    await _saveNotificationToHistory(title: title, body: body);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ============ جدولة إشعارات المهمة الثلاثة ============
  Future<void> scheduleTaskNotifications({
    required String taskId,
    required String taskTitle,
    required DateTime taskDate,
    required String startTimeStr,
    required String endTimeStr,
    required bool isArabic,
  }) async {
    final startTime = _parseTimeString(startTimeStr, taskDate);
    final endTime = _parseTimeString(endTimeStr, taskDate);
    final reminderTime = startTime.subtract(const Duration(minutes: 10));

    final baseId = taskId.hashCode;
    final reminderId = baseId + 1;
    final startId = baseId + 2;
    final endId = baseId + 3;

    final now = DateTime.now();

    if (reminderTime.isAfter(now)) {
      await _scheduleNotification(
        id: reminderId,
        title: isArabic ? '🔔 تذكير بمهمة' : '🔔 Task Reminder',
        body: isArabic
            ? 'مهمة "$taskTitle" ستبدأ بعد 10 دقائق.'
            : 'Task "$taskTitle" starts in 10 minutes.',
        scheduledDate: reminderTime,
        payload: 'task_$taskId',
        taskId: taskId,
      );
    }

    if (startTime.isAfter(now)) {
      await _scheduleNotification(
        id: startId,
        title: isArabic ? '▶️ حان وقت المهمة' : '▶️ Task Started',
        body: isArabic
            ? 'مهمة "$taskTitle" قد بدأت الآن.'
            : 'Task "$taskTitle" has started now.',
        scheduledDate: startTime,
        payload: 'task_$taskId',
        taskId: taskId,
      );
    }

    if (endTime.isAfter(now)) {
      await _scheduleNotification(
        id: endId,
        title: isArabic ? '⏹️ انتهى وقت المهمة' : '⏹️ Task Time Ended',
        body: isArabic
            ? 'انتهى وقت مهمة "$taskTitle". يرجى إكمالها أو تمديدها.'
            : 'Task "$taskTitle" time is up. Please complete or extend it.',
        scheduledDate: endTime,
        payload: 'task_$taskId',
        taskId: taskId,
      );
    }

    print('✅ Scheduled 3 notifications for task: $taskTitle');
  }

  // ============ جدولة إشعار واحد (مع حفظ في السجل لما يحين وقته) ============
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String? taskId,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      ),
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    await _saveNotificationToHistory(
      title: title,
      body: body,
      timestamp: scheduledDate,
      taskId: taskId,
    );

  }

  // ============ إلغاء إشعارات مهمة معينة (مع حذف من السجل) ============
  Future<void> cancelTaskNotifications(String taskId) async {
    final baseId = taskId.hashCode;
    final reminderId = baseId + 1;
    final startId = baseId + 2;
    final endId = baseId + 3;

    // 1. إلغاء الإشعارات المجدولة
    await _localNotifications.cancel(reminderId);
    await _localNotifications.cancel(startId);
    await _localNotifications.cancel(endId);

    // 2. إلغاء الـ Timers
    _scheduledHistoryTimers[reminderId]?.cancel();
    _scheduledHistoryTimers[startId]?.cancel();
    _scheduledHistoryTimers[endId]?.cancel();
    _scheduledHistoryTimers.remove(reminderId);
    _scheduledHistoryTimers.remove(startId);
    _scheduledHistoryTimers.remove(endId);

    // 3. حذف الإشعارات من السجل (اللي لها علاقة بهذي المهمة)
    await _removeNotificationsFromHistory(taskId);

    print('🗑️ Cancelled all notifications for task: $taskId');
  }

  // ============ حذف إشعارات المهمة من السجل ============
  Future<void> _removeNotificationsFromHistory(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history =
          prefs.getStringList('notification_history') ?? [];

      final filtered = history.where((e) {
        try {
          final map = jsonDecode(e) as Map<String, dynamic>;
          return map['taskId'] != taskId;
        } catch (_) {
          return true;
        }
      }).toList();

      await prefs.setStringList('notification_history', filtered);
      print('🗑️ Removed notifications for task: $taskId from history');
    } catch (e) {
      print('❌ Error removing notifications from history: $e');
    }
  }

  // ============ إلغاء كل الإشعارات ============
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();

    // إلغاء كل الـ Timers
    for (final timer in _scheduledHistoryTimers.values) {
      timer.cancel();
    }
    _scheduledHistoryTimers.clear();

    print('🗑️ All notifications cancelled');
  }

  // ============ دوال مساعدة ============
  DateTime _parseTimeString(String timeStr, DateTime date) {
    try {
      final format = DateFormat('hh:mm a');
      final parsed = format.parse(timeStr);
      return DateTime(
          date.year, date.month, date.day, parsed.hour, parsed.minute);
    } catch (e) {
      return date;
    }
  }
}