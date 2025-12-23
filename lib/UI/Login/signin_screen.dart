import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/UI/main_layout.dart';
import 'package:applamdep/UI/Login/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import AuthService của bạn (Cần đảm bảo đường dẫn này là chính xác)
import 'package:applamdep/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  // Key để lưu trữ email
  static const String _rememberMeKey = 'rememberedEmail';

  // Khởi tạo AuthService
  final AuthService _authService = AuthService();

  // Trạng thái cho checkbox và ẩn/hiện mật khẩu
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  // Controllers cho các ô text
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Màu sắc từ thiết kế
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color primaryPink = Color(0xFFF25278); // Màu "Forgot Password"
  static const Color buttonPink = Color(0xFFC72C41); // Ước lượng màu nút "Sign in"
  static const Color textPrimary = Color(0xFF313235);
  static const Color textSecondary = Color(0xFF7B7D87);
  static const Color textHint = Color(0xFF9A9EA7);
  static const Color textFieldBg = Color(0xFFF5F5F5);
  static const Color textFieldBorder = Color(0xFFE0E2E5);
  static const Color separatorText = Color(0xFF616161);
  static const Color separatorLine = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    // (Giữ nguyên logic initState nếu có)
  }

  @override
  void dispose() {
    // Giải phóng controllers khi widget bị huỷ
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC ĐĂNG NHẬP BẰNG EMAIL/MẬT KHẨU ---
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Kiểm tra đầu vào
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter your email and password.');
      return;
    }

    try {
      // 2. Thực hiện đăng nhập Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // 3. Ghi lại thông tin thiết bị để phục vụ "Device Management"
        await _recordDeviceSession(user);

        // 4. Lưu trạng thái đăng nhập vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (_rememberMe) {
          await prefs.setString(_rememberMeKey, email);
        } else {
          await prefs.remove(_rememberMeKey);
        }

        // 5. Điều hướng đến MainLayout
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainLayout()),
                (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // 6. Xử lý các lỗi cụ thể từ Firebase
      String message = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      // 7. Các lỗi không mong muốn khác
      _showErrorSnackBar('An unexpected error occurred: $e');
    }
  }
  Future<void> _authenticateWithBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    bool isBiometricEnabled = prefs.getBool('use_biometric') ?? false;

    if (!isBiometricEnabled) {
      _showErrorSnackBar('Biometric login is not enabled. Please enable it in Settings.');
      return;
    }

    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to sign in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        String? savedEmail = await _secureStorage.read(key: 'user_email');
        String? savedPassword = await _secureStorage.read(key: 'user_password');

        if (savedEmail != null && savedPassword != null) {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _signIn(); // Gọi hàm đăng nhập
        } else {
          _showErrorSnackBar('No saved credentials found. Please sign in manually once.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Biometric authentication failed: $e');
    }
  }
  Future<void> _recordDeviceSession(User user) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = "Unknown Device";
    String os = Platform.isAndroid ? "Android" : "iOS";

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = "${androidInfo.manufacturer} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }

      // Lưu vào Firestore: users -> {uid} -> sessions -> {tên_máy}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(deviceName.replaceAll(' ', '_')) // Dùng tên máy làm ID
          .set({
        'deviceName': deviceName,
        'os': os,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Sử dụng merge để chỉ cập nhật thời gian nếu thiết bị đã tồn tại
    } catch (e) {
      debugPrint("Error recording device: $e");
    }
  }
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  // --- KẾT THÚC LOGIC ĐĂNG NHẬP EMAIL ---


  // --- LOGIC XỬ LÝ ĐĂNG NHẬP BẰNG BÊN THỨ BA (SOCIAL SIGN-IN) ---
  void _socialSignInHandler(Future<User?> signInFuture) async {
    // Thêm logic hiển thị loading nếu cần

    final user = await signInFuture;

    // Ẩn loading nếu có

    if (user != null) {
      // Lưu trạng thái đăng nhập
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true); // <-- LƯU TRẠNG THÁI

      // Đăng nhập thành công, điều hướng đến màn hình chính
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainLayout()),
              (Route<dynamic> route) => false,
        );
      }
    } else {
      // Đăng nhập thất bại (hoặc bị hủy)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed or cancelled.')),
        );
      }
    }
  }
  // --- KẾT THÚC LOGIC XỬ LÝ SOCIAL SIGN-IN ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back! 👋',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 28,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 1.21,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your next nail appointment is just a tap away',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 2. Form Fields
                        _buildTextFieldGroup(
                          label: 'Email',
                          controller: _emailController,
                          hintText: 'Email',
                          icon: Icons.mail_outline,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                        ),
                        const SizedBox(height: 24),
                        _buildTextFieldGroup(
                          label: 'Password',
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          autofillHints: const [AutofillHints.password],
                        ),
                        const SizedBox(height: 20),

                        _buildRememberForgotRow(),
                        const SizedBox(height: 28),
                        _buildOrSeparator(),
                        const SizedBox(height: 28),

                        // Nút GOOGLE (Đã sửa onPressed)
                        _buildSocialButton(
                          text: 'Continue with Google',
                          iconPath: 'assets/images/google_icon.png',
                          onPressed: () {
                            _socialSignInHandler(_authService.signInWithGoogle());
                          },
                        ),

                        const SizedBox(height: 20),

                        // Nút FACEBOOK (Đã sửa onPressed)
                        _buildSocialButton(
                          text: 'Continue with Facebook',
                          iconPath: 'assets/images/facebook_icon.png',
                          onPressed: () {
                            _socialSignInHandler(_authService.signInWithFacebook());
                          },
                        ),

                        // Đã loại bỏ nút Continue with Apple và Continue with X

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 6. Nút Sign in (đặt cố định ở dưới)
            _buildSignInButton(),
          ],
        ),
      ),
    );
  }

  // Widget cho các trường nhập liệu
  Widget _buildTextFieldGroup({
    required String label,
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    bool isPassword = false,
    Iterable<String>? autofillHints,
  }) {
    final TextInputAction inputAction = isPassword
        ? TextInputAction.done
        : TextInputAction.next;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,

          autofillHints: autofillHints,
          keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
          textInputAction: inputAction,
          onFieldSubmitted: (value) {
            if (isPassword) {
              _signIn();
            }
          },

          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: textHint,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: icon != null ? Icon(icon, color: textHint) : null,
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: textHint,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: textFieldBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: textFieldBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryPink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // Widget cho "Remember me" và "Forgot Password?"
  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (bool? value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              activeColor: primaryPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: const BorderSide(color: textHint, width: 2),
            ),
            const Text(
              'Remember me',
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // Forgot Password
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return const ForgotPasswordScreen();
                },
              ),
            );
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: primaryPink,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Widget cho dải phân cách "or"
  Widget _buildOrSeparator() {
    return Row(
      children: const [
        Expanded(child: Divider(color: separatorLine, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'or',
            style: TextStyle(
              color: separatorText,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
        ),
        Expanded(child: Divider(color: separatorLine, thickness: 1)),
      ],
    );
  }

  // Widget cho các nút đăng nhập xã hội
  Widget _buildSocialButton({
    required String text,
    required String iconPath,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
          side: const BorderSide(color: textFieldBorder, width: 1),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.login, size: 24);
            },
          ),
          const SizedBox(width: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // Nút "Sign in" ở cuối trang
  Widget _buildSignInButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(color: backgroundColor),
      child: Row(
        children: [
          // Nút Sign In chính
          Expanded(
            child: ElevatedButton(
              onPressed: _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonPink,
                padding: const EdgeInsets.all(18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              ),
              child: const Text(
                'Sign in',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nút Biometric ID
          InkWell(
            onTap: _authenticateWithBiometrics,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: textFieldBorder),
              ),
              child: const Icon(Icons.fingerprint, color: primaryPink, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
