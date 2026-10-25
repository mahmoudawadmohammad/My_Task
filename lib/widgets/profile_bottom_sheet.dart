import 'package:flutter/material.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:my_task/core/localization/app_localizations.dart';
import 'package:my_task/data/models/user_model.dart';


class ProfileBottomSheet extends StatelessWidget {
  final UserModel user;

  const ProfileBottomSheet({super.key, required this.user});

  // تنسيق تاريخ الانضمام
  String _formatJoinDate(DateTime date, bool isArabic) {
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

            const SizedBox(height: 25),

            // ============ الصورة الشخصية ============
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryBlue,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: primaryBlue.withOpacity(0.15),
                backgroundImage: user.photoUrl != null &&
                    user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? Icon(
                  Icons.person_rounded,
                  size: 55,
                  color: primaryBlue,
                )
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            // ============ الاسم ============
            Text(
              user.fullName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // ============ البريد ============
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  color: subTextColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: subTextColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ============ معلومات إضافية ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // تاريخ الانضمام
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.joinedOn,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatJoinDate(user.createdAt, isArabic),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ============ تلميح: ضغطة طويلة لتغيير الصورة ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    color: subTextColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isArabic
                        ? 'اضغط ضغطة طويلة على الصورة لتغييرها'
                        : 'Long press on picture to change it',
                    style: TextStyle(
                      fontSize: 11,
                      color: subTextColor,
                      fontStyle: FontStyle.italic,
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
}