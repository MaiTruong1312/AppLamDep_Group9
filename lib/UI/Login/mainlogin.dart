import 'package:flutter/material.dart';
import 'package:applamdep/UI/Login/signin_screen.dart';
import 'package:applamdep/UI/Login/signup_screen.dart';

class MainLoginScreen extends StatelessWidget {
  const MainLoginScreen({super.key});

  // Định nghĩa màu sắc để dễ dàng tái sử dụng
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color primaryPink = Color(0xFFF25278); // Màu "Sign up"
  static const Color secondaryPink = Color(0xFFFFE4E8); // Màu "Sign in"
  static const Color textPrimary = Color(0xFF313235);
  static const Color textSecondary = Color(0xFF7B7D87);
  static const Color textButtonPink = Color(0xFFBB1549);
  static const Color borderColor = Color(0xFFE0E2E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          // Thêm padding cho toàn bộ màn hình
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2), // Đẩy nội dung xuống
              // 1. Logo (Placeholder)
              Image.asset(
                'assets/images/logo_placeholder.png', // Thay thế bằng đường dẫn logo của bạn
                height: 80,
                width: 62,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    width: 62,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: textSecondary,
                      size: 60,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 2. Tiêu đề
              const Text(
                'Let\'s Get Started!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 28,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 8),

              // 3. Tiêu đề phụ
              const Text(
                'Let\'s dive in into your account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
              const SizedBox(height: 40),

              // 4. Các nút Đăng nhập xã hội
              _buildSocialButton(
                text: 'Continue with Google',
                iconPath: 'assets/images/google_icon.png',
                onPressed: () {
                  // TODO: Xử lý đăng nhập Google
                },
              ),
              const SizedBox(height: 20),
              _buildSocialButton(
                text: 'Continue with Facebook',
                iconPath: 'assets/images/facebook_icon.png',
                onPressed: () {},
              ),
              const SizedBox(height: 40),

              // 5. Nút Sign up
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: const Text(
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
              ),
              const SizedBox(height: 16),

              // 6. Nút Sign in
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryPink,
                  foregroundColor: textButtonPink,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 0, // Không có đổ bóng
                ),
                child: const Text(
                  'Sign in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textButtonPink,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),

              const Spacer(flex: 3), // Đẩy text cuối trang xuống
              // 7. Privacy & Terms
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      /* TODO: Mở Privacy Policy */
                    },
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.14,
                      ),
                    ),
                  ),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFF65686E),
                      fontSize: 14,
                      fontFamily: 'Urbanist', // Lưu ý: font này khác 'Inter'
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      /* TODO: Mở Terms of Service */
                    },
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Đệm cho thanh home
            ],
          ),
        ),
      ),
    );
  }

  // Widget Tái sử dụng cho các nút đăng nhập xã hội
  Widget _buildSocialButton({
    required String text,
    required String iconPath,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        elevation: 0, // Không đổ bóng
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon (Placeholder)
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.login, size: 24); // Icon dự phòng
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
}
