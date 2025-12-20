// chatbot_page_v2.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:applamdep/services/chatbot_service.dart';
import 'package:applamdep/services/firebase_chat_history_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:applamdep/services/image_analysis_service.dart';

class ChatBotPageV2 extends StatefulWidget {
  const ChatBotPageV2({super.key});

  @override
  State<ChatBotPageV2> createState() => _ChatBotPageV2State();
}

class _ChatBotPageV2State extends State<ChatBotPageV2>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;
  bool _isRecordingVoice = false;
  bool _isAnalyzingImage = false;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  late AnimationController _voiceAnimationController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _chatsStreamSubscription;
  List<Map<String, dynamic>> _chatHistoryList = [];
  bool _isLoadingHistory = false;
  String? _currentChatId;
  // User preferences & memory
  Map<String, dynamic> _userProfile = {
    'name': 'Khách',
    'skinTone': 'warm_medium',
    'nailLength': 'medium',
    'preferredStyles': ['minimal', 'elegant'],
    'budget': 'medium',
    'savedDesigns': [],
    'bookingHistory': [],
  };

  // AI Personality states
  final List<String> _aiPersonalities = ['friendly', 'professional', 'creative'];
  String _currentPersonality = 'friendly';

  // Image Analysis states
  XFile? _selectedImage;
  Map<String, dynamic>? _imageAnalysisResult;

  // Voice recording
  Timer? _voiceRecordingTimer;
  int _voiceRecordingSeconds = 0;

  // Quick Replies với AI-suggested options
  List<Map<String, dynamic>> _quickOptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initAnimations();
    _loadUserProfile();
    _loadQuickOptions();
    _addWelcomeMessage();

    // Auto-scroll to bottom when keyboard appears
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingAnimationController.dispose();
    _voiceAnimationController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _voiceRecordingTimer?.cancel();
    _chatsStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveUserProfile();
    }
  }

  void _initAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _typingAnimation = CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    );

    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: true);
      });
    }
  }

  void _loadUserProfile() async {
    // TODO: Load from shared preferences
    setState(() {
      _userProfile = {
        'name': 'Mai',
        'skinTone': 'warm_medium',
        'nailLength': 'short',
        'preferredStyles': ['minimal', 'elegant', 'natural'],
        'budget': 'medium',
        'savedDesigns': [1, 3, 5],
        'bookingHistory': [
          {'date': '2024-01-15', 'service': 'Gel French'},
          {'date': '2024-02-20', 'service': 'Nail art hoa'},
        ],
      };
    });
  }

  void _saveUserProfile() {
    // TODO: Save to shared preferences
  }

  void _loadQuickOptions() {
    setState(() {
      _quickOptions = [
        {
          "icon": Icons.auto_awesome,
          "text": "Gợi ý mẫu nail đẹp",
          "colors": [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
          "category": "suggestion",
          "priority": 1,
        },
        {
          "icon": Icons.palette,
          "text": "Màu nail hợp với da tôi",
          "colors": [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
          "category": "color_analysis",
          "priority": 2,
        },
        {
          "icon": Icons.camera_alt,
          "text": "Phân tích ảnh móng",
          "colors": [Color(0xFF4facfe), Color(0xFF00f2fe)],
          "category": "image_analysis",
          "priority": 3,
        },
        {
          "icon": Icons.calendar_today,
          "text": "Đặt lịch làm nail",
          "colors": [Color(0xFF43e97b), Color(0xFF38f9d7)],
          "category": "booking",
          "priority": 4,
        },
        {
          "icon": Icons.shopping_bag,
          "text": "Sản phẩm đề xuất",
          "colors": [Color(0xFFfa709a), Color(0xFFfee140)],
          "category": "products",
          "priority": 5,
        },
      ];
    });
  }

  void _addWelcomeMessage() {
    Future.delayed(Duration(milliseconds: 500), () {
      _addAIMessage(
        "Chào ${_userProfile['name']}! 👋\nTôi là Nail Assistant AI - trợ lý thông minh của bạn!\n\n🎨 Tôi có thể:\n• Phân tích màu da & đề xuất màu nail phù hợp\n• Nhận diện hình ảnh móng tay của bạn\n• Gợi ý mẫu nail theo sở thích\n• Tư vấn sản phẩnail care\n• Đặt lịch làm nail trực tiếp\n\nBạn muốn bắt đầu từ đâu?",
        type: "welcome",
        actions: [
          {"text": "🎨 Phân tích màu da", "action": "skin_analysis"},
          {"text": "📸 Tải ảnh móng", "action": "upload_image"},
          {"text": "💅 Gợi ý mẫu nail", "action": "suggest_designs"},
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Bỏ SafeArea bao ngoài body
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F5),
              Color(0xFFFFF8FB),
              Colors.white,
            ],
          ),
        ),
        // Thay SafeArea bằng Column trực tiếp
        child: Column(
          children: [
            // ------------------ SMART APP BAR (Đã tự xử lý padding) ------------------
            _buildSmartAppBar(),

            // ------------------ CHAT LIST ------------------
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is UserScrollNotification) {
                    FocusScope.of(context).unfocus();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildSmartChatBubble(msg, index);
                  },
                ),
              ),
            ),

            // ... (Giữ nguyên các widget logic khác: Image Analysis, Typing...)
            if (_imageAnalysisResult != null) _buildImageAnalysisCard(),
            if (_isLoading) _buildTypingIndicator(),
            if (_isRecordingVoice) _buildVoiceRecordingUI(),
            if (_shouldShowSuggestions()) _buildContextualSuggestions(),

            // ------------------ SMART INPUT AREA (Vừa sửa ở trên) ------------------
            _buildSmartInputArea(),
          ],
        ),
      ),
    );
  }

  // ================== SMART APP BAR ==================
  Widget _buildSmartAppBar() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nút Back
          _buildAppBarButton(
            Icons.arrow_back,
                () => Navigator.pop(context),
            color: const Color(0xFFF25278),
          ),
          const SizedBox(width: 12),

          // Avatar AI
          _buildSmartAIAvatar(),

          const SizedBox(width: 12),

          // Phần thông tin (Sửa lỗi Overflow tại đây)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Nail Assistant AI",
                        style: const TextStyle(
                          color: Color(0xFFF25278),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "AI Pro",
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _isLoading ? "Đang suy nghĩ..." : "Trực tuyến",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nút Action bên phải
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAppBarButton(
                Icons.person,
                _showUserProfile,
                color: Colors.grey[700]!,
              ),
              const SizedBox(width: 8),
              _buildAppBarButton(
                Icons.more_vert,
                _showMoreOptions,
                color: Colors.grey[700]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAIAvatar() {
    return Stack(
      children: [
        // Outer glow
        AnimatedContainer(
          duration: Duration(milliseconds: 500),
          width: _isLoading ? 46 : 42,
          height: _isLoading ? 46 : 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _getAIGradientByPersonality(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              if (_isLoading)
                BoxShadow(
                  color: _getAIColorByPersonality().withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? _buildTypingAnimationAvatar()
                : Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
        ),

        // Personality badge
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Icon(
              _getPersonalityIcon(),
              color: _getAIColorByPersonality(),
              size: 12,
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getAIGradientByPersonality() {
    switch (_currentPersonality) {
      case 'creative':
        return [Color(0xFF6A11CB), Color(0xFF2575FC)];
      case 'professional':
        return [Color(0xFF2196F3), Color(0xFF21CBF3)];
      default: // friendly
        return [Color(0xFFFF9A9E), Color(0xFFFAD0C4)];
    }
  }

  Color _getAIColorByPersonality() {
    switch (_currentPersonality) {
      case 'creative':
        return Color(0xFF6A11CB);
      case 'professional':
        return Color(0xFF2196F3);
      default:
        return Color(0xFFFF9A9E);
    }
  }

  IconData _getPersonalityIcon() {
    switch (_currentPersonality) {
      case 'creative':
        return Icons.brush;
      case 'professional':
        return Icons.work;
      default:
        return Icons.favorite;
    }
  }

  // ================== USER PROFILE CARD ==================
  bool _showUserProfileCard() {
    return messages.length <= 3 && _userProfile['name'] != 'Khách';
  }

  Widget _buildPreferenceChip(String style) {
    final Map<String, Color> styleColors = {
      'minimal': Color(0xFFE3F2FD),
      'elegant': Color(0xFFF3E5F5),
      'natural': Color(0xFFE8F5E9),
      'glam': Color(0xFFFFF3E0),
      'bold': Color(0xFFFFEBEE),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: styleColors[style] ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        style,
        style: TextStyle(fontSize: 11, color: Colors.black87),
      ),
    );
  }

  // ================== SMART CHAT BUBBLES ==================
  Widget _buildSmartChatBubble(Map<String, dynamic> msg, int index) {
    final bool isUser = msg["role"] == "user";
    final String type = msg["type"] ?? "text";
    final List<dynamic>? actions = msg["actions"];

    return Column(
      children: [
        // Message bubble
        _buildEnhancedChatBubble(msg["text"]!, isUser, type, index),

        // Action buttons (for AI messages)
        if (actions != null && !isUser)
          Padding(
            padding: EdgeInsets.only(left: 60, right: 16, top: 8, bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map<Widget>((action) => _buildActionButton(action))
                  .toList(),
            ),
          ),

        // Image attachment
        if (type == "image_attachment" && msg["image"] != null)
          Padding(
            padding: EdgeInsets.only(left: isUser ? 60 : 16, right: isUser ? 16 : 60),
            child: _buildImageAttachment(msg["image"]),
          ),
      ],
    );
  }

  Widget _buildActionButton(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: () => _handleAction(action["action"]),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFF25278).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getActionIcon(action["action"]), size: 16, color: Color(0xFFF25278)),
            SizedBox(width: 6),
            Text(
              action["text"],
              style: TextStyle(fontSize: 13, color: Color(0xFFF25278)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'skin_analysis': return Icons.palette;
      case 'upload_image': return Icons.camera_alt;
      case 'suggest_designs': return Icons.auto_awesome;
      case 'book_appointment': return Icons.calendar_today;
      case 'view_gallery': return Icons.photo_library;
      default: return Icons.arrow_forward;
    }
  }

  Widget _buildImageAttachment(dynamic image) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65, // Tối đa 65% màn hình
        maxHeight: 250,
      ),
      child: ClipRRect( // Bo góc ảnh
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            image is String
                ? Image.network(image, fit: BoxFit.cover)
                : Image.file(image, fit: BoxFit.cover),

            // Nút xóa ảnh (nếu cần)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                // Thêm logic xóa nếu muốn
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== IMAGE ANALYSIS CARD ==================
  Widget _buildImageAnalysisCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "PHÂN TÍCH ẢNH AI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "🔍 AI đã phân tích ảnh móng của bạn:",
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          SizedBox(height: 8),
          // Analysis results
          if (_imageAnalysisResult != null)
            ..._buildAnalysisResults(),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.recommend),
                  label: Text("Đề xuất mẫu"),
                  onPressed: () => _suggestDesignsFromAnalysis(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF667eea),
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _imageAnalysisResult = null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnalysisResults() {
    return [
      _buildAnalysisRow("📏 Chiều dài móng", "Ngắn", 85),
      _buildAnalysisRow("🎨 Màu phù hợp", "Pastel, Nude", 90),
      _buildAnalysisRow("💎 Đề xuất kiểu", "French, Minimal", 80),
      _buildAnalysisRow("⭐ Tình trạng móng", "Khỏe", 95),
    ];
  }

  Widget _buildAnalysisRow(String label, String value, int score) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 12)),
          SizedBox(width: 8),
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== SKIN TONE ANALYSIS ==================
  bool _shouldShowSkinAnalysis() {
    return messages.any((msg) =>
    msg["type"] == "skin_analysis_request" ||
        (msg["text"] as String).contains("màu da"));
  }

  String _getSkinToneName(String tone) {
    switch (tone) {
      case 'fair': return 'sáng';
      case 'light': return 'sáng nhẹ';
      case 'warm_medium': return 'trung bình ấm';
      case 'olive': return 'olive';
      case 'deep': return 'đậm';
      default: return 'trung bình';
    }
  }

  List<Color> _getRecommendedColors(String skinTone) {
    switch (skinTone) {
      case 'fair':
        return [Color(0xFFFFCDD2), Color(0xFFF8BBD0), Color(0xFFE1BEE7), Color(0xFFD1C4E9)];
      case 'light':
        return [Color(0xFFBBDEFB), Color(0xFFB3E5FC), Color(0xFFB2EBF2), Color(0xFFC8E6C9)];
      case 'warm_medium':
        return [Color(0xFFFFCCBC), Color(0xFFFFECB3), Color(0xFFF0F4C3), Color(0xFFDCEDC8)];
      case 'olive':
        return [Color(0xFFA5D6A7), Color(0xFFC5E1A5), Color(0xFFE6EE9C), Color(0xFFFFF59D)];
      case 'deep':
        return [Color(0xFFEF9A9A), Color(0xFFF48FB1), Color(0xFFCE93D8), Color(0xFF9FA8DA)];
      default:
        return [Color(0xFFFFCDD2), Color(0xFFBBDEFB), Color(0xFFC8E6C9)];
    }
  }

  Widget _buildColorChip(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  // ================== VOICE RECORDING UI ==================
  Widget _buildVoiceRecordingUI() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF25278),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Đang ghi âm...",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 12),
          AnimatedBuilder(
            animation: _voiceAnimationController,
            builder: (context, child) {
              return Container(
                width: 100 + (_voiceAnimationController.value * 40),
                height: 100 + (_voiceAnimationController.value * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          Text(
            "${_voiceRecordingSeconds}s",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Nhấn giữ để nói, thả ra để gửi",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: _cancelVoiceRecording,
              ),
              SizedBox(width: 40),
              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.white, size: 40),
                onPressed: _stopVoiceRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================== CONTEXTUAL SUGGESTIONS ==================
  bool _shouldShowSuggestions() {
    if (_isLoading || _isRecordingVoice) return false;
    final lastMessage = messages.isNotEmpty ? messages.last : null;
    if (lastMessage == null) return true;
    final bool isAI = lastMessage["role"] == "ai";
    final int timeSinceLastMessage = DateTime.now().difference(lastMessage["timestamp"]).inSeconds;
    return isAI && timeSinceLastMessage < 30 && _quickOptions.isNotEmpty;
  }

  Widget _buildContextualSuggestions() {
    return Container(
      height: 70,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickOptions.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) => _buildSmartQuickReply(_quickOptions[index]),
      ),
    );
  }

  Widget _buildSmartQuickReply(Map<String, dynamic> item) {
    return Tooltip(
      message: item["text"],
      child: GestureDetector(
        onTap: () => _handleQuickReply(item),
        onLongPress: () => _showQuickReplyOptions(item),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(item["icon"], color: Colors.white, size: 16),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  item["text"],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== SMART INPUT AREA ==================
  Widget _buildSmartInputArea() {
    // Lấy khoảng cách an toàn dưới đáy (cho các máy có thanh Home ảo)
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Giảm padding top xuống 8, bottom thì linh động theo máy
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding > 0 ? bottomPadding : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        // QUAN TRỌNG: Dòng này giúp khung trắng co lại, không bị thừa chỗ trống
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dãy nút Camera, Thư viện...
          _buildAttachmentOptions(),

          // Giảm khoảng cách giữa icon và ô nhập liệu từ 12 xuống 8
          const SizedBox(height: 8),

          // Hàng chứa ô nhập liệu và nút gửi
          Row(
            children: [
              // Nút Voice (Mic)
              GestureDetector(
                onLongPressStart: (_) => _startVoiceRecording(),
                onLongPressEnd: (_) => _stopVoiceRecording(),
                child: Container(
                  padding: const EdgeInsets.all(8), // Giảm padding nút mic cho gọn
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF25278).withOpacity(0.1),
                  ),
                  child: const Icon(Icons.mic_none, color: Color(0xFFF25278), size: 24),
                ),
              ),
              const SizedBox(width: 8),

              // Ô nhập liệu (Input Field)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100), // Giới hạn chiều cao
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    textAlignVertical: TextAlignVertical.center, // Căn giữa chữ
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: "Nhập câu hỏi...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      // Padding gọn gàng hơn
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) => _isLoading ? null : sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút Gửi / Chọn ảnh
              if (_selectedImage != null || _controller.text.isNotEmpty)
                _buildSendButton()
              else
                _buildImageButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAttachmentOption(Icons.camera_alt, "Camera", () => _pickImage(ImageSource.camera)),
        _buildAttachmentOption(Icons.photo_library, "Thư viện", () => _pickImage(ImageSource.gallery)),
        _buildAttachmentOption(Icons.palette, "Màu da", () => _requestSkinAnalysis()),
        _buildAttachmentOption(Icons.calendar_today, "Đặt lịch", () => _bookAppointment()),
      ],
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFF25278).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFFF25278), size: 20),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _isLoading ? null : sendMessage,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFF25278), Color(0xFFFF867A)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFF25278).withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildImageButton() {
    return GestureDetector(
      onTap: () => _showImagePickerOptions(),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF4CAF50).withOpacity(0.1),
        ),
        child: Icon(Icons.image, color: Color(0xFF4CAF50), size: 22),
      ),
    );
  }

  // ================== HELPER WIDGETS ==================
  Widget _buildAppBarButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.grey.shade700, size: 20),
      ),
    );
  }

  Widget _buildTypingAnimationAvatar() {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_typingAnimation.value * 0.2),
          child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(right: 8, top: 4),
            child: _buildSmartAIAvatar(),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: List.generate(3, (index) => _buildTypingDot(index * 200)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final double opacity = (sin(
            _typingAnimationController.value * 2 * pi +
                (delay / 1000) * 2 * pi) +
            1) /
            2;
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getAIColorByPersonality(),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedChatBubble(
      String text, bool isUser, String type, int index) {
    final Color bubbleColor = _getBubbleColor(type);
    final bool showTail = index == messages.length - 1 || isUser;

    // Tính toán khoảng đệm động (20% màn hình)
    final double spacerWidth = MediaQuery.of(context).size.width * 0.2;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        // Giảm padding bên trái/phải để nội dung rộng hơn
        left: isUser ? spacerWidth : 0,
        right: isUser ? 0 : spacerWidth,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // Căn đáy cho avatar thẳng hàng
        children: [
          if (!isUser && showTail) ...[
            _buildSmartAIAvatar(),
            const SizedBox(width: 8),
          ] else if (!isUser)
            const SizedBox(width: 48), // Giữ khoảng trống bằng kích thước avatar + margin

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFF25278) : bubbleColor,
                gradient: isUser
                    ? const LinearGradient(
                  colors: [Color(0xFFF25278), Color(0xFFFF867A)],
                )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser || !showTail ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: !isUser || !showTail ? const Radius.circular(20) : const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (type == "product") ...[
                    const SizedBox(height: 8),
                    _buildProductPreview(),
                  ]
                ],
              ),
            ),
          ),

          if (isUser && showTail) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFF25278).withOpacity(0.2),
              child: Icon(Icons.person, size: 18, color: Color(0xFFF25278)),
            ),
          ] else if (isUser) SizedBox(width: 48),
        ],
      ),
    );
  }

  Color _getBubbleColor(String type) {
    switch (type) {
      case "image": return Color(0xFFE3F2FD);
      case "gallery": return Color(0xFFF3E5F5);
      case "product": return Color(0xFFE8F5E8);
      case "booking": return Color(0xFFFFF8E1);
      case "analysis": return Color(0xFFE0F7FA);
      default: return Colors.white;
    }
  }

  Widget _buildProductPreview() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage("https://picsum.photos/seed/product/100/100"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sơn Gel Cao Cấp", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Bền màu 3 tuần", style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text("250.000đ", style: TextStyle(color: Color(0xFFF25278), fontWeight: FontWeight.bold)),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFF25278).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text("Mua", style: TextStyle(color: Color(0xFFF25278), fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== BUSINESS LOGIC ==================
  void _addAIMessage(String text, {String type = "text", List<dynamic>? actions}) {
    setState(() {
      messages.add({
        "role": "ai",
        "text": text,
        "type": type,
        "timestamp": DateTime.now(),
        "actions": actions,
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text, {String type = "text"}) {
    setState(() {
      messages.add({
        "role": "user",
        "text": text,
        "type": type,
        "timestamp": DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<Map<String, dynamic>> _analyzeAndRespond(String query) async {
    // Simple AI response logic - can be replaced with real AI
    if (query.contains("màu da") || query.contains("skin tone")) {
      return {
        "text": "Tôi thấy bạn quan tâm đến màu sắc phù hợp với da. Dựa trên hồ sơ của bạn, tôi đề xuất các màu pastel và nude nhẹ nhàng. Bạn có muốn tôi phân tích kỹ hơn không?",
        "type": "analysis",
      };
    } else if (query.contains("ảnh") || query.contains("hình")) {
      return {
        "text": "Tôi có thể phân tích ảnh móng tay của bạn! Hãy tải lên một bức ảnh và tôi sẽ:\n• Đánh giá tình trạng móng\n• Đề xuất kiểu nail phù hợp\n• Gợi ý sản phẩm chăm sóc",
        "type": "image",
      };
    } else if (query.contains("đặt lịch") || query.contains("booking")) {
      return {
        "text": "Tôi có thể giúp bạn đặt lịch làm nail! Bạn muốn đặt:\n• Làm móng gel\n• Nail art\n• Chăm sóc móng\n• Sửa móng",
        "type": "booking",
      };
    }

    final response = await ChatbotService.sendMessage(query);
    return {"text": response, "type": "text"};
  }

  void _handleQuickReply(Map<String, dynamic> item) {
    final String category = item["category"];
    switch (category) {
      case "color_analysis":
        _requestSkinAnalysis();
        break;
      case "image_analysis":
        _showImagePickerOptions();
        break;
      case "booking":
        _bookAppointment();
        break;
      default:
        sendQuickMessage(item["text"]);
    }
  }

  void sendQuickMessage(String msg) async {
    _addUserMessage(msg);
    setState(() => _isLoading = true);

    await Future.delayed(Duration(milliseconds: 800));
    final aiResponse = await ChatbotService.sendMessage(msg);

    _addAIMessage(aiResponse);
    setState(() => _isLoading = false);
  }

  void _handleAction(String action) {
    switch (action) {
      case "skin_analysis":
        _requestSkinAnalysis();
        break;
      case "upload_image":
        _showImagePickerOptions();
        break;
      case "suggest_designs":
        _suggestDesigns();
        break;
      case "book_appointment":
        _bookAppointment();
        break;
    }
  }

  void _requestSkinAnalysis() {
    _addUserMessage("Tôi muốn phân tích màu da để chọn màu nail phù hợp", type: "skin_analysis_request");
    setState(() => _isLoading = true);

    Future.delayed(Duration(seconds: 1), () {
      _addAIMessage(
        "Dựa trên phân tích, da bạn thuộc tông ${_getSkinToneName(_userProfile['skinTone'])}. Các màu nail phù hợp nhất:",
        type: "skin_analysis",
      );
      setState(() => _isLoading = false);
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Chọn ảnh móng tay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(Icons.camera_alt, "Chụp ảnh", () => _pickImage(ImageSource.camera)),
                _buildImageOption(Icons.photo_library, "Thư viện", () => _pickImage(ImageSource.gallery)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildChatHistorySheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 12),
                Text(
                  'Lịch sử trò chuyện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF25278),
                  ),
                ),
                Spacer(),
                if (_chatHistoryList.isNotEmpty)
                  TextButton(
                    onPressed: _showHistoryOptions,
                    child: Text(
                      'Tùy chọn',
                      style: TextStyle(color: Color(0xFFF25278), fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),

          // Filter tabs
          _buildHistoryFilterTabs(),

          // History list
          Expanded(
            child: _isLoadingHistory
                ? _buildHistoryLoading()
                : _chatHistoryList.isEmpty
                ? _buildEmptyHistory()
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }
  Widget _buildHistoryFilterTabs() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterChip('Tất cả', Icons.chat, true),
          _buildFilterChip('Đã gắn sao', Icons.star, false),
          _buildFilterChip('Đã lưu trữ', Icons.archive, false),
          _buildFilterChip('Gần đây', Icons.access_time, false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool active) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Color(0xFFF25278) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: active ? Colors.white : Colors.grey),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFF25278)),
          SizedBox(height: 16),
          Text(
            'Đang tải lịch sử...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF25278).withOpacity(0.1),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFFF25278),
              size: 40,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Chưa có lịch sử trò chuyện',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Các cuộc trò chuyện của bạn sẽ\nxuất hiện ở đây',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Bắt đầu chat mới
              _controller.text = '';
              _focusNode.requestFocus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF25278),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('Bắt đầu trò chuyện mới',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _chatHistoryList.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) => _buildHistoryItem(_chatHistoryList[index]),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> chat) {
    final chatInfo = Map<String, dynamic>.from(chat['chatInfo'] ?? {});
    final title = chatInfo['title'] ?? 'Cuộc trò chuyện';
    final lastMessage = chat['lastMessage'] ?? '';
    final updatedAt = (chatInfo['updatedAt'] as Timestamp?)?.toDate();
    final isStarred = chat['isStarred'] == true;
    final isArchived = chat['isArchived'] == true;
    final messageCount = (chat['statistics']?['totalMessages'] as int? ?? 0);

    return InkWell(
      onTap: () => _loadChatFromHistory(chat['id']),
      onLongPress: () => _showHistoryItemOptions(chat),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Chat icon với trạng thái
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isStarred
                      ? [Color(0xFFFFD700), Color(0xFFFFA500)]
                      : [Color(0xFFF25278), Color(0xFFFF867A)],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      isArchived ? Icons.archive : Icons.chat_bubble,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (isStarred)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.star, size: 16, color: Colors.white),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12),

            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (lastMessage.isNotEmpty)
                    Text(
                      lastMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        _formatTimeAgo(updatedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.message, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        '$messageCount tin nhắn',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // More options button
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[500]),
              onPressed: () => _showHistoryItemOptions(chat),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Vừa xong';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Widget _buildImageOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF25278).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFFF25278), size: 30),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
  // Hàm phụ trợ để gọi Service ngắn gọn hơn
  Future<void> _saveMessageToFirebase(String text, String role, [String type = 'text']) async {
    if (_currentChatId == null) return;

    try {
      await FirebaseChatHistoryService.saveMessage(
        chatId: _currentChatId!,
        text: text,
        role: role,
        type: type,
      );
    } catch (e) {
      print('Lỗi khi lưu tin nhắn: $e');
    }
  }
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _isAnalyzingImage = true;
      });

      _addUserMessage("Đã tải lên ảnh móng tay", type: "image_attachment");

      // Simulate AI analysis
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _isAnalyzingImage = false;
          _imageAnalysisResult = {
            "nail_length": "short",
            "recommended_colors": ["pastel", "nude"],
            "nail_health": "good",
            "suggested_styles": ["french", "minimal"],
          };
        });

        _addAIMessage(
          "✅ Đã phân tích xong ảnh móng của bạn!\n\n📏 Chiều dài: Móng ngắn\n🎨 Màu phù hợp: Pastel, Nude nhẹ\n💎 Kiểu đề xuất: French tip, Minimalist\n⭐ Tình trạng: Móng khỏe, cần dưỡng ẩm",
          type: "analysis",
        );
      });
    }
  }

  void _suggestDesignsFromAnalysis() {
    _addAIMessage(
      "Dựa trên phân tích ảnh, đây là 3 mẫu nail phù hợp nhất với bạn:",
      type: "gallery",
      actions: [
        {"text": "Xem thêm mẫu", "action": "view_gallery"},
        {"text": "Lưu vào BST", "action": "save_designs"},
      ],
    );
  }

  void _suggestDesigns() {
    final styles = _userProfile['preferredStyles'].join(", ");
    _addAIMessage(
      "Dựa trên sở thích ($styles) của bạn, tôi đề xuất:",
      type: "gallery",
    );
  }

  void _bookAppointment() {
    _addAIMessage(
      "Tôi sẽ giúp bạn đặt lịch! Bạn muốn:\n• Dịch vụ gì?\n• Ngày nào?\n• Giờ nào phù hợp?",
      type: "booking",
      actions: [
        {"text": "Hôm nay", "action": "book_today"},
        {"text": "Ngày mai", "action": "book_tomorrow"},
        {"text": "Chọn ngày", "action": "pick_date"},
      ],
    );
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hồ sơ của bạn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👤 ${_userProfile['name']}", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("🎨 Sở thích: ${_userProfile['preferredStyles'].join(', ')}"),
            Text("📏 Chiều dài móng: ${_userProfile['nailLength']}"),
            Text("💰 Ngân sách: ${_userProfile['budget']}"),
            SizedBox(height: 12),
            Text("📊 Thống kê:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("• ${_userProfile['savedDesigns'].length} mẫu đã lưu"),
            Text("• ${_userProfile['bookingHistory'].length} lần đặt lịch"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Đóng"),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.settings, color: Color(0xFFF25278)),
              title: Text("Cài đặt AI"),
              onTap: () => _showAISettings(),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Color(0xFFF25278)),
              title: Text("Lịch sử chat"),
              onTap: () => _showChatHistory(),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Color(0xFFF25278)),
              title: Text("Xóa cuộc trò chuyện"),
              onTap: _clearChat,
            ),
            ListTile(
              leading: Icon(Icons.help, color: Color(0xFFF25278)),
              title: Text("Trợ giúp & Hướng dẫn"),
              onTap: () => _showHelp(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAISettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Cài đặt AI Assistant"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text("Tính cách AI"),
                  subtitle: Text(_currentPersonality.toUpperCase()),
                  trailing: DropdownButton<String>(
                    value: _currentPersonality,
                    onChanged: (value) {
                      setState(() => _currentPersonality = value!);
                    },
                    items: _aiPersonalities.map((personality) {
                      return DropdownMenuItem(
                        value: personality,
                        child: Text(personality.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
                SwitchListTile(
                  title: Text("Gợi ý thông minh"),
                  subtitle: Text("AI đề xuất dựa trên context"),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: Text("Phân tích ảnh AI"),
                  subtitle: Text("Tự động phân tích ảnh tải lên"),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Lưu"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChatHistory() {
    _loadChatHistory();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChatHistorySheet(),
    );
  }
  void _loadChatHistory() {
    setState(() {
      _isLoadingHistory = true;
    });

    // Hủy subscription cũ nếu có
    _chatsStreamSubscription?.cancel();

    // Lấy stream chats từ Firebase
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoadingHistory = false;
        _chatHistoryList = [];
      });
      return;
    }

    _chatsStreamSubscription = FirebaseChatHistoryService
        .getUserChatsStream(userId: userId, limit: 50)
        .listen((snapshot) {
      setState(() {
        _chatHistoryList = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'chatInfo': Map<String, dynamic>.from(data['chatInfo'] ?? {}),
          };
        }).toList();
        _isLoadingHistory = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoadingHistory = false;
      });
      print('Error loading chat history: $error');
    });
  }
  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận"),
        content: Text("Bạn có chắc muốn xóa toàn bộ cuộc trò chuyện?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              setState(() => messages.clear());
              Navigator.pop(context);
              _addWelcomeMessage();
            },
            child: Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    // TODO: Implement help guide
  }

  void _showQuickReplyOptions(Map<String, dynamic> item) {
    // TODO: Implement long press options for quick replies
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecordingVoice = true;
      _voiceRecordingSeconds = 0;
      _voiceAnimationController.repeat(reverse: true);
    });

    _voiceRecordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() => _voiceRecordingSeconds++);
      if (_voiceRecordingSeconds >= 60) {
        _stopVoiceRecording();
      }
    });
  }

  void _stopVoiceRecording() {
    _voiceRecordingTimer?.cancel();
    _voiceAnimationController.stop();

    setState(() {
      _isRecordingVoice = false;
    });

    // Simulate voice recognition
    if (_voiceRecordingSeconds > 1) {
      _addUserMessage("[Tin nhắn thoại ${_voiceRecordingSeconds}s]", type: "voice");
      Future.delayed(Duration(seconds: 1), () {
        _addAIMessage("Đã nhận được tin nhắn thoại của bạn! Tôi có thể giúp gì thêm không?", type: "text");
      });
    }
  }

  void _cancelVoiceRecording() {
    _voiceRecordingTimer?.cancel();
    _voiceAnimationController.stop();
    setState(() => _isRecordingVoice = false);
  }
  // ================== CHAT HISTORY ACTIONS ==================

  void _loadChatFromHistory(String chatId) async {
    // Xác nhận nếu đang có chat hiện tại
    if (messages.isNotEmpty && chatId != _currentChatId) {
      final confirmed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Tải cuộc trò chuyện'),
          content: Text('Cuộc trò chuyện hiện tại sẽ bị mất. Tiếp tục?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Tải', style: TextStyle(color: Color(0xFFF25278))),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    Navigator.pop(context); // Đóng history sheet

    // Hiển thị loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Load messages từ Firebase
      final chatMessages = await FirebaseChatHistoryService
          .loadChatMessages(chatId);

      setState(() {
        messages.clear();
        messages.addAll(chatMessages.map((msg) {
          return {
            'role': msg['sender']?['type'] == 'ai' ? 'ai' : 'user',
            'text': msg['content']?['text'] ?? '',
            'type': msg['content']?['type'] ?? 'text',
            'timestamp': msg['timestamp'],
            'actions': msg['actions'],
          };
        }).toList());

        _currentChatId = chatId;
        _isLoading = false;
      });

      // Scroll xuống cuối
      _scrollToBottom();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tải cuộc trò chuyện'),
          backgroundColor: Color(0xFFF25278),
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải cuộc trò chuyện: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showHistoryItemOptions(Map<String, dynamic> chat) {
    final chatId = chat['id'];
    final isStarred = chat['isStarred'] == true;
    final isArchived = chat['isArchived'] == true;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility, color: Color(0xFFF25278)),
              title: Text('Xem chi tiết'),
              onTap: () {
                Navigator.pop(context);
                _showChatDetails(chat);
              },
            ),
            ListTile(
              leading: Icon(isStarred ? Icons.star_border : Icons.star,
                  color: Color(0xFFF25278)),
              title: Text(isStarred ? 'Bỏ gắn sao' : 'Gắn sao'),
              onTap: () {
                Navigator.pop(context);
                _toggleStarChat(chatId, !isStarred);
              },
            ),
            ListTile(
              leading: Icon(isArchived ? Icons.unarchive : Icons.archive,
                  color: Color(0xFFF25278)),
              title: Text(isArchived ? 'Bỏ lưu trữ' : 'Lưu trữ'),
              onTap: () {
                Navigator.pop(context);
                _toggleArchiveChat(chatId, !isArchived);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Color(0xFFF25278)),
              title: Text('Đổi tên'),
              onTap: () {
                Navigator.pop(context);
                _renameChat(chat);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Xóa', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatDetails(Map<String, dynamic> chat) {
    final chatInfo = Map<String, dynamic>.from(chat['chatInfo'] ?? {});
    final statistics = Map<String, dynamic>.from(chat['statistics'] ?? {});
    final analysisSummary = Map<String, dynamic>.from(chat['analysisSummary'] ?? {});

    final title = chatInfo['title'] ?? 'Cuộc trò chuyện';
    final createdAt = (chatInfo['createdAt'] as Timestamp?)?.toDate();
    final totalMessages = statistics['totalMessages'] ?? 0;
    final wordCount = statistics['wordCount'] ?? 0;
    final skinTone = analysisSummary['skinTone'];
    final recommendedColors = (analysisSummary['recommendedColors'] as List?)?.join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết trò chuyện'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tiêu đề: $title', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (createdAt != null)
                Text('Thời gian: ${DateFormat('HH:mm dd/MM/yyyy').format(createdAt)}'),
              SizedBox(height: 8),
              Text('Số tin nhắn: $totalMessages'),
              SizedBox(height: 8),
              Text('Tổng số từ: $wordCount'),
              SizedBox(height: 8),
              if (skinTone != null)
                Text('Tông da: $skinTone'),
              if (recommendedColors != null && recommendedColors.isNotEmpty)
                Text('Màu đề xuất: $recommendedColors'),
              SizedBox(height: 12),
              if (chat['tags'] != null && (chat['tags'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: (chat['tags'] as List)
                          .map<Widget>((tag) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF25278).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$tag', style: TextStyle(fontSize: 12)),
                      ))
                          .toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadChatFromHistory(chat['id']);
            },
            child: Text('Mở lại', style: TextStyle(color: Color(0xFFF25278))),
          ),
        ],
      ),
    );
  }

  void _toggleStarChat(String chatId, bool isStarred) async {
    try {
      await FirebaseChatHistoryService.updateChatMetadata(
        chatId: chatId,
        isStarred: isStarred,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isStarred ? 'Đã gắn sao' : 'Đã bỏ gắn sao'),
          backgroundColor: Color(0xFFF25278),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleArchiveChat(String chatId, bool isArchived) async {
    try {
      await FirebaseChatHistoryService.updateChatMetadata(
        chatId: chatId,
        isArchived: isArchived,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArchived ? 'Đã lưu trữ' : 'Đã bỏ lưu trữ'),
          backgroundColor: Color(0xFFF25278),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _renameChat(Map<String, dynamic> chat) {
    final chatInfo = Map<String, dynamic>.from(chat['chatInfo'] ?? {});
    final currentTitle = chatInfo['title'] ?? '';

    TextEditingController renameController = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi tên cuộc trò chuyện'),
        content: TextField(
          controller: renameController,
          decoration: InputDecoration(
            hintText: 'Nhập tên mới',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = renameController.text.trim();
              if (newTitle.isNotEmpty && newTitle != currentTitle) {
                try {
                  await FirebaseChatHistoryService.updateChatMetadata(
                    chatId: chat['id'],
                    title: newTitle,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã đổi tên thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi đổi tên: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Lưu', style: TextStyle(color: Color(0xFFF25278))),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat(Map<String, dynamic> chat) {
    final title = (chat['chatInfo']?['title'] ?? 'Cuộc trò chuyện') as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn xóa "$title"?'),
            SizedBox(height: 12),
            Text('Chọn cách xóa:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _softDeleteChat(chat['id'], title);
            },
            child: Text('Xóa tạm', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permanentlyDeleteChat(chat['id'], title);
            },
            child: Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _softDeleteChat(String chatId, String title) async {
    try {
      await FirebaseChatHistoryService.softDeleteChat(chatId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển "$title" vào thùng rác'),
          backgroundColor: Color(0xFFF25278),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _permanentlyDeleteChat(String chatId, String title) async {
    try {
      await FirebaseChatHistoryService.permanentlyDeleteChat(chatId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa vĩnh viễn "$title"'),
          backgroundColor: Color(0xFFF25278),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHistoryOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_sweep, color: Color(0xFFF25278)),
              title: Text('Xóa tất cả lịch sử'),
              onTap: () {
                Navigator.pop(context);
                _confirmClearAllHistory();
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: Color(0xFFF25278)),
              title: Text('Làm mới danh sách'),
              onTap: () {
                Navigator.pop(context);
                _loadChatHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã làm mới danh sách'),
                    backgroundColor: Color(0xFFF25278),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud_download, color: Color(0xFFF25278)),
              title: Text('Xuất lịch sử'),
              onTap: () {
                Navigator.pop(context);
                _exportChatHistory();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAllHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa tất cả lịch sử'),
        content: Text('Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllHistory();
            },
            child: Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllHistory() async {
    try {
      // Lấy tất cả chats của user
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('nail_chatbot_chats')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      // Soft delete tất cả
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa toàn bộ lịch sử'),
          backgroundColor: Color(0xFFF25278),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa lịch sử: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportChatHistory() {
    // TODO: Implement export to file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng xuất lịch sử đang phát triển'),
        backgroundColor: Color(0xFFF25278),
      ),
    );
  }

// ================== UPDATE SEND MESSAGE TO SAVE TO FIREBASE ==================
  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Yêu cầu đăng nhập
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng đăng nhập để lưu chat'),
          backgroundColor: Colors.orange,
        ),
      );

      _addUserMessage(_controller.text);
      _controller.clear();
      return;
    }

    final msg = _controller.text;
    _controller.clear();

    // Tạo chat mới nếu chưa có
    if (_currentChatId == null) {
      try {
        _currentChatId = await FirebaseChatHistoryService.createNewChat(
          userId: userId,
          title: msg.length > 30 ? '${msg.substring(0, 30)}...' : msg,
        );
      } catch (e) {
        print('Error creating new chat: $e');
        return;
      }
    }

    // Add user message
    _addUserMessage(msg);
    setState(() => _isLoading = true);
    if (_currentChatId != null) {
      FirebaseChatHistoryService.saveMessage(
        chatId: _currentChatId!,
        text: msg,
        role: 'user',
      );
    }
    await _saveMessageToFirebase(msg, 'user');

    // Get AI response
    final aiResponse = await _analyzeAndRespond(msg);

    _addAIMessage(aiResponse['text'], type: aiResponse['type']);
    setState(() => _isLoading = false);
    if (_currentChatId != null) {
      FirebaseChatHistoryService.saveMessage(
        chatId: _currentChatId!,
        text: aiResponse['text'],
        role: 'ai',
        type: aiResponse['type'] ?? 'text',
      );
    }
    await _saveMessageToFirebase(aiResponse['text'], 'ai', aiResponse['type']);
  }
}