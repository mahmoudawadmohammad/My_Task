import 'package:flutter/material.dart';
import 'package:my_task/core/localization/app_localizations.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../data/models/task_model.dart';
import '../data/services/task_service.dart';
import 'task_details_sheet.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Color primaryBlue;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;

  const TaskCard({
    super.key,
    required this.task,
    this.primaryBlue = const Color(0xFF5B9BD5),
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
  });

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.notImportant:
        return Icons.low_priority_rounded;
      case TaskPriority.normal:
        return Icons.flag_outlined;
      case TaskPriority.important:
        return Icons.flag_rounded;
      case TaskPriority.veryImportant:
        return Icons.priority_high_rounded;
    }
  }

  // ============ تأكيد الحذف ============
  Future<bool?> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.deleteTask),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    // ============ Dismissible للسحب + GestureDetector للضغط ============
    return Dismissible(
      key: Key(task.id),
      direction: isSelectionMode ? DismissDirection.none : DismissDirection.endToStart, // السحب من اليمين لليسار
      // ============ الخلفية الحمراء عند السحب ============
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      // ============ تأكيد قبل الحذف ============
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await TaskService().deleteTask(task.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.taskDeleted),
            backgroundColor: Colors.red.shade400,
          ),
        );
      },
      // ============ الكارت نفسه (قابل للضغط) ============
      child: GestureDetector(
        onTap: () {
          if (isSelectionMode) {
            onSelectToggle?.call();
          } else {
          // فتح Bottom Sheet بتفاصيل المهمة
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (_) => TaskDetailsSheet(task: task),
          );
          }
        },
        onLongPress: () {
          if (!isSelectionMode) onSelectToggle?.call();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelectionMode
                ? Border.all(color: isSelected ? primaryBlue : Colors.transparent, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isSelected ? primaryBlue : Colors.grey,
                    size: 24,
                  ),
                ),
              const SizedBox(width: 10),
              // ============ الأيقونة ============
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? Colors.green.withOpacity(0.12)
                      : Color(int.parse(task.priority.colorHex.replaceFirst('#', '0xFF')))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  task.isCompleted
                      ? Icons.check_circle_rounded
                      : _getPriorityIcon(task.priority),
                  color: task.isCompleted
                      ? Colors.green.shade600
                      : Color(int.parse(task.priority.colorHex.replaceFirst('#', '0xFF'))),
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              // ============ النصوص ============
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: task.isCompleted
                            ? (isDark ? Colors.white54 : Colors.grey.shade500)
                            : (isDark ? Colors.white : Colors.black87),
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (task.description.isNotEmpty)
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: task.isCompleted
                              ? (isDark
                              ? Colors.white38
                              : Colors.grey.shade400)
                              : (isDark
                              ? Colors.white54
                              : Colors.grey.shade600),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ============ الوقت + شارة "تم" + التصنيف ============
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // شارة "تم" (تظهر فقط إذا منفذة)
                  if (task.isCompleted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6, right: 20 , left: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.green.shade600,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isArabic ? 'تم' : 'Done',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // ============ التصنيف ============
                  if (task.priority != TaskPriority.normal)
                    Container(
                      margin: EdgeInsets.only(right: (task.priority == TaskPriority.important) ? 8 : 0, left: (task.priority == TaskPriority.important) ? 6 : 0 ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Color(int.parse(task.priority.colorHex.replaceFirst('#', '0xFF')))
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(task.priority),
                            color: Color(int.parse(task.priority.colorHex.replaceFirst('#', '0xFF'))),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPriorityLabel(task.priority, l10n), // 👈 هنا الاسم
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(int.parse(task.priority.colorHex.replaceFirst('#', '0xFF'))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 5,),
                  // الوقت
                  Container(
                    margin: const EdgeInsets.only(right: 15, left: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.startTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriorityLabel(TaskPriority priority, AppLocalizations l10n) {
    switch (priority) {
      case TaskPriority.notImportant:
        return l10n.priorityNotImportant;
      case TaskPriority.normal:
        return l10n.priorityNormal;
      case TaskPriority.important:
        return l10n.priorityImportant;
      case TaskPriority.veryImportant:
        return l10n.priorityVeryImportant;
    }
  }
}