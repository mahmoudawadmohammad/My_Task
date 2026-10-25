import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import '../models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // مسار مجموعة المهام للمستخدم الحالي: users/{userId}/tasks
  CollectionReference<Map<String, dynamic>>? _tasksCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks');
  }

  // ============ إضافة مهمة جديدة ============
  Future<void> addTask({
    required String title,
    required String description,
    required DateTime date,
    required String startTime,
    required String endTime,
    TaskPriority priority = TaskPriority.normal,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final collection = _tasksCollection();
    if (collection == null) throw Exception('Collection not available');

    final task = TaskModel(
      id: '',
      userId: user.uid,
      title: title.trim(),
      description: description.trim(),
      date: date,
      startTime: startTime,
      endTime: endTime,
      isCompleted: false,
      createdAt: DateTime.now(),
      priority: priority,
    );

    final docRef = await collection.add(task.toMap());
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('locale') ?? 'system';
    bool isArabic;
    if (langCode == 'ar') {
      isArabic = true;
    } else if (langCode == 'en') {
      isArabic = false;
    } else {
      // لغة الجهاز
      final deviceLang = Platform.localeName.split('_').first;
      isArabic = deviceLang == 'ar';
    }
    final notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    // 👇 بعد الحفظ، جدول الإشعارات
    if (notificationsEnabled) {
    await NotificationService().scheduleTaskNotifications(
      taskId: docRef.id,
      taskTitle: title,
      taskDate: date,
      startTimeStr: startTime,
      endTimeStr: endTime,
      isArabic: isArabic, // أو حسب اللغة الحالية
    );
    } else {
      print('🔕 Notifications disabled - skipping scheduling');
    }
  }

  // ============ جلب المهام (Stream - مباشر) ============
  Stream<List<TaskModel>> getTasksStream() {
    final collection = _tasksCollection();
    if (collection == null) return const Stream.empty();

    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ============ جلب كل مهام المستخدم (Stream) ============
  Stream<List<TaskModel>> getAllTasksStream() {
    final collection = _tasksCollection();
    if (collection == null) return const Stream.empty();

    return collection
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ============ جلب مهام يوم معين ============
  Stream<List<TaskModel>> getTasksByDayStream(DateTime day) {
    final collection = _tasksCollection();
    if (collection == null) return const Stream.empty();

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ============ تحديث وقت وتاريخ المهمة ============
  Future<void> updateTaskDateTime({
    required String taskId,
    required DateTime newDate,
    required String newStartTime,
    required String newEndTime,
  }) async {
    final collection = _tasksCollection();
    if (collection == null) throw Exception('Collection not available');

    await collection.doc(taskId).update({
      'date': Timestamp.fromDate(newDate),
      'startTime': newStartTime,
      'endTime': newEndTime,
    });
  }

  // ============ تحديث المهمة كاملة (عنوان + وصف + تاريخ + وقت) ============
  Future<void> updateFullTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime date,
    required String startTime,
    required String endTime,
    TaskPriority priority = TaskPriority.normal,
  }) async {
    final collection = _tasksCollection();
    if (collection == null) throw Exception('Collection not available');

    await collection.doc(taskId).update({
      'title': title.trim(),
      'description': description.trim(),
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'priority': priority.key,
    });
    await NotificationService().cancelTaskNotifications(taskId);
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('locale') ?? 'system';
    final notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    bool isArabic;
    if (langCode == 'ar') {
      isArabic = true;
    } else if (langCode == 'en') {
      isArabic = false;
    } else {
      // لغة الجهاز
      final deviceLang = Platform.localeName.split('_').first;
      isArabic = deviceLang == 'ar';
    }
    if (notificationsEnabled) {
    await NotificationService().scheduleTaskNotifications(
      taskId: taskId,
      taskTitle: title,
      taskDate: date,
      startTimeStr: startTime,
      endTimeStr: endTime,
      isArabic: isArabic,
    );
    } else {
      print('🔕 Notifications disabled - skipping scheduling');
    }
  }

  // ============ تحديث مهمة ============
  Future<void> updateTask(TaskModel task) async {
    final collection = _tasksCollection();
    if (collection == null) throw Exception('Collection not available');

    await collection.doc(task.id).update(task.toMap());
  }

  // ============ حذف مهمة ============
  Future<void> deleteTask(String taskId) async {
    final collection = _tasksCollection();
    if (collection == null) throw Exception('Collection not available');
    await NotificationService().cancelTaskNotifications(taskId);
    await collection.doc(taskId).delete();
  }

  // ============ تبديل حالة الإكمال ============
  Future<void> toggleComplete(String taskId, bool isCompleted) async {
    final collection = _tasksCollection();
    if (collection == null) throw Exception('Collection not available');

    await collection.doc(taskId).update({'isCompleted': isCompleted});
  }
}