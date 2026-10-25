import 'package:flutter/material.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:my_task/data/models/task_model.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TaskService _taskService = TaskService();
  final Color primaryBlue = const Color(0xFF5B9BD5);

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  TaskPriority _selectedPriority = TaskPriority.normal;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ============ Date Picker ============
  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
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
            dialogBackgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryBlue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ============ Time Picker ============
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
      return '${weekdays[date.weekday - 1]}، ${date.day} ${months[date.month - 1]}';
    } else {
      return DateFormat('EEEE, d MMMM').format(date);
    }
  }

  // ============ حفظ المهمة ============
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _taskService.addTask(
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        priority: _selectedPriority,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.taskCreatedSuccess),
          backgroundColor: primaryBlue,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC); // لمسة لون فاتح
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white54 : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white; // لون الكروت

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ============ الهيدر ============
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ============ المحتوى ============
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ---------- العنوان ----------
                      Text(
                        l10n.createNewTask,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isArabic
                            ? 'املأ التفاصيل أدناه لإضافة مهمة جديدة'
                            : 'Fill in the details below to add a new task',
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ---------- اسم المهمة ----------
                      Text(
                        l10n.taskName,
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.taskNameHint,
                          hintStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: textColor.withOpacity(0.35),
                          ),
                          prefixIcon: Icon(Icons.title_rounded,
                              color: primaryBlue, size: 22),
                          filled: true,
                          fillColor: cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: subTextColor.withOpacity(0.15),
                                width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                            BorderSide(color: primaryBlue, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                            const BorderSide(color: Colors.red, width: 1),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.taskNameRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 25),

                      // ---------- التاريخ ----------
                      Text(
                        l10n.date,
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: subTextColor.withOpacity(0.15),
                                width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(_selectedDate, isArabic),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isArabic
                                          ? 'اضغط لتغيير التاريخ'
                                          : 'Tap to change date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_right_rounded,
                                color: subTextColor,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ---------- وقت البدء والانتهاء ----------
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.startTime,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickStartTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color:
                                          subTextColor.withOpacity(0.15),
                                          width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline_rounded,
                                          color: primaryBlue,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _formatTime(_startTime),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.endTime,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickEndTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color:
                                          subTextColor.withOpacity(0.15),
                                          width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.stop_circle_outlined,
                                          color: primaryBlue,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _formatTime(_endTime),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                        // ============ التصنيف ============
                      Text(
                        l10n.priority,
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                            cardColor: cardColor,
                          ),
                          _buildPriorityChip(
                            priority: TaskPriority.normal,
                            label: l10n.priorityNormal,
                            icon: Icons.flag_outlined,
                            color: const Color(0xFF5B9BD5),
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                          _buildPriorityChip(
                            priority: TaskPriority.important,
                            label: l10n.priorityImportant,
                            icon: Icons.flag_rounded,
                            color: const Color(0xFFFF9800),
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                          _buildPriorityChip(
                            priority: TaskPriority.veryImportant,
                            label: l10n.priorityVeryImportant,
                            icon: Icons.priority_high_rounded,
                            color: const Color(0xFFF44336),
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // ---------- الوصف ----------
                      Text(
                        l10n.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.descriptionHint,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: subTextColor.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: cardColor,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: subTextColor.withOpacity(0.15),
                                width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                            BorderSide(color: primaryBlue, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 100), // مساحة للزر السفلي
                    ],
                  ),
                ),
              ),
            ),

            // ============ زر Create Task ============
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      l10n.createTask,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
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
    required Color cardColor,
  }) {
    final isSelected = _selectedPriority == priority;

    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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