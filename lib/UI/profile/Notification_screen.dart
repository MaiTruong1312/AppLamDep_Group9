import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Đảm bảo đã cài firebase_messaging

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 1. Danh sách đầy đủ tất cả các loại thông báo
  final List<String> _notificationKeys = [
    'New Rewards Alert',
    'Points Update',
    'Special Promotions',
    'Security Alerts',
    'Expiration Alerts',
    'Survey Opportunities',
    'Tier Progress',
    'Referral Bonuses',
    'Store Nearby Deals',
    'App Updates and News',
    'Birthday Rewards',
    'Location-Based Rewards',
  ];

  // Map lưu trạng thái thực tế
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  // 2. Khởi tạo và đọc dữ liệu từ máy
  Future<void> _initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, bool> tempSettings = {};

    for (String key in _notificationKeys) {
      // Mặc định là false nếu chưa từng cài đặt
      tempSettings[key] = prefs.getBool(key) ?? false;
    }

    if (mounted) {
      setState(() {
        _settings = tempSettings;
        _isLoading = false;
      });
    }
  }

  // 3. Logic xử lý khi gạt nút (Lưu máy + Firebase Topic)
  Future<void> _onToggleChanged(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();

    // Lưu vào máy
    await prefs.setBool(key, value);

    // Cập nhật giao diện
    setState(() {
      _settings[key] = value;
    });

    // --- LOGIC THỰC TẾ VỚI FIREBASE ---
    // Chuyển tên nút thành định dạng topic (ví dụ: "new_rewards_alert")
    String topicName = key.replaceAll(' ', '_').toLowerCase();

    try {
      if (value) {
        // Nếu bật: Đăng ký nhận thông báo cho chủ đề này
        await FirebaseMessaging.instance.subscribeToTopic(topicName);
        debugPrint('Subscribed to topic: $topicName');
      } else {
        // Nếu tắt: Hủy đăng ký
        await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
        debugPrint('Unsubscribed from topic: $topicName');
      }
    } catch (e) {
      debugPrint('Error with Firebase Topic: $e');
    }
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
          'Notification',
          style: TextStyle(
            color: Color(0xFF313235),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF25278)))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _notificationKeys.length,
        itemBuilder: (context, index) {
          String key = _notificationKeys[index];
          bool isEnabled = _settings[key] ?? false;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF313235),
                ),
              ),
              trailing: Switch(
                value: isEnabled,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFFF25278),
                onChanged: (bool value) => _onToggleChanged(key, value),
              ),
            ),
          );
        },
      ),
    );
  }
}