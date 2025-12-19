import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkedAppearanceScreen extends StatefulWidget {
  const LinkedAppearanceScreen({Key? key}) : super(key: key);

  @override
  State<LinkedAppearanceScreen> createState() => _LinkedAppearanceScreenState();
}

// Sử dụng WidgetsBindingObserver để biết khi nào bạn từ trình duyệt quay lại App
class _LinkedAppearanceScreenState extends State<LinkedAppearanceScreen> with WidgetsBindingObserver {
  // Trạng thái: Google mặc định true (Gmail), Apple/Facebook mặc định false
  final Map<String, bool> _linkedStatus = {
    'Google': true,
    'Apple': false,
    'Facebook': false,
  };

  bool _isWaitingForReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Đăng ký theo dõi trạng thái App
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Hủy theo dõi khi thoát trang
    super.dispose();
  }

  // Tự động chạy khi bạn quay lại App từ trình duyệt Facebook
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForReturn) {
      _isWaitingForReturn = false; // Tắt chế độ chờ
      _showConfirmDialog("Facebook"); // Hiện ngay câu hỏi xác nhận
    }
  }

  // Hàm mở Facebook thật (Trình duyệt máy)
  Future<void> _launchFacebook() async {
    final Uri url = Uri.parse("https://m.facebook.com");
    try {
      _isWaitingForReturn = true; // Đánh dấu là đang đợi người dùng quay lại
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _isWaitingForReturn = false;
      _showSnackBar("Could not open Facebook", false);
    }
  }

  // Hộp thoại hỏi: Would you like to link?
  Future<void> _showConfirmDialog(String name) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Đợi UI mượt mà
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Link"),
        content: Text("Would you like to link your $name account?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar("Link failed", false); // Giữ nguyên màu hồng
            },
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _linkedStatus[name] = true); // Chuyển sang màu nhạt + hiện 3 chấm
              _showSnackBar("Successful!", true); // Báo thành công
            },
            child: const Text("Yes", style: TextStyle(color: Color(0xFFF25278), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

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
          style: TextStyle(color: Color(0xFF313235), fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Column(
          children: [
            _buildLinkedItem('assets/images/google_icon.png', 'Google'),
            const SizedBox(height: 16),
            _buildLinkedItem('assets/images/apple_icon.png', 'Apple'),
            const SizedBox(height: 16),
            _buildLinkedItem('assets/images/facebook_icon.png', 'Facebook'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(), // Đã thêm lại thanh Bottom Nav cho bạn
    );
  }

  Widget _buildLinkedItem(String imagePath, String name) {
    bool isLinked = _linkedStatus[name] ?? false;
    bool isGoogle = name == 'Google';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Image.asset(imagePath, width: 35, height: 35,
              errorBuilder: (c, e, s) => const Icon(Icons.link, size: 35, color: Colors.grey)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          if (!isLinked)
            GestureDetector(
              onTap: () => name == 'Facebook' ? _launchFacebook() : setState(() => _linkedStatus[name] = true),
              child: const Text(
                'Connect',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF25278)),
              ),
            )
          else
            Row(
              children: [
                const Text(
                  'Connected',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFB0B2B5)),
                ),
                if (!isGoogle)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Color(0xFFB0B2B5)),
                    onSelected: (v) => setState(() => _linkedStatus[name] = false),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'd', child: Text('Disconnect', style: TextStyle(color: Colors.red))),
                    ],
                  )
                else
                  const SizedBox(width: 48),
              ],
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