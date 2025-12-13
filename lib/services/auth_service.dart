import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart'; // Dùng cho debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Hàm tiện ích để ghi log (chỉ in ra trong chế độ debug)
  void _logError(String method, dynamic e) {
    debugPrint('LỖI Đăng nhập $method: $e');
  }

  // --- 1. Đăng nhập bằng Google ---
  Future<User?> signInWithGoogle() async {
    try {
      // ⚠️ THÊM LỆNH ĐĂNG XUẤT NÀY ĐỂ BUỘC HIỂN THỊ HỘP THOẠI CHỌN TÀI KHOẢN
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng hủy

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      _logError('Google', e);
      return null;
    }
  }

  // --- 2. Đăng nhập bằng Facebook ---
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile'], // CHỈ ĐỊNH RÕ RÀNG CÁC QUYỀN
      );

      if (result.status == LoginStatus.success) {
        final AccessToken? accessToken = result.accessToken;

        if (accessToken != null) {
          final AuthCredential credential = FacebookAuthProvider.credential(accessToken.token);
          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          return userCredential.user;
        }
      } else if (result.status == LoginStatus.cancelled) {
        return null; // Người dùng hủy
      }
      return null;
    } catch (e) {
      _logError('Facebook', e);
      return null;
    }
  }

  // --- Hàm Đăng xuất chung ---
  Future<void> signOut() async {
    // Đăng xuất khỏi các nhà cung cấp bên thứ ba
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();

    // Đăng xuất khỏi Firebase
    await _auth.signOut();
  }
}