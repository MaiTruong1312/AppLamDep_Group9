import 'dart:async';
import 'package:flutter/material.dart';
import 'package:applamdep/main.dart';
import 'welcome_flow.dart'; // Import WelcomeFlow

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  @override
  void initState() {
    super.initState();
    // Bắt đầu bộ đếm thời gian khi widget được khởi tạo
    Timer(const Duration(seconds: 3), () {
      // Sau 3 giây, chuyển sang SplashScreen2
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeFlow()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Giả định kích thước màn hình thiết kế để tính toán tỷ lệ
    // Bạn có thể dùng MediaQuery để làm cho nó responsive hơn
    const double designWidth = 393;
    const double designHeight = 852;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double widthRatio = width / designWidth;
    double heightRatio = height / designHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Màu nền trắng xám
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder cho Logo
                Image.asset(
                  'assets/images/logo_placeholder.png',
                  width: 113 * widthRatio,
                  height: 147 * heightRatio,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 113 * widthRatio,
                      height: 147 * heightRatio,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 50 * widthRatio,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
