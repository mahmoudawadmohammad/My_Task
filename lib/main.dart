import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_task/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'core/providers/app_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_wrapper.dart';
import 'data/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en', null);

  // 🔥 تهيئة SettingsService قبل تشغيل التطبيق
  final settingsService = SettingsService();
  await settingsService.init();

  // 👇 التحقق من شاشة البداية
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(MyApp(settingsService: settingsService,showOnboarding: !hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  final bool showOnboarding;
  const MyApp({super.key, required this.settingsService, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    print('🚀 MyApp build - showOnboarding: $showOnboarding');
    return ChangeNotifierProvider(
      create: (_) => AppProvider(settingsService),
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'My Task',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode,
            locale: provider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            home: showOnboarding
                ? _buildOnboarding()
                : _buildAuthWrapper(),
          );
        },
      ),
    );
  }
  Widget _buildOnboarding() {
    print('📱 Showing OnboardingScreen');
    return const OnboardingScreen();
  }

  Widget _buildAuthWrapper() {
    print('🔐 Showing AuthWrapper');
    return const AuthWrapper();
  }
}