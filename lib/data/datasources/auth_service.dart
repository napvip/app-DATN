import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user_model.dart';
import 'cloudinary_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    // Yêu cầu Firebase gửi email theo mẫu tiếng Việt (nếu đã cấu hình locale 'vi'
    // trong Console). Tránh email mặc định tiếng Anh.
    try {
      await _auth.setLanguageCode('vi');
    } catch (_) {}
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
    final trimmed = name.trim();

    // Nguồn dữ liệu chính: Firestore users doc (set merge để không lỗi nếu doc thiếu)
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({'name': trimmed}, SetOptions(merge: true));

    // Cập nhật displayName của Auth là phụ — bỏ qua nếu lỗi (tránh lỗi cast Pigeon)
    try {
      await user.updateDisplayName(trimmed);
    } catch (_) {}
  }

  /// Upload avatar – dùng Cloudinary (đồng bộ hạ tầng ảnh với app), nhận bytes
  /// để chạy trên cả Mobile lẫn Web.
  Future<String> uploadAvatar(Uint8List imageBytes) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    // Lấy ảnh avatar cũ để xoá sau khi đổi (nếu là ảnh Cloudinary)
    String? oldUrl;
    try {
      final snap = await _firestore.collection('users').doc(user.uid).get();
      oldUrl = snap.data()?['photoUrl'] as String?;
    } catch (_) {}

    final downloadUrl =
        await CloudinaryService.uploadImage(imageBytes, folder: 'avatars');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({'photoUrl': downloadUrl}, SetOptions(merge: true));

    try {
      await user.updatePhotoURL(downloadUrl);
    } catch (_) {}

    // Xoá ảnh cũ trên Cloudinary (URL không phải Cloudinary sẽ tự bỏ qua)
    if (oldUrl != null && oldUrl.isNotEmpty && oldUrl != downloadUrl) {
      try {
        await CloudinaryService.deleteImageByUrl(oldUrl);
      } catch (_) {}
    }

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
