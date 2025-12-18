import 'package:flutter/material.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({Key? key}) : super(key: key);

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  // Trạng thái các nút gạt theo hình mẫu
  bool biometricId = false;
  bool faceId = false;
  bool smsAuth = false;
  bool googleAuth = false;

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
          "Account & Security",
          style: TextStyle(color: Color(0xFF313235), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildToggleItem("Biometric ID", biometricId, (v) => setState(() => biometricId = v)),
          _buildToggleItem("Face ID", faceId, (v) => setState(() => faceId = v)),
          _buildToggleItem("SMS Authenticator", smsAuth, (v) => setState(() => smsAuth = v)),
          _buildToggleItem("Google Authenticator", googleAuth, (v) => setState(() => googleAuth = v)),
          const Divider(height: 32),
          _buildNavItem("Change Password"),
          _buildNavItem("Device Management", subtitle: "Manage your account on the various devices you own."),
          _buildNavItem("Deactivate Account", subtitle: "Temporarily deactivate your account. Easily reactivate when you're ready."),
          _buildNavItem("Delete Account", isDestructive: true, subtitle: "Permanently remove your account and data. Proceed with caution."),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF313235))),
      value: value,
      activeTrackColor: const Color(0xFFF25278), // Màu hồng chủ đạo
      activeColor: Colors.white,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildNavItem(String title, {String? subtitle, bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: isDestructive ? const Color(0xFFF25278) : const Color(0xFF313235), // Màu hồng cho nút xóa
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF54565B),
            fontSize: 16,
          ),
        ),
      )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Thêm logic điều hướng cho từng mục ở đây
      },
    );
  }
}