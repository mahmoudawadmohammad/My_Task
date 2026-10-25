import 'package:flutter/material.dart';
import 'package:my_task/core/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_wrapper.dart'; // أو أي شاشة تبدأ منها

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Color primaryBlue = const Color(0xFF5B9BD5);

  // سيتم بناء البيانات داخل build عشان نستخدم الترجمة
  List<Map<String, dynamic>> _getPages(AppLocalizations l10n) {
    return [
      {
        'title': l10n.onboardingTitle1,
        'description': l10n.onboardingDesc1,
        'icon': Icons.task_alt_rounded,
        'color': primaryBlue,
      },
      {
        'title': l10n.onboardingTitle2,
        'description': l10n.onboardingDesc2,
        'icon': Icons.calendar_month_rounded,
        'color': Colors.orangeAccent,
      },
      {
        'title': l10n.onboardingTitle3,
        'description': l10n.onboardingDesc3,
        'icon': Icons.emoji_events_rounded,
        'color': Colors.greenAccent,
      },
    ];
  }

  // دالة لحفظ أن المستخدم شاهد الشاشة والانتقال
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true); // نحفظ القيمة

    if (!mounted) return;
    // الانتقال لشاشة تسجيل الدخول
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final pages = _getPages(l10n);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ============ زر التخطي ============
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  l10n.skip,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // ============ محتوى الشرائح ============
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // الأيقونة الكبيرة
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: page['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page['icon'],
                            size: 90,
                            color: page['color'],
                          ),
                        ),
                        const SizedBox(height: 50),
                        // العنوان
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // الوصف
                        Text(
                          page['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: subTextColor,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ============ مؤشرات الصفحات (Dots) ============
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? primaryBlue
                        : primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ============ زر التالي / ابدأ الآن ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == pages.length - 1
                        ? l10n.getStarted
                        : l10n.next,
                    style: const TextStyle(
                      fontSize: 17,
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
    );
  }
}