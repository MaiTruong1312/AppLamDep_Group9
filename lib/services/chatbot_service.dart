import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ChatbotService {
  // ⚠️ Lưu ý: Bạn nên vào aistudio.google.com tạo Key mới vì Key cũ đã lộ.
  static const String GEMINI_API_KEY = "AIzaSyDuGcCQhgSqwC3ITE7mec4NID5PAKlHkCY";

  static Future<String> sendMessage(String message) async {
    // ✅ URL chuẩn theo tài liệu Google (Model 1.5 Flash)
    final String url =
        "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$GEMINI_API_KEY";

    log("Calling URL: $url"); // In ra để debug

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": message}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"] ?? "Không có nội dung.";
      } else {
        log("Lỗi API: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 404) return "Lỗi 404: Sai tên Model hoặc URL.";
        if (response.statusCode == 429) return "Lỗi 429: Server bận, thử lại sau.";
        return "Lỗi (${response.statusCode}): Vui lòng kiểm tra lại Key.";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}