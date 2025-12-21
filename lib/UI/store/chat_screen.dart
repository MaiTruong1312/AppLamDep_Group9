import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ChatScreen extends StatefulWidget {
  final String storeName;
  const ChatScreen({super.key, required this.storeName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String? _userName = FirebaseAuth.instance.currentUser?.displayName?.split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.neutral950),
        title: Text("New Message", style: AppTypography.labelLG.copyWith(color: AppColors.neutral950)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildBotGreeting(),
                const SizedBox(height: 100), // Khoảng trống tạo cảm giác thoáng đạt
                _buildQuickActions(),
              ],
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  // 1. Lời chào tự động kèm tên người dùng
  Widget _buildBotGreeting() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Text(
            "Hi ${_userName ?? 'there'}! Can we help you?",
            style: AppTypography.textSM.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // 2. Các nút phản hồi nhanh
  Widget _buildQuickActions() {
    return Column(
      children: [
        const Text("Click to send", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        _actionButton("Book Now"),
        _actionButton("I need to see a consultant"),
        _actionButton("Learn more about the service"),
      ],
    );
  }

  Widget _actionButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(text, style: AppTypography.textSM.copyWith(color: Colors.black87)),
      ),
    );
  }

  // 3. Thanh nhập liệu tích hợp đa phương tiện
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          _inputIcon(Icons.camera_alt, AppColors.primary, isCircular: true),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Chat...",
                hintStyle: const TextStyle(color: AppColors.neutral500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          _inputIcon(Icons.mic_none, AppColors.neutral950),
          _inputIcon(Icons.image_outlined, AppColors.neutral950),
          _inputIcon(Icons.sentiment_satisfied_alt_outlined, AppColors.neutral950),
          _inputIcon(Icons.add_circle_outline, AppColors.neutral950),
        ],
      ),
    );
  }

  Widget _inputIcon(IconData icon, Color color, {bool isCircular = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: isCircular
          ? Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      )
          : Icon(icon, color: color, size: 24),
    );
  }
}