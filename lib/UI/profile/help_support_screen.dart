import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Danh sách các mục theo hình mẫu của bạn
    final List<String> supportItems = [
      "FAQ",
      "Contact Support",
      "Privacy Policy",
      "Terms of Service",
      "Partner",
      "Job Vacancy",
      "Accessibility",
      "Feedback",
      "About us",
      "Rate us",
      "Visit Our Website",
      "Follow us on Social Media",
    ];

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
          "Help & Support",
          style: TextStyle(
            color: Color(0xFF313235),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: supportItems.length,
        // Tạo đường kẻ mờ giữa các mục nếu cần, hoặc để trắng như hình
        separatorBuilder: (context, index) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(
              supportItems[index],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF313235),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right, // Icon mũi tên bên phải
              color: Color(0xFF313235),
              size: 20,
            ),
            onTap: () {
              // Xử lý khi nhấn vào từng mục
            },
          );
        },
      ),
    );
  }
}