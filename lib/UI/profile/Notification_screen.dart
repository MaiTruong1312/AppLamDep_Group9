import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Map lưu trữ trạng thái của các nút gạt (Switch)
  final Map<String, bool> _settings = {
    'New Rewards Alert': true,
    'Points Update': false,
    'Special Promotions': true,
    'Security Alerts': true,
    'Expiration Alerts': true,
    'Survey Opportunities': true,
    'Tier Progress': false,
    'Referral Bonuses': false,
    'Store Nearby Deals': true,
    'App Updates and News': false,
    'Birthday Rewards': false,
    'Location-Based Rewards': false,
  };

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _settings.keys.map((String key) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF313235),
                  ),
                ),
                Switch(
                  value: _settings[key]!,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFFF25278), // Màu hồng khi bật
                  onChanged: (bool value) {
                    setState(() {
                      _settings[key] = value;
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}