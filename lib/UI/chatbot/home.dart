import 'package:flutter/material.dart';
import 'package:applamdep/services/chatbot_service.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  bool _isLoading = false;

  // QUICK REPLY ICON + GRADIENT (Logic Unchanged)
  final List<Map<String, dynamic>> quickOptions = [
    {
      "icon": Icons.auto_awesome,
      "text": "Gợi ý mẫu nail đẹp",
      "colors": [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
    },
    {
      "icon": Icons.palette,
      "text": "Màu nail hợp với da?",
      "colors": [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
    },
    {
      "icon": Icons.trending_up,
      "text": "Trend nail 2025",
      "colors": [Color(0xFF89f7fe), Color(0xFF66a6ff)],
    },
    {
      "icon": Icons.work,
      "text": "Kiểu nail đi làm",
      "colors": [Color(0xFFFFE29F), Color(0xFFFF719A)],
    },
    {
      "icon": Icons.favorite,
      "text": "Phong cách nhẹ nhàng",
      "colors": [Color(0xFFfddb92), Color(0xFFd1fdff)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Extend body behind app bar for a premium feel
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.8),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa, color: const Color(0xFFF25278), size: 20),
            const SizedBox(width: 8),
            const Text(
              "Nail Assistant",
              style: TextStyle(
                color: Color(0xFFF25278),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        leading: const BackButton(color: Color(0xFFF25278)),
      ),
      body: Container(
        // Soft gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F5), // Lavender Blush
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ------------------ CHAT LIST ------------------
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    bool isUser = msg["role"] == "user";
                    return _buildChatBubble(msg["text"]!, isUser);
                  },
                ),
              ),

              // ------------------ LOADING INDICATOR ------------------
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF25278))
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Trợ lý đang nhập...",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      )
                    ],
                  ),
                ),

              // ------------------ QUICK OPTIONS ------------------
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: quickOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = quickOptions[index];
                    return _buildQuickReplyChip(item);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ------------------ INPUT AREA ------------------
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget: Chat Bubble
  Widget _buildChatBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // If AI, show a cute avatar
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFFFD1DC), // Soft Pink
                child: Icon(Icons.face_3, size: 18, color: Color(0xFFF25278)),
              ),
            ),

          // Message Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFF25278) : Colors.white,
                gradient: isUser
                    ? const LinearGradient(colors: [Color(0xFFF25278), Color(0xFFFF867A)])
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4, // Better line height for reading
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget: Quick Reply Chip
  Widget _buildQuickReplyChip(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => sendQuickMessage(item["text"]),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item["colors"].cast<Color>(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: (item["colors"][0] as Color).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(item["icon"], color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              item["text"],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Input Area
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
          ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Nhập câu hỏi về nail...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _isLoading ? null : sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF25278), Color(0xFFFF867A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF25278).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ LOGIC (UNCHANGED) ------------------
  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final msg = _controller.text;
    _controller.clear();
    setState(() {
      messages.add({"role": "user", "text": msg});
      _isLoading = true;
    });
    final aiResponse = await ChatbotService.sendMessage(msg);
    setState(() {
      messages.add({"role": "ai", "text": aiResponse});
      _isLoading = false;
    });
  }

  void sendQuickMessage(String msg) async {
    setState(() {
      messages.add({"role": "user", "text": msg});
      _isLoading = true;
    });
    final aiResponse = await ChatbotService.sendMessage(msg);
    setState(() {
      messages.add({"role": "ai", "text": aiResponse});
      _isLoading = false;
    });
  }
}