import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../home/my_task_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('🔍 AuthWrapper state: ${snapshot.connectionState}');
        print('🔍 AuthWrapper hasData: ${snapshot.hasData}');
        print('🔍 AuthWrapper user: ${snapshot.data?.email}');
        print('🔍 AuthWrapper error: ${snapshot.error}');
        // ---------- لسا يتحقق ----------
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5B9BD5),
              ),
            ),
          );
        }

        // ---------- المستخدم مسجل دخول ----------
        if (snapshot.hasData && snapshot.data != null) {
          print('✅ Navigating to MyTaskScreen');
          return const MyTaskScreen();
        }

        // ---------- غير مسجل → شاشة الدخول ----------
        print('❌ Showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}