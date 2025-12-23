import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/service_model.dart'; // Model chứa thông tin dịch vụ (manicure, gel...)
import '../../models/nail_model.dart';    // Model chứa các mẫu thiết kế móng cụ thể
import '../../models/store_model.dart';   // Model chứa thông tin tiệm (để truyền tiếp khi đặt lịch)
import '../../theme/app_colors.dart';    // Hệ thống bảng màu hồng chủ đạo của Pionails
import '../../theme/app_typography.dart';// Hệ thống font chữ (headline, label, text)
import '../ar/home.dart';                // Trang thực tế ảo AR Try-on [cite: 26]
import '../detail/nail_detail_screen.dart'; // Trang chi tiết mẫu móng

/// ===========================================================================
/// CLASS SERVICEDETAILSSCREEN: CHI TIẾT DỊCH VỤ (VÍ DỤ: GEL POLISH, NAIL ART)
/// ===========================================================================
/// Trang này thực hiện 3 nhiệm vụ chính:
/// 1. Hiển thị thông tin mô tả và thời gian thực hiện dịch vụ.
/// 2. Tự động tính toán khoảng giá ($Min - $Max) dựa trên các mẫu móng có tag dịch vụ này.
/// 3. Cung cấp lối tắt đến công nghệ AR Try-on và các mẫu thiết kế gợi ý.
class ServiceDetailsScreen extends StatefulWidget {
  final Service service;
  final Store? store;
  const ServiceDetailsScreen({super.key, required this.service, this.store});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final PageController _aiPageController = PageController();
  int _currentAIIndex = 0; // Theo dõi chỉ số ảnh trong Banner AI
  bool isFavorite = false; // Trạng thái yêu thích của dịch vụ
  List<Nail> relatedNails = []; // Danh sách các mẫu móng thuộc dịch vụ này
  String priceRange = "Calculating..."; // Khoảng giá hiển thị động

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus(); // Kiểm tra trạng thái yêu thích từ Firestore
    _fetchNailsAndPrices(); // Truy vấn các mẫu móng liên quan để tính giá
  }

  /// -------------------------------------------------------------------------
  /// LOGIC 1: TRUY VẤN MẪU MÓNG VÀ TÍNH GIÁ ĐỘNG ($MIN - $MAX)
  /// -------------------------------------------------------------------------
  /// Hệ thống sẽ tìm trong collection 'nails' các mẫu móng có tag trùng với
  /// tên dịch vụ hiện tại để tính toán khoảng giá thấp nhất và cao nhất.
  Future<void> _fetchNailsAndPrices() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('nails')
        .where('tags', arrayContains: widget.service.name) // Lọc mẫu móng theo tag [cite: 88]
        .get();

    final nails = snapshot.docs.map((doc) => Nail.fromFirestore(doc)).toList();

    if (nails.isNotEmpty) {
      final prices = nails.map((n) => n.price).toList();
      final min = prices.reduce((a, b) => a < b ? a : b); // Tìm giá thấp nhất
      final max = prices.reduce((a, b) => a > b ? a : b); // Tìm giá cao nhất
      setState(() {
        relatedNails = nails;
        priceRange = "\$${min.toStringAsFixed(2)} - \$${max.toStringAsFixed(2)}";
      });
    } else {
      // Nếu không có mẫu móng nào, hiển thị giá cơ bản của dịch vụ
      setState(() { priceRange = "\$${widget.service.price.toStringAsFixed(2)}"; });
    }
  }

  /// -------------------------------------------------------------------------
  /// LOGIC 2: QUẢN LÝ YÊU THÍCH (USER_FAVORITES)
  /// -------------------------------------------------------------------------
  /// Đồng bộ hóa trạng thái yêu thích với collection 'user_favorites' của User[cite: 117].
  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('user_favorites').doc(user.uid).get();
    if (doc.exists) {
      List favs = doc.data()?['service_ids'] ?? [];
      setState(() => isFavorite = favs.contains(widget.service.id));
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('user_favorites').doc(user.uid);

    setState(() => isFavorite = !isFavorite);

    if (isFavorite) {
      // Thêm vào danh sách yêu thích dùng arrayUnion để tránh trùng lặp [cite: 218]
      await ref.set({'service_ids': FieldValue.arrayUnion([widget.service.id])}, SetOptions(merge: true));
    } else {
      // Xóa khỏi danh sách yêu thích
      await ref.update({'service_ids': FieldValue.arrayRemove([widget.service.id])});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildPremiumHeader(), // Phần Header ảnh lớn thu gọn (SliverAppBar)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfo(), // Thông tin tên, giá, mô tả dịch vụ
                  const SizedBox(height: 24),
                  _buildAIBannerSection(), // Banner quảng bá công nghệ AI Try-on [cite: 26]
                  const SizedBox(height: 32),
                  _buildSectionTitle("Gallery Designs"), // Tiêu đề mục các mẫu móng gợi ý
                  const SizedBox(height: 16),
                  _buildNailGallery(), // Grid hiển thị các mẫu móng thực tế
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// GIAO DIỆN HEADER VỚI HIỆU ỨNG GRADIENT
  /// -------------------------------------------------------------------------
  Widget _buildPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: _buildCircleAction(Icons.arrow_back, () => Navigator.pop(context)),
      actions: [
        _buildCircleAction(Icons.share_outlined, () {}),
        const SizedBox(width: 12),
        _buildCircleAction(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            _toggleFavorite,
            iconColor: isFavorite ? Colors.red : Colors.black87
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildSmartImage(widget.service.imageUrl ?? ''), // Hiển thị ảnh dịch vụ
            // Lớp phủ Gradient để tạo độ tương phản cho các nút bấm phía trên
            Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.white.withOpacity(0.9)]
                    )
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(widget.service.name, style: AppTypography.headlineXL.copyWith(fontWeight: FontWeight.w900))),
            Text(priceRange, style: AppTypography.headlineSM.copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.grey), const SizedBox(width: 4), Text("${widget.service.duration} mins", style: AppTypography.textSM.copyWith(color: Colors.grey))]),
        const SizedBox(height: 24),
        _buildSectionTitle("About this service"),
        const SizedBox(height: 8),
        Text(widget.service.description, style: AppTypography.textSM.copyWith(color: Colors.black54, height: 1.6)),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// BANNER AI TRY-ON: QUẢNG BÁ TRẢI NGHIỆM THỰC TẾ ẢO
  /// -------------------------------------------------------------------------
  final List<String> aiBannerImages = [
    "assets/images/AI_1.png",
    "assets/images/AI_2.png",
    "assets/images/AI_3.png",
  ];

  Widget _buildAIBannerSection() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _aiPageController,
            onPageChanged: (index) => setState(() => _currentAIIndex = index),
            itemCount: aiBannerImages.length,
            itemBuilder: (context, index) => _buildBannerItem(aiBannerImages[index]),
          ),
        ),
        const SizedBox(height: 12),
        // THANH CHỈ BÁO VỊ TRÍ (INDICATOR DOTS)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(aiBannerImages.length, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            width: _currentAIIndex == index ? 22 : 8,
            decoration: BoxDecoration(
              color: _currentAIIndex == index ? AppColors.primary : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildBannerItem(String imagePath) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArNailTryOnPage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.black.withOpacity(0.5), Colors.transparent]),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 42),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("AI Try-on", style: AppTypography.labelLG.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  Text("Virtual experience", style: AppTypography.textXS.copyWith(color: Colors.white.withOpacity(0.8))),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// GRID HIỂN THỊ CÁC MẪU MÓNG LIÊN QUAN (NAIL GALLERY)
  /// -------------------------------------------------------------------------
  Widget _buildNailGallery() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.72
      ),
      itemCount: relatedNails.length,
      itemBuilder: (context, index) {
        final nail = relatedNails[index];
        return InkWell(
          // Chuyển sang chi tiết mẫu móng khi nhấn vào Card
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NailDetailScreen(nail: nail, store: widget.store))),
          child: _buildNailCard(nail),
        );
      },
    );
  }

  Widget _buildNailCard(Nail nail) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Stack(
                  children: [
                    ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), child: _buildSmartImage(nail.imgUrl)),
                    Positioned(top: 12, right: 12, child: CircleAvatar(radius: 14, backgroundColor: Colors.white.withOpacity(0.8), child: const Icon(Icons.favorite_border, size: 16, color: Colors.grey))),
                    Positioned(bottom: 12, right: 12, child: CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: const Icon(Icons.add, size: 18, color: Colors.white))),
                  ]
              )
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nail.name, style: AppTypography.textXS.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text("Nail Haven Studio", style: AppTypography.textXS.copyWith(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("\$${nail.price}", style: AppTypography.textSM.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Row(children: [const Icon(Icons.favorite, color: Colors.grey, size: 12), const SizedBox(width: 4), Text("${nail.likes}", style: AppTypography.textXS.copyWith(color: Colors.grey))])
                    ]
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// HÀM TRỢ GIÚP: XỬ LÝ ẢNH THÔNG MINH VÀ NÚT BẤM TRÒN
  /// -------------------------------------------------------------------------
  Widget _buildSmartImage(String path) {
    if (path.isEmpty) return Container(color: Colors.grey[100], child: const Icon(Icons.broken_image));
    if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image));
    return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
  }

  Widget _buildSectionTitle(String title) => Text(title, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w900));

  Widget _buildCircleAction(IconData icon, VoidCallback onTap, {Color iconColor = Colors.black87}) =>
      Center(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle), child: Icon(icon, size: 20, color: iconColor))));
}