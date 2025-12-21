import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/service_model.dart';
import '../../models/nail_model.dart';
import '../../models/store_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../ar/home.dart';
import '../detail/nail_detail_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final Service service;
  final Store? store;
  const ServiceDetailsScreen({super.key, required this.service, this.store});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final PageController _aiPageController = PageController();
  int _currentAIIndex = 0;
  bool isFavorite = false;
  List<Nail> relatedNails = [];
  String priceRange = "Calculating...";

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _fetchNailsAndPrices();
  }

  // 1. LOGIC TÍNH GIÁ $MIN - $MAX TỪ COLLECTION NAILS
  Future<void> _fetchNailsAndPrices() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('nails')
        .where('tags', arrayContains: widget.service.name)
        .get();

    final nails = snapshot.docs.map((doc) => Nail.fromFirestore(doc)).toList();

    if (nails.isNotEmpty) {
      final prices = nails.map((n) => n.price).toList();
      final min = prices.reduce((a, b) => a < b ? a : b);
      final max = prices.reduce((a, b) => a > b ? a : b);
      setState(() {
        relatedNails = nails;
        priceRange = "\$$min - \$$max";
      });
    } else {
      setState(() { priceRange = "\$${widget.service.price}"; });
    }
  }

  // 2. LOGIC ĐỒNG BỘ YÊU THÍCH VỚI PROFILE
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
      await ref.set({'service_ids': FieldValue.arrayUnion([widget.service.id])}, SetOptions(merge: true));
    } else {
      await ref.update({'service_ids': FieldValue.arrayRemove([widget.service.id])});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildPremiumHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfo(),
                  const SizedBox(height: 24),
                  _buildAIBannerSection(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Gallery Designs"),
                  const SizedBox(height: 16),
                  _buildNailGallery(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      elevation: 0,
      leading: _buildCircleAction(Icons.arrow_back, () => Navigator.pop(context)),
      actions: [
        _buildCircleAction(Icons.share_outlined, () {}),
        const SizedBox(width: 12),
        _buildCircleAction(isFavorite ? Icons.favorite : Icons.favorite_border, _toggleFavorite, iconColor: isFavorite ? Colors.red : Colors.black87),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildSmartImage(widget.service.imageUrl ?? ''), // Sửa lỗi X đỏ
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.white.withOpacity(0.9)]))),
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

  // BANNER AI TRY-ON THEO ẢNH 3: 3 ẢNH & INDICATOR
  final List<String> aiBannerImages = [
    "assets/images/AI_1.png",
    "assets/images/AI_2.png",
    "assets/images/AI_3.png",
  ];

  Widget _buildAIBannerSection() {
    return Column(
      children: [
        SizedBox(
          height: 160, // Tăng nhẹ chiều cao để ảnh đẹp hơn
          child: PageView.builder(
            controller: _aiPageController,
            onPageChanged: (index) => setState(() => _currentAIIndex = index),
            itemCount: aiBannerImages.length,
            // TRUYỀN đường dẫn ảnh vào hàm build item
            itemBuilder: (context, index) => _buildBannerItem(aiBannerImages[index]),
          ),
        ),
        const SizedBox(height: 12),
        // THANH CHỈ BÁO (DOTS)
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

  // THÊM tham số String imagePath vào đây
  Widget _buildBannerItem(String imagePath) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArNailTryOnPage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // THÊM ẢNH NỀN VÀO ĐÂY
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Container(
          // Lớp phủ Gradient để chữ AI Try-on luôn rõ nét
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 42),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "AI Try-on",
                    style: AppTypography.labelLG.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    "Virtual experience",
                    style: AppTypography.textXS.copyWith(color: Colors.white.withOpacity(0.8)),
                  ),
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

  Widget _buildNailGallery() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.72),
      itemCount: relatedNails.length,
      itemBuilder: (context, index) {
        final nail = relatedNails[index];
        return InkWell(
          // FIX LỖI (image_cde10f.png): Truyền cả object nail thay vì chỉ ID
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NailDetailScreen(nail: nail, store: widget.store))),
          child: _buildNailCard(nail),
        );
      },
    );
  }

  Widget _buildNailCard(Nail nail) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Stack(children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), child: _buildSmartImage(nail.imgUrl)), Positioned(top: 12, right: 12, child: CircleAvatar(radius: 14, backgroundColor: Colors.white.withOpacity(0.8), child: const Icon(Icons.favorite_border, size: 16, color: Colors.grey))), Positioned(bottom: 12, right: 12, child: CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: const Icon(Icons.add, size: 18, color: Colors.white)))] )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nail.name, style: AppTypography.textXS.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text("Nail Haven Studio", style: AppTypography.textXS.copyWith(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("\$${nail.price}", style: AppTypography.textSM.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)), Row(children: [const Icon(Icons.favorite, color: Colors.grey, size: 12), const SizedBox(width: 4), Text("${nail.likes}", style: AppTypography.textXS.copyWith(color: Colors.grey))])]),
              ],
            ),
          )
        ],
      ),
    );
  }

  // HÀM XỬ LÝ ẢNH THÔNG MINH ĐỂ KHÔNG BỊ CRASH
  Widget _buildSmartImage(String path) {
    if (path.isEmpty) return Container(color: Colors.grey[100], child: const Icon(Icons.broken_image));
    if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image));
    return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
  }

  Widget _buildSectionTitle(String title) => Text(title, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w900));

  Widget _buildCircleAction(IconData icon, VoidCallback onTap, {Color iconColor = Colors.black87}) => Center(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle), child: Icon(icon, size: 20, color: iconColor))));
}