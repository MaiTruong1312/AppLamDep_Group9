import 'package:flutter/material.dart';

class LinkedAppearanceScreen extends StatelessWidget {
  const LinkedAppearanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF313235)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Linked Accounts",
          style: TextStyle(
            color: Color(0xFF313235),
            fontWeight: FontWeight.bold,
            fontSize: 20, // Tăng kích thước tiêu đề cho to rõ
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Column(
          children: [
            // Google: Đã liên kết -> Chữ màu xám
            _buildLinkedItem(
              imagePath: 'assets/images/google_icon.png',
              name: 'Google',
              isApplied: true,
            ),
            const SizedBox(height: 16), // Tăng khoảng cách giữa các ô
            // Apple: Đã liên kết -> Chữ màu xám
            _buildLinkedItem(
              imagePath: 'assets/images/apple_icon.png',
              name: 'Apple',
              isApplied: true,
            ),
            const SizedBox(height: 16),
            // Facebook: Chưa liên kết -> Chữ màu hồng
            _buildLinkedItem(
              imagePath: 'assets/images/facebook_icon.png',
              name: 'Facebook',
              isApplied: false,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLinkedItem({
    required String imagePath,
    required String name,
    required bool isApplied,
  }) {
    return Container(
      // Tăng padding để ô trông to và thoáng hơn
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Bo góc lớn hơn cho hiện đại
        border: Border.all(color: Colors.grey.shade200, width: 1.5), // Viền rõ hơn chút
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 35, // Tăng kích thước logo
            height: 35,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.link, size: 35, color: Colors.grey),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 18, // Tăng kích cỡ chữ tên thương hiệu
                fontWeight: FontWeight.bold,
                color: Color(0xFF313235),
              ),
            ),
          ),
          Text(
            'Connect',
            style: TextStyle(
              fontSize: 16, // Tăng kích cỡ chữ Connect
              fontWeight: FontWeight.w700,
              // Logic màu sắc: Đã áp dụng (true) -> Xám, Chưa áp dụng (false) -> Hồng
              color: isApplied ? const Color(0xFFB0B2B5) : const Color(0xFFF25278),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 4,
      selectedItemColor: const Color(0xFFF25278),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.collections_outlined), label: 'Collection'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Booking'),
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Discover'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}