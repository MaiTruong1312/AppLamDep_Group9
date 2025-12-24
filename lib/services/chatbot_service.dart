// services/chatbot_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotService {
  // Nên giấu Key này vào biến môi trường (Env) khi production
  static const String _apiKey = "AIzaSyCpFGG_QOp2a1kp0Juy4Eob0CzprSTSodM";

  // SINGLETON INSTANCE
  static ChatbotService? _instance;
  late GenerativeModel _model;
  late ChatSession _chatSession;

  // PRIVATE CONSTRUCTOR
  ChatbotService._internal() {
    _initModel();
  }

  // SINGLETON GETTER
  static ChatbotService get instance {
    _instance ??= ChatbotService._internal();
    return _instance!;
  }

  // INITIALIZE MODEL
  void _initModel() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );

    // Bắt đầu phiên chat
    _chatSession = _model.startChat(
      history: [
        Content.text(
            'Bạn là trợ lý AI chuyên về làm móng, làm đẹp. '
                'Bạn có thể tư vấn về: '
                '- Màu sơn phù hợp với tông da '
                '- Kiểu nail theo xu hướng '
                '- Chăm sóc móng '
                '- Đặt lịch làm nail '
                'Hãy trả lời thân thiện và chuyên nghiệp.'),
      ],
    );
  }

  // INSTANCE METHOD
  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(userMessage));
      return response.text ?? "Xin lỗi, tôi không hiểu ý bạn.";
    } catch (e) {
      return "Lỗi kết nối AI: $e";
    }
  }

  // STATIC HELPER METHOD (Để gọi dễ dàng từ bất kỳ đâu)
  static Future<String> send(String message) async {
    return await instance.sendMessage(message);
  }
}