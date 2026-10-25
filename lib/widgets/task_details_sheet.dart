import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_task/core/localization/app_localizations.dart';

import '../data/models/task_model.dart';
import '../data/services/task_service.dart';
import 'edit_task_dialog.dart';

class TaskDetailsSheet extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsSheet({super.key, required this.task});

  @override
  State<TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<TaskDetailsSheet> {
  late bool _isCompleted;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.isCompleted;
  }

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

  // ============ دالة تبديل حالة المهمة ============
  Future<void> _toggleComplete() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      final newState = !_isCompleted;
      await TaskService().toggleComplete(widget.task.id, newState);

      if (!mounted) return;
      setState(() {
        _isCompleted = newState;
        _isLoading = false;
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            newState ? l10n.taskCompleted : l10n.taskIncompleted,
          ),
          backgroundColor: newState ? Colors.green.shade600 : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============ تنسيق التاريخ ============
  String _formatDate(DateTime date, bool isArabic) {
    if (isArabic) {
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      final weekdays = [
        'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
        'الجمعة', 'السبت', 'الأحد'
      ];
      return '${weekdays[date.weekday - 1]}، ${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primaryBlue = const Color(0xFF5B9BD5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ============ مقبض السحب ============
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: subTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // ============ العنوان ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? Colors.green.withOpacity(0.15)
                          : primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.task_alt_rounded,
                      color: _isCompleted
                          ? Colors.green.shade600
                          : primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.taskDetails,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            decoration: _isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ============ شارة التصنيف ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                          widget.task.priority.colorHex.replaceFirst('#', '0xFF')))
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(widget.task.priority),
                          color: Color(int.parse(
                              widget.task.priority.colorHex.replaceFirst('#', '0xFF'))),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getPriorityLabel(widget.task.priority, l10n),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(
                                widget.task.priority.colorHex.replaceFirst('#', '0xFF'))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ============ الوصف ============
            if (widget.task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.description,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // ============ معلومات التاريخ والوقت ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.calendar_today_rounded,
                      label: l10n.date,
                      value: _formatDate(widget.task.date, isArabic),
                      primaryBlue: primaryBlue,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.play_arrow_rounded,
                      label: l10n.startTimeLabel,
                      value: widget.task.startTime,
                      primaryBlue: primaryBlue,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      icon: Icons.stop_rounded,
                      label: l10n.endTimeLabel,
                      value: widget.task.endTime,
                      primaryBlue: primaryBlue,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ============ زر الإكمال ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCompleted
                        ? Colors.orange
                        : Colors.green.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Icon(
                    _isCompleted
                        ? Icons.undo_rounded
                        : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: Text(
                    _isCompleted
                        ? l10n.markAsIncomplete
                        : l10n.markAsCompleted,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ============ الأزرار ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // زر الحذف
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger =
                          ScaffoldMessenger.of(context);
                          final l10n = AppLocalizations.of(context)!;

                          navigator.pop();

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(l10n.deleteTask),
                              content: Text(l10n.deleteConfirm),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: Text(
                                    l10n.delete,
                                    style: const TextStyle(
                                        color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await TaskService()
                                  .deleteTask(widget.task.id);
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(l10n.taskDeleted),
                                  backgroundColor: Colors.red.shade400,
                                ),
                              );
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.red.shade400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        label: Text(
                          l10n.delete,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر التعديل
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) =>
                                EditTaskDialog(task: widget.task),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          l10n.editTask,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ============ كارت المعلومات ============
  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryBlue,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}