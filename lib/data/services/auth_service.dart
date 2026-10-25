import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:imgbb_uploader/imgbb.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _imgbbApiKey = '4d3c5119a0adfdc3082d9111c174914e';
  // المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // تيار حالة المصادقة (يستخدمه AuthWrapper)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============ تسجيل الدخول ============
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) return null;

      // 🔥 تأكد أن users doc موجود، وإلا أنشئه
      final uid = credential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        // أنشئ الـ doc إذا مو موجود
        final newUser = UserModel(
          uid: uid,
          email: credential.user!.email ?? email,
          fullName: credential.user!.displayName ?? 'User',
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(uid).set(newUser.toMap());
        return newUser;
      }

      return UserModel.fromMap(userDoc.data()!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

// ============ Stream لبيانات المستخدم (يتحدث تلقائياً) ============
  Stream<UserModel?> getCurrentUserStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }


  // ============ رفع الصورة الشخصية (عبر ImgBB) ============
  Future<String?> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // رفع الصورة على ImgBB
      final uploader = ImgbbUploader(_imgbbApiKey);

      final result = await uploader.uploadImageFile(
        imageFile: imageFile,
        name: user.uid,   // اسم الملف = uid المستخدم
      );

      // استخراج الرابط المباشر
      final String? downloadUrl = result?.data?.url;

      if (downloadUrl == null) {
        throw Exception('Upload failed: no URL returned');
      }

      // تحديث Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      // تحديث Firebase Auth
      await user.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // ============ حذف الصورة الشخصية ============
// ملاحظة: ImgBB ما يسمح بالحذف عبر API مجاناً،
// فنكتفي بحذف الرابط من Firestore و Auth
  Future<void> removeProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // حذف من Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': null,
      });

      // حذف من Auth
      await user.updatePhotoURL(null);
    } catch (e) {
      throw Exception('Remove failed: $e');
    }
  }

  // ============ إنشاء حساب ============
  Future<UserModel?> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) return null;

      // تحديث الاسم في Firebase Auth
      await credential.user!.updateDisplayName(fullName);

      // إنشاء نموذج المستخدم
      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        createdAt: DateTime.now(),
      );

      // حفظ بيانات المستخدم في Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============ تسجيل الخروج ============
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ============ إرسال رابط إعادة تعيين كلمة المرور ============
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============ جلب بيانات المستخدم من Firestore ============
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // ============ معالجة أخطاء Firebase Auth ============
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return e.message ?? 'An unknown error occurred';
    }
  }
}