import 'package:flutter/material.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_task/core/localization/app_localizations.dart' show AppLocalizations;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../core/providers/app_provider.dart';
import '../data/services/auth_service.dart';
import '../screens/report/generate_report_screen.dart';
import '../../data/services/notification_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primaryBlue = const Color(0xFF5B9BD5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Drawer(
      backgroundColor:
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FC),
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ============ الهيدر ============
            Container(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 25),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  // أيقونة التطبيق
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settings,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.appName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // زر الإغلاق
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // ============ المحتوى ============
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================== قسم الإشعارات ==================
                    _sectionTitle(l10n.notifications, textColor),
                    const SizedBox(height: 10),
                    _settingCard(
                      isDark: isDark,
                      child: SwitchListTile(
                        value: provider.notificationsEnabled,
                        onChanged: (value) async {
                          await provider.setNotificationsEnabled(value);
                          // 👇 نافذة تأكيد (اختياري)
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? (isArabic
                                    ? 'تم تفعيل الإشعارات 🔔'
                                    : 'Notifications enabled 🔔')
                                    : (isArabic
                                    ? 'تم إلغاء تفعيل الإشعارات 🔕'
                                    : 'Notifications disabled 🔕'),
                              ),
                              backgroundColor: value ? Colors.green.shade600 : Colors.orange,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        title: Text(
                          l10n.enableNotifications,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            provider.notificationsEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color: primaryBlue,
                            size: 20,
                          ),
                        ),
                        activeColor: primaryBlue,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ================== قسم اللغة ==================
                    _sectionTitle(l10n.language, textColor),
                    const SizedBox(height: 10),
                    _settingCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _radioTile(
                            title: l10n.systemLanguage,
                            subtitle: null,
                            icon: Icons.language_rounded,
                            isSelected: provider.locale == null,
                            primaryBlue: primaryBlue,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () => provider.setLocale(null),
                          ),
                          Divider(
                            height: 1,
                            color: subTextColor.withOpacity(0.15),
                          ),
                          _radioTile(
                            title: l10n.arabic,
                            subtitle: 'العربية',
                            icon: Icons.translate_rounded,
                            isSelected:
                            provider.locale?.languageCode == 'ar',
                            primaryBlue: primaryBlue,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () =>
                                provider.setLocale(const Locale('ar')),
                          ),
                          Divider(
                            height: 1,
                            color: subTextColor.withOpacity(0.15),
                          ),
                          _radioTile(
                            title: l10n.english,
                            subtitle: 'English',
                            icon: Icons.translate_rounded,
                            isSelected:
                            provider.locale?.languageCode == 'en',
                            primaryBlue: primaryBlue,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () =>
                                provider.setLocale(const Locale('en')),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ================== قسم الوضع ==================
                    _sectionTitle(l10n.theme, textColor),
                    const SizedBox(height: 10),
                    _settingCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _radioTile(
                            title: l10n.systemMode,
                            subtitle: null,
                            icon: Icons.brightness_auto_rounded,
                            isSelected:
                            provider.themeMode == ThemeMode.system,
                            primaryBlue: primaryBlue,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () =>
                                provider.setThemeMode(ThemeMode.system),
                          ),
                          Divider(
                            height: 1,
                            color: subTextColor.withOpacity(0.15),
                          ),
                          _radioTile(
                            title: l10n.lightMode,
                            subtitle: null,
                            icon: Icons.light_mode_rounded,
                            isSelected:
                            provider.themeMode == ThemeMode.light,
                            primaryBlue: primaryBlue,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () =>
                                provider.setThemeMode(ThemeMode.light),
                          ),
                          Divider(
                            height: 1,
                            color: subTextColor.withOpacity(0.15),
                          ),
                          _radioTile(
                            title: l10n.darkMode,
                            subtitle: null,
                            icon: Icons.dark_mode_rounded,
                            isSelected:
                            provider.themeMode == ThemeMode.dark,
                            primaryBlue: primaryBlue,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            onTap: () =>
                                provider.setThemeMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ================== قسم متقدم ==================
                    _sectionTitle(l10n.advanced, textColor),
                    const SizedBox(height: 10),
                    _settingCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.appVersion,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'v$appVersion',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: subTextColor.withOpacity(0.15),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.copyright_rounded,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '© ${DateTime.now().year}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.allRightsReserved,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: subTextColor.withOpacity(0.15),
                          ),
// 👇 زر إعادة جولة التعريف
                          InkWell(
                            onTap: () async {
                              // نافذة تأكيد
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Text(l10n.restartOnboarding),
                                  content: Text(l10n.restartOnboardingConfirm),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        isArabic ? 'إعادة' : 'Restart',
                                        style: TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                // مسح علم "شاهد التعريف"
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('hasSeenOnboarding', false);

                                if (!context.mounted) return;

                                // الانتقال لشاشة التعريف
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OnboardingScreen(),
                                  ),
                                      (route) => false,
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.help_outline_rounded,
                                      color: primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.restartOnboarding,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.restart_alt_rounded,
                                    color: subTextColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: subTextColor.withOpacity(0.15),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GenerateReportScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.generatePdfReport,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: subTextColor,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ================== زر تسجيل الخروج ==================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await AuthService().logout();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.red.shade400,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        label: Text(
                          l10n.logout,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ عنوان القسم ============
  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============ كارت الإعداد ============
  Widget _settingCard({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============ صف اختيار (Radio Tile) ============
  Widget _radioTile({
    required String title,
    required String? subtitle,
    required IconData icon,
    required bool isSelected,
    required Color primaryBlue,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryBlue.withOpacity(0.15)
                    : subTextColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryBlue : subTextColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: subTextColor,
                      ),
                    ),
                  ],
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
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
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
}