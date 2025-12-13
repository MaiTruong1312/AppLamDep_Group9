import 'dart:convert';
import 'dart:developer'; // Để in log lỗi
import 'package:http/http.dart' as http;

class ChatbotService {
  // 1. Dán API Key của bạn vào đây
  static const String apiKey = "AIzaSyCln088hs9KVsUP1xIZfDEnM3TampeS6X4";

  static Future<String> sendMessage(String message) async {
    // 2. Dùng Model Gemini 2.0 Flash (Bản Experimental mới nhất)
    // Lưu ý: Tên đúng của nó là "gemini-2.0-flash-exp"
    final String url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": message}
              ]
            }
          ]
        }),
      );

      // In log để kiểm tra nếu có lỗi
      log("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"] ?? "AI đang suy nghĩ...";
      } else {
        log("Lỗi Body: ${response.body}");

        // Nếu bản 2.0 bị lỗi (do chưa ổn định), hãy gợi ý người dùng về bản 1.5
        if (response.statusCode == 404) {
          return "Lỗi: Không tìm thấy model 2.0. Bạn hãy thử đổi lại thành 'gemini-1.5-flash' trong code nhé.";
        }
        return "Lỗi API (${response.statusCode}): Vui lòng kiểm tra lại Key.";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}