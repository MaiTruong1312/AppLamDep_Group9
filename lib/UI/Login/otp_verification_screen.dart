// File: lib/UI/Login/otp_verification_screen.dart (Phiên bản đã sửa cho Đăng ký)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:applamdep/UI/Login/reset_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:applamdep/UI/Login/signin_screen.dart'; // Import Sign In Screen

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, String>? registrationData; // Dữ liệu đăng ký mới (name, password)

  // Sửa constructor để nhận registrationData (là null nếu gọi từ Quên mật khẩu)
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.registrationData,
  });

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // ... (Giữ nguyên các Controllers, FocusNode, Biến trạng thái và Colors)
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  String _otp = "";

  Timer? _timer;
  int _countdown = 56;
  bool _canResend = false;
  bool _isLoading = false;

  // Màu sắc
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF313235);
  static const Color textSecondary = Color(0xFF7B7D87);
  static const Color primaryPink = Color(0xFFF25278);
  static const Color countdownColor = Color(0xFFF25278);
  static const Color buttonPink = Color(0xFFC72C41);

  // Khởi tạo Base URL
  final String _baseUrl = defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000'
      : 'http://127.0.0.1:3000';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTimer();
      FocusScope.of(context).requestFocus(_focusNode);
    });
    _otpController.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    setState(() {
      _otp = _otpController.text;
    });
    // Kích hoạt xác thực khi đã đủ 6 ký tự
    if (_otp.length == 6 && !_isLoading) {
      _verifyOtp(_otp);
    }
  }

  void startTimer() {
    _timer?.cancel();
    _canResend = false;
    _countdown = 56;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  void _showLoadingDialog() {
    if (!mounted) return; // Bảo vệ showDialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryPink),
                SizedBox(height: 20),
                Text(
                  'Processing...',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ... (Giữ nguyên _resendCode)

  // Gửi lại code (Resend Code)
  void _resendCode() async {
    if (!_canResend) return;
    if (!mounted) return; // Bảo vệ khỏi lỗi FocusNode/setState

    setState(() {
      _isLoading = true;
      _canResend = false;
    });

    // Reset UI và khởi động lại timer trước khi gọi API
    startTimer();

    final url = Uri.parse('$_baseUrl/send-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      );

      if (!mounted) return; // Kiểm tra mounted sau await

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP code has been resent!')),
        );
      } else {
        final errorBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: ${errorBody['message'] ?? 'Error resending'}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // HÀM MỚI: TẠO TÀI KHOẢN FIREBASE SAU KHI XÁC THỰC OTP
  Future<void> _createAccountAndNavigate(String email, String password, String name) async {
    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
      }

      // Xử lý thành công: Thông báo và chuyển về màn hình Đăng nhập
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please log in.')),
      );

      // Chuyển đến màn hình Đăng nhập và xóa tất cả stack trước đó
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
            (Route<dynamic> route) => false,
      );

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password is too weak (must be at least 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else {
        message = 'Registration failed. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred during registration: $e')),
      );
    }
  }


  // Xác thực OTP (Logic đã được sửa)
  void _verifyOtp(String otp) async {
    try {
      _focusNode.unfocus();
    } catch (e) {
      debugPrint('Error during unfocus: $e');
    }

    setState(() {
      _isLoading = true;
    });

    _showLoadingDialog();

    final url = Uri.parse('$_baseUrl/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email, 'otp': otp}),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Tắt dialog

      if (response.statusCode == 200) {
        // --- XỬ LÝ THÀNH CÔNG ---

        // 1. Nếu đang ở chế độ Đăng ký (registrationData có dữ liệu)
        if (widget.registrationData != null) {
          final name = widget.registrationData!['name']!;
          final password = widget.registrationData!['password']!;

          // Gọi hàm tạo tài khoản và chuyển hướng (Xử lý toàn bộ trong hàm mới)
          await _createAccountAndNavigate(widget.email, password, name);

        }
        // 2. Nếu đang ở chế độ Quên mật khẩu
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP verified successfully!')),
          );
          // Điều hướng đến màn hình ResetPasswordScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: widget.email, otp: otp),
            ),
          );
        }
      } else {
        // Xử lý thất bại
        _otpController.clear();
        final errorBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${errorBody['message'] ?? 'Invalid OTP'}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      try {
        Navigator.of(context).pop();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ... (Giữ nguyên các Widget helper và Build method)

  Widget _buildOtpInput() {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOtpBox(0),
              _buildOtpBox(1),
              _buildOtpBox(2),
              _buildOtpBox(3),
              _buildOtpBox(4),
              _buildOtpBox(5),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: TextField(
              controller: _otpController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Colors.transparent,
                fontSize: 0,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                filled: true,
                fillColor: Colors.transparent,
              ),
              cursorColor: Colors.transparent,
              enableSuggestions: false,
              autocorrect: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final char = index < _otp.length ? _otp[index] : '';
    final hasFocus = index == _otpController.text.length && _focusNode.hasFocus;
    final textFieldBg = const Color(0xFFEEF0F1);
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: textFieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFocus ? primaryPink : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildResendText() {
    return Center(
      child: _canResend
          ? TextButton(
        onPressed: _isLoading ? null : _resendCode,
        child: const Text(
          'Resend code',
          style: TextStyle(
            color: primaryPink,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      )
          : RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: textSecondary,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'You can resend the code in '),
            TextSpan(
              text: '$_countdown seconds',
              style: const TextStyle(
                color: countdownColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    bool isOtpComplete = _otp.length == 6;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(color: backgroundColor),
      child: ElevatedButton(
        onPressed: (_isLoading || !isOtpComplete) ? null : () => _verifyOtp(_otp),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonPink,
          disabledBackgroundColor: buttonPink.withOpacity(0.5),
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : const Text(
          'Verify',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }


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
            // Tắt timer khi quay lại màn hình trước
            _timer?.cancel();
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // 1. Header
                      const Text(
                        'OTP Verification',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          height: 1.21,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 2. Subtitle
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                          children: [
                            TextSpan(
                              text: widget.registrationData != null ?
                              'Please check your email inbox to verify your new account. The code was sent to ' :
                              'Please check your email inbox for a message from Pionails. Enter the one-time verification code sent to ',
                            ),
                            TextSpan(
                              text: widget.email, // Hiển thị email người dùng
                              style: const TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3. Ô nhập OTP (và TextField ẩn)
                      _buildOtpInput(),

                      const SizedBox(height: 32),
                      // 4. Đếm ngược
                      _buildResendText(),
                    ],
                  ),
                ),
              ),
            ),
            // Nút Verify
            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }
}