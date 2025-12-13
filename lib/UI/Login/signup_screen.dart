// File: lib/UI/Login/signup_screen.dart (Phiên bản đã sửa cho OTP)

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/UI/Main/Home.dart';
import 'package:applamdep/UI/Login/signin_screen.dart';
import 'package:applamdep/UI/Login/otp_verification_screen.dart'; // Import màn hình OTP
import 'package:http/http.dart' as http; // Import thư viện HTTP
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Dùng cho defaultTargetPlatform

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ... (Giữ nguyên các Controllers, Keys, Biến trạng thái và Colors)
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color primaryPink = Color(0xFFF25278);
  static const Color buttonPink = Color(0xFFBB1549);
  static const Color textPrimary = Color(0xFF313235);
  static const Color textSecondary = Color(0xFF7B7D87);
  static const Color textHint = Color(0xFF9A9EA7);
  static const Color textFieldBg = Color(0xFFEEF0F1);
  static const Color socialButtonBorder = Color(0xFFE0E2E5);

  // Khởi tạo Base URL
  final String _baseUrl = defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000'
      : 'http://127.0.0.1:3000';


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  // ... (Giữ nguyên _inputDecoration)
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: textFieldBg,
      hintText: hintText,
      hintStyle: const TextStyle(color: textHint),
      prefixIcon: Icon(prefixIcon, color: textHint),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryPink, width: 1.5),
      ),
    );
  }

  // >>> SỬA ĐỔI CHÍNH: Gửi OTP thay vì tạo tài khoản ngay lập tức <<<
  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password and confirmation do not match.')),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to our Terms and Privacy Policy.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // 1. GỌI API GỬI OTP
    final url = Uri.parse('$_baseUrl/send-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}), // CHỈ CẦN GỬI EMAIL ĐỂ LẤY OTP
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // 2. NẾU GỬI OTP THÀNH CÔNG: Chuyển sang màn hình xác thực
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent! Please verify your email.')),
        );

        // CHUYỂN SANG MÀN HÌNH OTP VÀ TRUYỀN DỮ LIỆU ĐĂNG KÝ
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: email,
              // THÊM DỮ LIỆU ĐĂNG KÝ VÀO ĐÂY ĐỂ XỬ LÝ KHI XÁC THỰC THÀNH CÔNG
              registrationData: {
                'name': name,
                'password': password,
              },
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        // Xử lý lỗi nếu email đã được đăng ký (vì server của bạn kiểm tra Firebase)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email is already registered.')),
        );
      } else {
        // Xử lý các lỗi khác (500, lỗi server/Nodemailer)
        final errorBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: ${errorBody['message'] ?? 'Server error'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error or connection failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ... (Giữ nguyên _buildTermsAndCondition, _buildSignUpButton, _buildFooterText và Build method)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Header
                      const Text(
                        'Create an Account ✍️',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Register now to start your journey with us!",
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 1. Name Field
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hintText: 'Full Name',
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Invalid email address';
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icons.mail_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.next,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: textHint,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hintText: 'Confirm Password',
                          prefixIcon: Icons.lock_open_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: textHint,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Checkbox Terms and Conditions
                      _buildTermsAndCondition(),
                      const SizedBox(height: 24),

                      // Sign up Button
                      _buildSignUpButton(),
                      const SizedBox(height: 32),

                      // Footer: Already have an account
                      _buildFooterText(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for Checkbox and Terms
  Widget _buildTermsAndCondition() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24.0,
          width: 24.0,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (bool? newValue) {
              setState(() {
                _agreeToTerms = newValue ?? false;
              });
            },
            activeColor: primaryPink,
            side: const BorderSide(color: socialButtonBorder, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: primaryPink,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Open Terms of Service page
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: primaryPink,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Open Privacy Policy page
                      },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget for the Sign Up button
  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signUp,
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
        'Sign up',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
    );
  }

  // Widget for the footer text
  Widget _buildFooterText(BuildContext context) {
    return Center(
      child: RichText(
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
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Sign in',
              style: const TextStyle(
                color: primaryPink,
                fontWeight: FontWeight.w700,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Navigate to the Sign In screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}