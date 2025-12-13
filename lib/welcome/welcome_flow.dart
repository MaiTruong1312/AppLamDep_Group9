import 'package:flutter/material.dart';
import 'screen3.dart';
import 'screen4.dart';
import 'screen5.dart';
import '../UI/Login/mainlogin.dart'; // Import MainLoginScreen

class WelcomeFlow extends StatefulWidget {
  const WelcomeFlow({super.key});

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // Hàm điều hướng đến màn hình chính của ứng dụng
  void _goToMainLoginScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainLoginScreen()),
      );
    }
  }

  // Xử lý khi nhấn nút "Next" hoặc "Finish"
  void _onNextPressed() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      // This is the last page, go to the main screen
      _goToMainLoginScreen();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        // Sử dụng PageView để lướt qua các màn hình
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          SplashScreen3(onNext: _onNextPressed, onSkip: _goToMainLoginScreen),
          SplashScreen4(onNext: _onNextPressed, onSkip: _goToMainLoginScreen),
          SplashScreen5(onNext: _onNextPressed, onSkip: _goToMainLoginScreen),
        ],
      ),
    );
  }
}
