import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatProvider with ChangeNotifier {
  final ChatbotService _service = ChatbotService();
  List<ChatMessage> messages = [];
  bool isLoading = false;

  ChatProvider() {
    _service.init(); // Khởi tạo Gemini
  }

  Future<void> sendUserMessage(String text) async {
    // 1. Hiển thị tin nhắn người dùng ngay lập tức
    messages.add(ChatMessage(text: text, isUser: true));
    isLoading = true;
    notifyListeners();

    // 2. Gửi lên Gemini và chờ trả lời
    String reply = await _service.sendMessage(text);

    // 3. Hiển thị câu trả lời của AI
    messages.add(ChatMessage(text: reply, isUser: false));
    isLoading = false;
    notifyListeners();
  }
}