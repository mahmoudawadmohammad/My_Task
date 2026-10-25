import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_task/core/localization/app_localizations.dart';
import 'package:my_task/data/services/auth_service.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/app_drawer.dart';
import '../../data/models/task_model.dart';
import '../../data/services/task_service.dart';
import '../create_task/create_task_screen.dart';
import '../../widgets/task_card.dart';
import 'dart:io';
import 'package:my_task/data/models/user_model.dart';
import '../../widgets/profile_bottom_sheet.dart';
import 'package:image_picker/image_picker.dart';
import '../notifications/notifications_screen.dart';
import 'dart:async'; // 👈 مهم عشان StreamSubscription

class MyTaskScreen extends StatefulWidget {
  const MyTaskScreen({super.key});

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  final Color primaryBlue = const Color(0xFF5B9BD5);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // null = "الكل" | DateTime = تاريخ محدد
  DateTime? selectedDate;
  bool _isUploadingImage = false;
  TaskPriority? _selectedPriorityFilter; // null = كل التصنيفات

  // ============ حالة التحديد المتعدد ============
  bool _isSelectionMode = false;
  final Set<String> _selectedTaskIds = {};

  // 👇 متغيرات الكاش
  List<TaskModel> _cachedTasks = [];
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    // 👇 الاشتراك في Stream في الخلفية
    _tasksSubscription = _taskService.getAllTasksStream().listen((tasks) {
      if (mounted) {
        setState(() {
          _cachedTasks = tasks;
        });
      }
    });
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedTaskIds.clear();
    });
  }

  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedTaskIds.add(taskId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAllTasks() {
    if (_cachedTasks.isEmpty) return;
    setState(() {
      // نحدد المهام الظاهرة حالياً (بعد فلترة التاريخ والتصنيف)
      final filtered = _getFilteredTasks();
      if (_selectedTaskIds.length == filtered.length) {
        _selectedTaskIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedTaskIds.addAll(filtered.map((t) => t.id));
        _isSelectionMode = true;
      }
    });
  }

  // 👇 دالة مساعدة لفلترة المهام (نفس المنطق داخل _buildDateBarAndTasks)
  List<TaskModel> _getFilteredTasks() {
    List<TaskModel> filteredTasks;
    if (selectedDate == null) {
      filteredTasks = _cachedTasks;
    } else {
      filteredTasks = _cachedTasks.where((task) {
        return task.date.year == selectedDate!.year &&
            task.date.month == selectedDate!.month &&
            task.date.day == selectedDate!.day;
      }).toList();
    }

    if (_selectedPriorityFilter != null) {
      filteredTasks = filteredTasks
          .where((task) => task.priority == _selectedPriorityFilter)
          .toList();
    }
    return filteredTasks;
  }

  Future<void> _deleteSelectedTasks() async {
    if (_selectedTaskIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text(l10n.deleteTasksConfirm(_selectedTaskIds.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in _selectedTaskIds) {
        await _taskService.deleteTask(id);
      }
      setState(() {
        _selectedTaskIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  // ============ عرض الملف الشخصي ============
  Future<void> _showProfile() async {
    final user = await _authService.getCurrentUserData();
    if (user == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => ProfileBottomSheet(user: user),
    );
  }

// ============ عرض خيارات تغيير الصورة ============
  Future<void> _showImagePickerOptions() async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF5B9BD5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => Container(
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
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.changeProfilePicture,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              _pickerOption(
                icon: Icons.camera_alt_rounded,
                label: l10n.takePhoto,
                primaryBlue: primaryBlue,
                textColor: textColor,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadImage(ImageSource.camera);
                },
              ),
              _pickerOption(
                icon: Icons.photo_library_rounded,
                label: l10n.chooseFromGallery,
                primaryBlue: primaryBlue,
                textColor: textColor,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              _pickerOption(
                icon: Icons.delete_outline_rounded,
                label: l10n.removePhoto,
                primaryBlue: Colors.red.shade400,
                textColor: textColor,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _removeProfileImage();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

// ============ خيار واحد في القائمة ============
  Widget _pickerOption({
    required IconData icon,
    required String label,
    required Color primaryBlue,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: textColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

// ============ اختيار ورفع الصورة ============
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) return;

      if (!mounted) return;
      setState(() => _isUploadingImage = true);

      final File imageFile = File(pickedFile.path);
      await _authService.uploadProfileImage(imageFile);

      if (!mounted) return;
      setState(() => _isUploadingImage = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdated),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.imageUploadFailed}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// ============ حذف الصورة ============
  Future<void> _removeProfileImage() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      setState(() => _isUploadingImage = true);
      await _authService.removeProfileImage();
      if (!mounted) return;
      setState(() => _isUploadingImage = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.photoRemoved),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FB);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // ================== الخلفية الزرقاء ==================
          Container(
            height: 350,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
          ),

          // ================== المحتوى ==================
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- الهيدر ----------
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      if (_isSelectionMode) ...[
                        // ============ وضع التحديد ============
                        _squareIconButton(
                          icon: Icons.close_rounded,
                          onTap: _toggleSelectionMode,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.selectedCount(_selectedTaskIds.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _squareIconButton(
                          icon: Icons.select_all_rounded,
                          onTap: _selectAllTasks,
                        ),
                        const SizedBox(width: 8),
                        _squareIconButton(
                          icon: Icons.delete_rounded,
                          onTap: _deleteSelectedTasks,
                        ),
                      ] else ...[
                        // ============ الوضع العادي ============
                        _squareIconButton(
                          icon: Icons.menu_rounded,
                          onTap: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                        const SizedBox(width: 12),
                        _squareIconButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        // 👇 زر تفعيل وضع التحديد
                        _squareIconButton(
                          icon: Icons.checklist_rounded,
                          onTap: () {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedTaskIds.clear();
                            });
                          },
                        ),
                        const Spacer(),
                        StreamBuilder<UserModel?>(
                          stream: _authService.getCurrentUserStream(),
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            final photoUrl = user?.photoUrl;

                            return GestureDetector(
                              onTap: _showProfile,
                              onLongPress: _showImagePickerOptions,
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.6),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                      backgroundImage:
                                      photoUrl != null && photoUrl.isNotEmpty
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: photoUrl == null ||
                                          photoUrl.isEmpty
                                          ? const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                          : null,
                                    ),
                                  ),
                                  if (_isUploadingImage)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ---------- العنوان + زر الإضافة ----------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appName,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.today,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateTaskScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================== قائمة المهام ==================
                // 👇 نستخدم _cachedTasks بدل StreamBuilder
                Expanded(
                  child: _cachedTasks.isEmpty
                      ? Column(
                    children: [
                      _buildDateBar(
                        context: context,
                        dates: const [],
                        isDark: isDark,
                        isArabic: isArabic,
                        l10n: l10n,
                      ),
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF5B9BD5),
                          ),
                        ),
                      ),
                    ],
                  )
                      : _buildDateBarAndTasks(
                    context: context,
                    allTasks: _cachedTasks,
                    isDark: isDark,
                    isArabic: isArabic,
                    l10n: l10n,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ بناء شريط التواريخ + قائمة المهام ============
  Widget _buildDateBarAndTasks({
    required BuildContext context,
    required List<TaskModel> allTasks,
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    // 1) استخراج التواريخ الفريدة من المهام
    final Set<String> uniqueDatesSet = {};
    final List<DateTime> uniqueDates = [];

    for (final task in allTasks) {
      final d = DateTime(task.date.year, task.date.month, task.date.day);
      final key = '${d.year}-${d.month}-${d.day}';
      if (!uniqueDatesSet.contains(key)) {
        uniqueDatesSet.add(key);
        uniqueDates.add(d);
      }
    }

    // ترتيب التواريخ تصاعدياً
    uniqueDates.sort((a, b) => a.compareTo(b));

    // فلترة حسب التاريخ
    List<TaskModel> filteredTasks;
    if (selectedDate == null) {
      filteredTasks = allTasks;
    } else {
      filteredTasks = allTasks.where((task) {
        return task.date.year == selectedDate!.year &&
            task.date.month == selectedDate!.month &&
            task.date.day == selectedDate!.day;
      }).toList();
    }

    // 👇 فلترة حسب التصنيف
    if (_selectedPriorityFilter != null) {
      filteredTasks = filteredTasks
          .where((task) => task.priority == _selectedPriorityFilter)
          .toList();
    }

    return Column(
      children: [
        // شريط التواريخ
        _buildDateBar(
          context: context,
          dates: uniqueDates,
          isDark: isDark,
          isArabic: isArabic,
          l10n: l10n,
        ),

        const SizedBox(height: 20),

        // 👇 فلتر التصنيف
        _buildPriorityFilterBar(
          isDark: isDark,
          isArabic: isArabic,
          l10n: l10n,
        ),

        const SizedBox(height: 20),

        // قائمة المهام
        Expanded(
          child: filteredTasks.isEmpty
              ? _emptyState(l10n, isDark)
              : ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return TaskCard(
                task: task,
                primaryBlue: primaryBlue,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedTaskIds.contains(task.id),
                onSelectToggle: () => _toggleTaskSelection(task.id),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ شريط التواريخ ============
  Widget _buildDateBar({
    required BuildContext context,
    required List<DateTime> dates,
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 10),
        children: [
          // ---------- زر "الكل" ----------
          _buildDateChip(
            label: isArabic ? 'الكل' : 'All',
            subLabel: '📋',
            isSelected: selectedDate == null,
            onTap: () {
              setState(() {
                selectedDate = null;
              });
            },
          ),

          // ---------- التواريخ الفريدة ----------
          ...dates.map((date) {
            final isSelected = selectedDate != null &&
                selectedDate!.year == date.year &&
                selectedDate!.month == date.month &&
                selectedDate!.day == date.day;

            return _buildDateChip(
              label: date.day.toString().padLeft(2, '0'),
              subLabel: _getWeekdayShort(date, isArabic),
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  selectedDate = date;
                });
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  // ============ شكل زر التاريخ الواحد ============
  Widget _buildDateChip({
    required String label,
    required String subLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 55),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryBlue : Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? primaryBlue.withOpacity(0.6)
                    : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ يوم الأسبوع المختصر ============
  String _getWeekdayShort(DateTime date, bool isArabic) {
    if (isArabic) {
      const days = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];
      return days[date.weekday - 1];
    } else {
      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return days[date.weekday - 1];
    }
  }

  // ============ Empty State ============
  Widget _emptyState(AppLocalizations l10n, bool isDark) {
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
              Icons.task_alt_rounded,
              size: 55,
              color: primaryBlue.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noTasks,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noTasksSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============ زر مربع أعلى الشاشة ============
  Widget _squareIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildPriorityFilterBar({
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildPriorityFilterChip(
            priority: null,
            label: l10n.all,
            icon: Icons.list_alt_rounded,
            color: isDark ? Colors.white : Colors.cyan,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildPriorityFilterChip(
            priority: TaskPriority.notImportant,
            label: l10n.priorityNotImportant,
            icon: Icons.low_priority_rounded,
            color: const Color(0xFF9E9E9E),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildPriorityFilterChip(
            priority: TaskPriority.normal,
            label: l10n.priorityNormal,
            icon: Icons.flag_outlined,
            color: const Color(0xFF2E5C8A),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildPriorityFilterChip(
            priority: TaskPriority.important,
            label: l10n.priorityImportant,
            icon: Icons.flag_rounded,
            color: const Color(0xFFFF9800),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildPriorityFilterChip(
            priority: TaskPriority.veryImportant,
            label: l10n.priorityVeryImportant,
            icon: Icons.priority_high_rounded,
            color: const Color(0xFFF44336),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilterChip({
    required TaskPriority? priority,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedPriorityFilter == priority;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _selectedPriorityFilter = priority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cardColor,
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