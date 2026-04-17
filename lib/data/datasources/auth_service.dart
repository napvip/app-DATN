import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // Trạng thái auth
  // ---------------------------------------------------------------------------

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Email / Password
  // ---------------------------------------------------------------------------

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    await user.reload();

    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? email.trim(),
      name: name.trim(),
      photoUrl: '',
      createdAt: DateTime.now(),
      role: 'user',
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _getOrCreateUserDoc(credential.user!);
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In – dùng signInWithProvider (firebase_auth v5)
  // Web: signInWithPopup | Mobile: signInWithProvider (Chrome Custom Tab)
  // Không dùng google_sign_in package để tránh lỗi Credential Manager & People API
  // ---------------------------------------------------------------------------

  Future<UserModel> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider()..addScope('email');

    final UserCredential userCredential;
    if (kIsWeb) {
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      userCredential = await _auth.signInWithProvider(googleProvider);
    }

    return _getOrCreateUserDoc(userCredential.user!);
  }

  // ---------------------------------------------------------------------------
  // Đặt lại mật khẩu
  // ---------------------------------------------------------------------------

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ---------------------------------------------------------------------------
  // Đăng xuất
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Firestore helpers
  // ---------------------------------------------------------------------------

  Future<UserModel> _getOrCreateUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snap = await docRef.get();

    if (snap.exists) return UserModel.fromMap(snap.data()!);

    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      createdAt: DateTime.now(),
      role: 'user',
    );

    await docRef.set(userModel.toMap());
    return userModel;
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _firestore.collection('users').doc(user.uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.data()!);
  }

  // ---------------------------------------------------------------------------
  // Cập nhật profile
  // ---------------------------------------------------------------------------

  Future<void> updateUserName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await Future.wait([
      _firestore
          .collection('users')
          .doc(user.uid)
          .update({'name': name.trim()}),
      user.updateDisplayName(name.trim()),
    ]);
  }

  /// Upload avatar – nhận bytes để hoạt động trên cả Mobile lẫn Web.
  Future<String> uploadAvatar(Uint8List imageBytes) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final ref = _storage.ref().child('avatars/${user.uid}.jpg');
    final snapshot = await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await Future.wait([
      _firestore
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': downloadUrl}),
      user.updatePhotoURL(downloadUrl),
    ]);

    return downloadUrl;
  }

  // ---------------------------------------------------------------------------
  // Thông báo lỗi tiếng Việt
  // ---------------------------------------------------------------------------

  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Email này đã được đăng ký. Vui lòng đăng nhập.';
        case 'invalid-email':
          return 'Địa chỉ email không hợp lệ.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng dùng ít nhất 6 ký tự.';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'wrong-password':
          return 'Mật khẩu không đúng. Vui lòng thử lại.';
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không chính xác.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        case 'too-many-requests':
          return 'Quá nhiều lần thử. Vui lòng đợi một lúc rồi thử lại.';
        case 'network-request-failed':
          return 'Lỗi mạng. Vui lòng kiểm tra kết nối internet.';
        case 'user-cancelled':
        case 'canceled':
        case 'popup-closed-by-user':
          return 'Đăng nhập Google đã bị hủy.';
        case 'operation-not-allowed':
          return 'Phương thức đăng nhập này chưa được bật trong Firebase Console.';
        case 'account-exists-with-different-credential':
          return 'Email đã tồn tại với phương thức đăng nhập khác.';
        case 'requires-recent-login':
          return 'Vui lòng đăng nhập lại để thực hiện thao tác này.';
        default:
          return error.message ?? 'Đã xảy ra lỗi không xác định.';
      }
    }
    return 'Lỗi: ${error.toString()}';
  }
}
