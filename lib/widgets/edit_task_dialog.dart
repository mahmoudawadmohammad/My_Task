import 'package:flutter/material.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:my_task/core/localization/app_localizations.dart';

import '../data/models/task_model.dart';
import '../data/services/task_service.dart';

class EditTaskDialog extends StatefulWidget {
  final TaskModel task;

  const EditTaskDialog({super.key, required this.task});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskPriority _selectedPriority;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isLoading = false;

  final Color primaryBlue = const Color(0xFF5B9BD5);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.date;
    _startTime = _parseTime(widget.task.startTime);
    _endTime = _parseTime(widget.task.endTime);
    _selectedPriority = widget.task.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ============ تحويل String Time إلى TimeOfDay ============
  TimeOfDay _parseTime(String timeStr) {
    try {
      final format = DateFormat('hh:mm a');
      final dt = format.parse(timeStr);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      return const TimeOfDay(hour: 10, minute: 0);
    }
  }

  // ============ تنسيق الوقت ============
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
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

  // ============ اختيار التاريخ ============
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ============ اختيار وقت البدء ============
  Future<void> _pickStartTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      initialEntryMode: TimePickerEntryMode.dialOnly,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false, // 👈 هذا اللي يخليها 12 ساعة
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme(
                brightness: isDark ? Brightness.dark : Brightness.light,
                primary: primaryBlue,
                onPrimary: Colors.white,
                secondary: primaryBlue,
                onSecondary: Colors.white,
                error: Colors.red,
                onError: Colors.white,
                surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                onSurface: isDark ? Colors.white : Colors.black,
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor:
                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                hourMinuteColor: primaryBlue.withOpacity(0.15),
                hourMinuteTextColor: primaryBlue,
                dialHandColor: primaryBlue,
                dialBackgroundColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                dialTextColor: isDark ? Colors.white : Colors.black87,
                entryModeIconColor: primaryBlue,
                helpTextStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
                cancelButtonStyle: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                ),
                confirmButtonStyle: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: primaryBlue),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  // ============ اختيار وقت الانتهاء ============
  Future<void> _pickEndTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      initialEntryMode: TimePickerEntryMode.dialOnly,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false, // 👈 هذا اللي يخليها 12 ساعة
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme(
                brightness: isDark ? Brightness.dark : Brightness.light,
                primary: primaryBlue,
                onPrimary: Colors.white,
                secondary: primaryBlue,
                onSecondary: Colors.white,
                error: Colors.red,
                onError: Colors.white,
                surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                onSurface: isDark ? Colors.white : Colors.black,
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor:
                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                hourMinuteColor: primaryBlue.withOpacity(0.15),
                hourMinuteTextColor: primaryBlue,
                dialHandColor: primaryBlue,
                dialBackgroundColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                dialTextColor: isDark ? Colors.white : Colors.black87,
                entryModeIconColor: primaryBlue,
                helpTextStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
                cancelButtonStyle: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                ),
                confirmButtonStyle: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: primaryBlue),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  // ============ الحفظ ============
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await TaskService().updateFullTask(
        taskId: widget.task.id,
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        priority: _selectedPriority,
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.taskUpdated),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.updateFailed}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final dialogColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFF5F7FB);

    return Dialog(
      backgroundColor: dialogColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============ العنوان الرئيسي ============
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.editTaskTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    // زر إغلاق
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: subTextColor,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ============ حقل العنوان ============
                _label(l10n.titleLabel, subTextColor),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: _inputDecoration(
                    hint: l10n.titleHint,
                    icon: Icons.task_alt_rounded,
                    fillColor: inputFillColor,
                    subTextColor: subTextColor,
                    primaryBlue: primaryBlue,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.titleRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                    // ============ التصنيف ============
                _label(l10n.priority, subTextColor),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPriorityChip(
                      priority: TaskPriority.notImportant,
                      label: l10n.priorityNotImportant,
                      icon: Icons.low_priority_rounded,
                      color: const Color(0xFF9E9E9E),
                      textColor: textColor,
                      inputFillColor: inputFillColor,
                    ),
                    _buildPriorityChip(
                      priority: TaskPriority.normal,
                      label: l10n.priorityNormal,
                      icon: Icons.flag_outlined,
                      color: const Color(0xFF5B9BD5),
                      textColor: textColor,
                      inputFillColor: inputFillColor,
                    ),
                    _buildPriorityChip(
                      priority: TaskPriority.important,
                      label: l10n.priorityImportant,
                      icon: Icons.flag_rounded,
                      color: const Color(0xFFFF9800),
                      textColor: textColor,
                      inputFillColor: inputFillColor,
                    ),
                    _buildPriorityChip(
                      priority: TaskPriority.veryImportant,
                      label: l10n.priorityVeryImportant,
                      icon: Icons.priority_high_rounded,
                      color: const Color(0xFFF44336),
                      textColor: textColor,
                      inputFillColor: inputFillColor,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ============ حقل الوصف ============
                _label(l10n.descriptionLabel, subTextColor),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                  decoration: _inputDecoration(
                    hint: l10n.descriptionEmpty,
                    icon: Icons.notes_rounded,
                    fillColor: inputFillColor,
                    subTextColor: subTextColor,
                    primaryBlue: primaryBlue,
                  ),
                ),

                const SizedBox(height: 20),

                // ============ حقل التاريخ ============
                _label(l10n.date, subTextColor),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: inputFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDate(_selectedDate, isArabic),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: subTextColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ============ الأوقات ============
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(l10n.startTimeLabel, subTextColor),
                          const SizedBox(height: 6),
                          _timeField(
                            time: _startTime,
                            onTap: _pickStartTime,
                            icon: Icons.play_arrow_rounded,
                            fillColor: inputFillColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            primaryBlue: primaryBlue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(l10n.endTimeLabel, subTextColor),
                          const SizedBox(height: 6),
                          _timeField(
                            time: _endTime,
                            onTap: _pickEndTime,
                            icon: Icons.stop_rounded,
                            fillColor: inputFillColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            primaryBlue: primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // ============ الأزرار ============
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: subTextColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            l10n.save,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ Label ============
  Widget _label(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  // ============ Input Decoration ============
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color fillColor,
    required Color subTextColor,
    required Color primaryBlue,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: subTextColor.withOpacity(0.7),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      filled: true,
      fillColor: fillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primaryBlue.withOpacity(0.15),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  // ============ حقل الوقت ============
  Widget _timeField({
    required TimeOfDay time,
    required VoidCallback onTap,
    required IconData icon,
    required Color fillColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryBlue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryBlue.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryBlue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPriorityChip({
    required TaskPriority priority,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color inputFillColor,
  }) {
    final isSelected = _selectedPriority == priority;

    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : inputFillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}