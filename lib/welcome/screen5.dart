import 'package:flutter/material.dart';

class SplashScreen5 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const SplashScreen5({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFE5398D); // Ước lượng màu

    return Scaffold(
      backgroundColor: primaryPink,
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
                    'assets/images/mockup_screen_5.png', // Thay bằng ảnh của bạn
                    width: MediaQuery.of(context).size.width * 0.85,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Center(
                          child: Text(
                            'Image Placeholder (Screen 5)',
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
                    'Application Of AI\nTechnology',
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
                    'Discover your beauty with AI technology. helping you optimize your beauty easily and conveniently',
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
                          'Finish', // Đổi chữ ở màn hình cuối
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
