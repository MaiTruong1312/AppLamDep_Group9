import 'package:flutter/material.dart';

class SplashScreen4 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const SplashScreen4({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFE5398D); // Ước lượng màu

    return Scaffold(
      backgroundColor: primaryPink, // Nền hồng cho phần trên
      body: Column(
        children: [
          Expanded(
            flex: 5, // Tỷ lệ cho phần ảnh
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Placeholder cho hình ảnh mockup app
                Positioned(
                  top: 100, // Điều chỉnh vị trí
                  child: Image.asset(
                    'assets/images/mockup_screen_4.png', // Thay bằng ảnh của bạn
                    width: MediaQuery.of(context).size.width * 0.85,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Center(
                          child: Text(
                            'Image Placeholder (Screen 4)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4, // Tỷ lệ cho phần nội dung trắng
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Tiêu đề
                  const Text(
                    'Collection, Enjoy\nBeauty Art',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mô tả
                  const Text(
                    'Discover and collect your favorites, and more. Enhance your beauty with every move. Start exploring, start enjoying!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Nút Skip và Next
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: onSkip, // Sử dụng callback
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onNext, // Sử dụng callback
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
