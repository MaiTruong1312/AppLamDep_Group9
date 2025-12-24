import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart'; // Bảng màu hồng chủ đạo của dự án
import '../../theme/app_typography.dart'; // Hệ thống kiểu chữ chuẩn
import '../../models/store_model.dart'; // Model chứa thông tin tiệm
import '../../models/service_model.dart'; // Model chứa thông tin dịch vụ

/// ===========================================================================
/// CLASS CHATSCREEN: MÀN HÌNH NHẮN TIN TRỰC TUYẾN GIỮA KHÁCH VÀ TIỆM
/// ===========================================================================
/// Chức năng này đáp ứng yêu cầu trong Chương 2.2.4 của mục lục báo cáo.
/// Hệ thống sử dụng Cloud Firestore để lưu trữ và cập nhật tin nhắn Real-time.
class ChatScreen extends StatefulWidget {
  final String storeId; // ID tiệm để định danh cuộc hội thoại
  final String storeName; // Tên tiệm hiển thị trên thanh AppBar
  final List<Service>? sampleServices; // Danh sách dịch vụ mẫu để gợi ý cho khách

  const ChatScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    this.sampleServices,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isWriting = false; // Theo dõi trạng thái người dùng đang nhập văn bản

  // TẠO CHAT ID DUY NHẤT: Kết hợp giữa UID người dùng và ID tiệm
  String get _chatId => "${_user?.uid}_${widget.storeId}";

  // THAM CHIẾU ĐẾN COLLECTION TIN NHẮN TRÊN FIRESTORE
  CollectionReference get _messageRef => FirebaseFirestore.instance
      .collection('chats')
      .doc(_chatId)
      .collection('messages');

  @override
  void initState() {
    super.initState();
    _ensureInitialGreeting(); // Gửi lời chào tự động khi bắt đầu cuộc chat
  }

