import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/UI/profile/change_password_screen.dart';
import 'package:applamdep/UI/profile/device_management_screen.dart';
import 'package:applamdep/UI/Login/signin_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({Key? key}) : super(key: key);

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  // Trạng thái các nút gạt
  bool biometricId = false; // Vân tay
  bool faceId = false;      // Face ID
  bool smsAuth = false;
  bool googleAuth = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Tải trạng thái riêng biệt cho từng loại từ bộ nhớ
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      biometricId = prefs.getBool('use_fingerprint') ?? false;
      faceId = prefs.getBool('use_faceid') ?? false;
    });
  }

  // --- LOGIC SINH TRẮC HỌC THẬT ---
  Future<void> _toggleBiometric(bool value, String type) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      bool canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) {
        _showErrorSnackBar("This device does not support this method.");
        return;
      }

      try {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Authenticate to enable login using ${type == 'face' ? 'Face ID' : 'fingerprint'}}',
          options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
        );

        if (didAuthenticate) {
          if (type == 'fingerprint') {
            await prefs.setBool('use_fingerprint', true);
            setState(() => biometricId = true);
          } else {
            await prefs.setBool('use_faceid', true);
            setState(() => faceId = true);
          }
        }
      } catch (e) {
        _showErrorSnackBar("Authentication error: $e");
      }
    } else {
      if (type == 'fingerprint') {
        await prefs.setBool('use_fingerprint', false);
        setState(() => biometricId = false);
      } else {
        await prefs.setBool('use_faceid', false);
        setState(() => faceId = false);
      }

      // Nếu tắt cả hai thì xóa pass đã lưu trong két sắt
      if (!(prefs.getBool('use_fingerprint') ?? false) && !(prefs.getBool('use_faceid') ?? false)) {
        await _storage.delete(key: 'user_password');
      }
    }
  }

  // --- LOGIC XÓA TÀI KHOẢN ---
  Future<void> _handleDeleteAccount() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Account"),
        content: const Text("This action will permanently delete your account. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SignInScreen()), (route) => false);
        }
      } on FirebaseAuthException catch (e) {
        _showErrorSnackBar(e.message ?? "An error occurred.");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
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
        title: const Text("Account & Security", style: TextStyle(color: Color(0xFF313235), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Phần 1: Các nút gạt
          _buildToggleItem("Biometric ID ", biometricId, (v) => _toggleBiometric(v, 'fingerprint')),
          _buildToggleItem("Face ID", faceId, (v) => _toggleBiometric(v, 'face')),
          _buildToggleItem("SMS Authenticator", smsAuth, (v) => setState(() => smsAuth = v)),
          _buildToggleItem("Google Authenticator", googleAuth, (v) => setState(() => googleAuth = v)),

          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 1, color: Color(0xFFF1F1F1))),

          // Phần 2: Điều hướng
          _buildNavItem(
              "Change Password",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()))
          ),

          _buildNavItem(
              "Device Management",
              subtitle: "Manage logged-in devices.",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DeviceManagementScreen()))
          ),

          _buildNavItem(
              "Delete Account",
              isDestructive: true,
              subtitle: "Permanently delete your account data.",
              onTap: _handleDeleteAccount
          ),

          const SizedBox(height: 30),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildToggleItem(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF313235))),
      value: value,
      activeColor: const Color(0xFFF25278),
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildNavItem(String title, {String? subtitle, bool isDestructive = false, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      onTap: onTap,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: isDestructive ? const Color(0xFFF25278) : const Color(0xFF313235))),
      subtitle: subtitle != null ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 14))) : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
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