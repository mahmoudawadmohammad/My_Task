import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_task/core/localization/app_localizations.dart';

import '../../data/models/task_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/pdf_service.dart';
import '../../data/services/task_service.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final PdfService _pdfService = PdfService();
  final Color primaryBlue = const Color(0xFF5B9BD5);

  // 0 = كامل، 1 = تاريخ محدد، 2 = مجال تواريخ
  int _reportType = 0;
  DateTime _specificDate = DateTime.now();
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  final List<DateTime> _excludeDates = [];
  // التصنيف المختار (null = كل التصنيفات)
  TaskPriority? _selectedPriorityFilter;

  bool _isLoading = false;

  // ============ اختيار تاريخ محدد ============
  Future<void> _pickSpecificDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDate,
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _specificDate = picked);
  }

  // ============ اختيار تاريخ البداية ============
  Future<void> _pickFromDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  // ============ اختيار تاريخ النهاية ============
  Future<void> _pickToDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  // ============ إضافة تاريخ للاستثناء ============
  Future<void> _addExcludeDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: _fromDate,
      lastDate: _toDate,
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!_excludeDates.any((d) => _isSameDay(d, picked))) {
        setState(() => _excludeDates.add(picked));
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============ توليد التقرير ============
  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() => _isLoading = true);

    try {
      // جلب كل المهام من Firestore
      final allTasks = await _getAllTasks();

      // فلترة المهام حسب الخيار المختار
      List<TaskModel> filteredTasks;

      if (_reportType == 0) {
        // تقرير كامل
        filteredTasks = allTasks;
      } else if (_reportType == 1) {
        // تاريخ محدد
        filteredTasks = allTasks
            .where((t) => _isSameDay(t.date, _specificDate))
            .toList();
      } else {
        // مجال تواريخ مع استثناءات
        filteredTasks = allTasks.where((t) {
          final d = DateTime(t.date.year, t.date.month, t.date.day);
          final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
          final to = DateTime(_toDate.year, _toDate.month, _toDate.day);

          // داخل المجال؟
          final inRange = !d.isBefore(from) && !d.isAfter(to);
          if (!inRange) return false;

          // مستثنى؟
          final isExcluded = _excludeDates.any((e) => _isSameDay(e, d));
          return !isExcluded;
        }).toList();
      }

      if (_selectedPriorityFilter != null) {
        filteredTasks = filteredTasks
            .where((t) => t.priority == _selectedPriorityFilter)
            .toList();
      }

      if (filteredTasks.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noTasksInRange),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // اسم المستخدم
      final user = await _authService.getCurrentUserData();
      final userName = user?.fullName ?? 'User';

      // توليد PDF
      await _pdfService.generateReport(
        tasks: filteredTasks,
        userName: userName,
        reportTitle: l10n.reportTitle,
        generatedOnLabel: l10n.generatedOn,
        totalLabel: l10n.totalTasks,
        completedLabel: l10n.completedTasks,
        pendingLabel: l10n.pendingTasks,
        isArabic: isArabic,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.reportSuccess),
          backgroundColor: Colors.green.shade600,
        ),
      );
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

  // ============ جلب كل المهام ============
  Future<List<TaskModel>> _getAllTasks() async {
    final stream = _taskService.getAllTasksStream();
    final tasks = await stream.first;
    return tasks;
  }

  // ============ تنسيق التاريخ ============
  String _formatDate(DateTime date, bool isArabic) {
    if (isArabic) {
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.generatePdfReport,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============ عنوان ============
                    Text(
                      l10n.reportOptions,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ============ الخيارات الثلاثة ============
                    _reportTypeCard(
                      index: 0,
                      title: l10n.fullReport,
                      description: l10n.fullReportDesc,
                      icon: Icons.all_inbox_rounded,
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 12),
                    _reportTypeCard(
                      index: 1,
                      title: l10n.specificDate,
                      description: l10n.specificDateDesc,
                      icon: Icons.event_rounded,
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 12),
                    _reportTypeCard(
                      index: 2,
                      title: l10n.dateRange,
                      description: l10n.dateRangeDesc,
                      icon: Icons.date_range_rounded,
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),

                    // ============ تفاصيل التاريخ المحدد ============
                    if (_reportType == 1) ...[
                      const SizedBox(height: 20),
                      _datePickerCard(
                        label: l10n.selectDate,
                        date: _specificDate,
                        onTap: _pickSpecificDate,
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        isArabic: isArabic,
                      ),
                    ],

                    // ============ تفاصيل مجال التواريخ ============
                    if (_reportType == 2) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _datePickerCard(
                              label: l10n.fromDate,
                              date: _fromDate,
                              onTap: _pickFromDate,
                              isDark: isDark,
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              isArabic: isArabic,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _datePickerCard(
                              label: l10n.toDate,
                              date: _toDate,
                              onTap: _pickToDate,
                              isDark: isDark,
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              isArabic: isArabic,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ============ قسم الاستثناءات ============
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.excludeDates,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.excludeDatesDesc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: _addExcludeDate,
                            icon: Icon(Icons.add_circle_rounded,
                                color: primaryBlue, size: 28),
                          ),
                        ],
                      ),

                      if (_excludeDates.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _excludeDates.map((date) {
                            return Chip(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              label: Text(
                                _formatDate(date, isArabic),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              deleteIcon: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
                              onDeleted: () {
                                setState(() => _excludeDates.remove(date));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],

                    const SizedBox(height: 20),

// ============ فلتر التصنيف ============
                    Text(
                      l10n.filterByPriority,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPriorityFilterChip(
                            priority: null,
                            label: l10n.allPriorities,
                            icon: Icons.list_alt_rounded,
                            color: primaryBlue,
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityFilterChip(
                            priority: TaskPriority.notImportant,
                            label: l10n.priorityNotImportant,
                            icon: Icons.low_priority_rounded,
                            color: const Color(0xFF9E9E9E),
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityFilterChip(
                            priority: TaskPriority.normal,
                            label: l10n.priorityNormal,
                            icon: Icons.flag_outlined,
                            color: const Color(0xFF5B9BD5),
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityFilterChip(
                            priority: TaskPriority.important,
                            label: l10n.priorityImportant,
                            icon: Icons.flag_rounded,
                            color: const Color(0xFFFF9800),
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityFilterChip(
                            priority: TaskPriority.veryImportant,
                            label: l10n.priorityVeryImportant,
                            icon: Icons.priority_high_rounded,
                            color: const Color(0xFFF44336),
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // ============ زر التوليد ============
            Padding(
              padding: const EdgeInsets.all(20),
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
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: Text(
                      l10n.generate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  // ============ كارت خيار التقرير ============
  Widget _reportTypeCard({
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final isSelected = _reportType == index;

    return GestureDetector(
      onTap: () => setState(() => _reportType = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : subTextColor.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primaryBlue.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryBlue.withOpacity(0.15)
                    : subTextColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryBlue : subTextColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: subTextColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============ كارت اختيار التاريخ ============
  Widget _datePickerCard({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required bool isArabic,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: subTextColor.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: subTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: primaryBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(date, isArabic),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPriorityFilterChip({
    required TaskPriority? priority,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color cardColor,
  }) {
    final isSelected = _selectedPriorityFilter == priority;

    return GestureDetector(
      onTap: () => setState(() => _selectedPriorityFilter = priority),
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