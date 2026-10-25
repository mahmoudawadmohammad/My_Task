import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_task/core/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Color primaryBlue = const Color(0xFF5B9BD5);
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  // ============ حالة التحديد ============
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  // ============ تفعيل / إلغاء وضع التحديد ============
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIndices.clear();
      }
    });
  }

  // ============ تحديد / إلغاء تحديد إشعار معين ============
  void _toggleNotificationSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        // إذا ما في شي محدد، نخرج من وضع التحديد تلقائياً
        if (_selectedIndices.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  // ============ تحديد الكل / إلغاء تحديد الكل ============
  void _selectAllNotifications() {
    setState(() {
      if (_selectedIndices.length == _notifications.length) {
        // إذا كان الكل محدد، نلغي التحديد
        _selectedIndices.clear();
        _isSelectionMode = false;
      } else {
        // نحدد كل الإشعارات
        _selectedIndices.addAll(
          List.generate(_notifications.length, (i) => i),
        );
        _isSelectionMode = true;
      }
    });
  }

  // ============ حذف الإشعارات المحددة ============
  Future<void> _deleteSelectedNotifications() async {
    if (_selectedIndices.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // نافذة تأكيد
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isArabic ? 'حذف الإشعارات' : 'Delete Notifications'),
        content: Text(
          isArabic
              ? 'هل تريد حذف ${_selectedIndices.length} إشعار؟'
              : 'Delete ${_selectedIndices.length} notifications?',
        ),
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

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history = prefs.getStringList('notification_history') ?? [];

      // نحذف من الأكبر للأصغر عشان الـ indices ما تتأثر
      final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));

      for (final index in sortedIndices) {
        if (index >= 0 && index < history.length) {
          history.removeAt(index);
        }
      }

      await prefs.setStringList('notification_history', history);

      if (!mounted) return;

      setState(() {
        _selectedIndices.clear();
        _isSelectionMode = false;
      });

      // إعادة تحميل الإشعارات عشان تنعرض التحديثات
      await _loadNotifications();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }


  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('notification_history') ?? [];
    final now = DateTime.now();
    setState(() {
      _notifications = history
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .where((n) {
        final timestamp = DateTime.tryParse(n['timestamp'] ?? '');
        return timestamp != null && !timestamp.isAfter(now);
      })
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_history');
    setState(() => _notifications = []);
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
      final time = DateFormat('hh:mm a').format(date);
      return '${weekdays[date.weekday - 1]}، ${date.day} ${months[date.month - 1]} - $time';
    } else {
      return DateFormat('EEEE, d MMMM - hh:mm a').format(date);
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
          icon: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back),
          onPressed: _isSelectionMode ? _toggleSelectionMode : () => Navigator.pop(context),
        ),
        title: Text(
          _isSelectionMode ? '${_selectedIndices.length}' :(isArabic ? 'الإشعارات' : 'Notifications'),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: _isSelectionMode ? [
          IconButton(icon: Icon(Icons.select_all), onPressed: _selectAllNotifications),
          IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelectedNotifications),
        ] : [
          IconButton(icon: Icon(Icons.checklist), onPressed: () => setState(() => _isSelectionMode = true)),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B9BD5)),
        )
            : _notifications.isEmpty
            ? _emptyState(isArabic, isDark, textColor, subTextColor)
            : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final notif = _notifications[index];
            final timestamp = DateTime.tryParse(
                notif['timestamp'] ?? '') ??
                DateTime.now();

            return GestureDetector(
                onTap: _isSelectionMode ? () => _toggleNotificationSelection(index) : null,
                onLongPress: () => setState(() { _isSelectionMode = true; _selectedIndices.add(index); }),
              child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: _isSelectionMode && _selectedIndices.contains(index)
                    ? Border.all(color: primaryBlue, width: 2)
                    : null,
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Icon(_selectedIndices.contains(index) ? Icons.check_circle : Icons.circle_outlined, color: primaryBlue),
                  const SizedBox(width: 5,),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['title'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif['body'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: subTextColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(timestamp, isArabic),
                          style: TextStyle(
                            fontSize: 11,
                            color: subTextColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState(
      bool isArabic, bool isDark, Color textColor, Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 55,
              color: primaryBlue.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'لا توجد إشعارات' : 'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'ستظهر هنا جميع الإشعارات الواردة'
                : 'All incoming notifications will appear here',
            style: TextStyle(fontSize: 13, color: subTextColor),
          ),
        ],
      ),
    );
  }
}