  /// -------------------------------------------------------------------------
  /// LOGIC 1: LỜI CHÀO TỰ ĐỘNG (BOT GREETING)
  /// -------------------------------------------------------------------------
  /// Kiểm tra nếu cuộc hội thoại mới tinh, Bot sẽ tự động gửi lời chào ban đầu.
  Future<void> _ensureInitialGreeting() async {
    final snapshot = await _messageRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      await _saveMessage(
        text: "Hi ${_user?.displayName?.split(' ').first ?? 'Customer'}! How can we help you today?",
        isUser: false,
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// LOGIC 2: LƯU TIN NHẮN VÀO FIRESTORE
  /// -------------------------------------------------------------------------
  /// Lưu trữ nội dung, thời gian và vai trò (người dùng hay tiệm) vào cơ sở dữ liệu.
  Future<void> _saveMessage({required String text, required bool isUser, List<Service>? suggestions}) async {
    await _messageRef.add({
      'text': text,
      'isUser': isUser,
      'timestamp': FieldValue.serverTimestamp(), // Sử dụng thời gian của Server để chính xác tuyệt đối
      'suggestions': suggestions?.map((s) => {
        'name': s.name,
        'imageUrl': s.imageUrl,
      }).toList(),
    });
    _scrollToBottom(); // Tự động cuộn xuống tin nhắn mới nhất
  }

  /// -------------------------------------------------------------------------
  /// LOGIC 3: XỬ LÝ GỬI TIN NHẮN VÀ PHẢN HỒI THÔNG MINH
  /// -------------------------------------------------------------------------
  void _handleSend(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    setState(() => _isWriting = false);

    // 1. Lưu tin nhắn của người dùng
    await _saveMessage(text: text, isUser: true);

    // 2. Giả lập phản hồi từ phía Tiệm (hoặc AI Assistance) sau 1 giây
    Future.delayed(const Duration(seconds: 1), () async {
      String replyText = "Thank you for contacting us! We will get back to you as soon as possible.";
      List<Service>? suggestions;

      // Logic phản hồi dựa trên từ khóa người dùng gửi
      if (text == "Book Now") {
        replyText = "Great choice! Here are our featured services at ${widget.storeName}:";
        suggestions = widget.sampleServices;
      } else if (text == "Consultant") {
        replyText = "What would you like to be consulted about? Our experts are ready to assist you.";
      }

      await _saveMessage(text: replyText, isUser: false, suggestions: suggestions);
    });
  }

  // Tự động cuộn danh sách xuống cuối cùng
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.neutral950),
        title: Text(widget.storeName, style: AppTypography.labelLG.copyWith(color: AppColors.neutral950)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // VÙNG HIỂN THỊ TIN NHẮN (REAL-TIME STREAM)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messageRef.orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Hiển thị danh sách bóng bong tin nhắn
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildMessageBubble(messages[index].data() as Map<String, dynamic>),
                          childCount: messages.length,
                        ),
                      ),
                    ),
                    // PHẦN CÂU HỎI NHANH (QUICK ACTIONS) LUÔN NẰM Ở CUỐI VÙNG CUỘN
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildHighlightedQuickActions(),
                    ),
                  ],
                );
              },
            ),
          ),
          // THANH NHẬP TIN NHẮN (INPUT BAR)
          _buildPillInputBar(),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// WIDGET: _BUILDMESSAGEBUBBLE - THIẾT KẾ BÓNG BONG TIN NHẮN
  /// -------------------------------------------------------------------------
  Widget _buildMessageBubble(Map<String, dynamic> data) {
    bool isUser = data['isUser'] ?? false;
    var suggestions = data['suggestions'] as List<dynamic>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildBotAvatar(), // Hiển thị Avatar nếu là tin nhắn từ tiệm
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.white, // Màu hồng cho User, Trắng cho Bot
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Text(
                      data['text'] ?? '',
                      style: AppTypography.textSM.copyWith(
                          color: isUser ? AppColors.white : AppColors.neutral950,
                          fontWeight: FontWeight.w500
                      )
                  ),
                ),
              ),
            ],
          ),
          // Hiển thị danh sách thẻ dịch vụ gợi ý nếu có (Service Suggestions)
          if (suggestions != null && suggestions.isNotEmpty) _buildServiceList(suggestions),
        ],
      ),
    );
  }

  // Widget hiển thị Avatar biểu tượng AI/Bot
  Widget _buildBotAvatar() => CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14)
  );

  /// Widget hiển thị danh sách các dịch vụ gợi ý trượt ngang trong Chat
  Widget _buildServiceList(List<dynamic> suggestions) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 12, left: 40),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    s['imageUrl'] ?? '',
                    width: 45, height: 45, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.spa, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(s['name'] ?? '', style: AppTypography.textXS.copyWith(fontWeight: FontWeight.bold), maxLines: 2)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// WIDGET: _BUILDHIGHLIGHTEDQUICKACTIONS - CÁC NÚT HỎI NHANH
  /// -------------------------------------------------------------------------
  /// Giúp người dùng tương tác nhanh mà không cần nhập liệu nhiều.
  Widget _buildHighlightedQuickActions() {
    final actions = ["Book Now", "Consultant", "Learn more"];
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(height: 40),
        Text("Quick inquiry", style: AppTypography.textXS.copyWith(color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => Center(
              child: GestureDetector(
                onTap: () => _handleSend(actions[index]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: Text(actions[index], style: AppTypography.textSM.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// WIDGET: _BUILDPILLINPUTBAR - THANH NHẬP LIỆU DẠNG VIÊN THUỐC (PILL)
  /// -------------------------------------------------------------------------
  Widget _buildPillInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 34),
      color: const Color(0xFFF7F8FA),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(35)),
        child: Row(
          children: [
            // Nút Camera nhanh
            Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20)
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: (v) => setState(() => _isWriting = v.isNotEmpty),
                onSubmitted: _handleSend,
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Chat...", isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              ),
            ),
            // Hiển thị nút Gửi nếu đang nhập, ngược lại hiển thị các icon chức năng khác
            if (_isWriting)
              IconButton(icon: const Icon(Icons.send, color: AppColors.primary), onPressed: () => _handleSend(_messageController.text))
            else ...[
              _buildInputIcon(Icons.mic_none_outlined, AppColors.neutral950),
              _buildInputIcon(Icons.image_outlined, AppColors.neutral950),
              _buildInputIcon(Icons.sentiment_satisfied_alt_outlined, AppColors.neutral950),
              _buildInputIcon(Icons.add_circle_outline, AppColors.neutral950),
            ],
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // Hàm tạo Icon cho thanh Input Bar
  Widget _buildInputIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, color: color, size: 24),
    );
  }
}