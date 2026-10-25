import 'package:cloud_firestore/cloud_firestore.dart';

// 👇 تعريف أنواع الأولويات
enum TaskPriority {
  notImportant,  // غير مهمة
  normal,        // عادية
  important,     // مهمة
  veryImportant, // مهمة جداً
}

extension TaskPriorityExtension on TaskPriority {
  // لون كل أولوية
  String get colorHex {
    switch (this) {
      case TaskPriority.notImportant:
        return '#9E9E9E'; // رمادي
      case TaskPriority.normal:
        return '#5B9BD5'; // أزرق
      case TaskPriority.important:
        return '#FF9800'; // برتقالي
      case TaskPriority.veryImportant:
        return '#F44336'; // أحمر
    }
  }

  // اسم المفتاح للتخزين
  String get key {
    switch (this) {
      case TaskPriority.notImportant:
        return 'not_important';
      case TaskPriority.normal:
        return 'normal';
      case TaskPriority.important:
        return 'important';
      case TaskPriority.veryImportant:
        return 'very_important';
    }
  }

  // من مفتاح إلى Enum
  static TaskPriority fromKey(String? key) {
    switch (key) {
      case 'not_important':
        return TaskPriority.notImportant;
      case 'normal':
        return TaskPriority.normal;
      case 'important':
        return TaskPriority.important;
      case 'very_important':
        return TaskPriority.veryImportant;
      default:
        return TaskPriority.normal;
    }
  }
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isCompleted;
  final DateTime createdAt;
  final TaskPriority priority;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    required this.createdAt,
    this.priority = TaskPriority.normal,
  });

  // من Map إلى Model
  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    return TaskModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt:
      (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: TaskPriorityExtension.fromKey(map['priority']),
    );
  }

  // من Model إلى Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'priority': priority.key,
    };
  }

  // نسخة معدّلة
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? isCompleted,
    DateTime? createdAt,
    TaskPriority? priority,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
    );
  }
}