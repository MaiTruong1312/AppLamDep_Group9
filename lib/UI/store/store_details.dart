import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:applamdep/providers/store_provider.dart'; // Quản lý dữ liệu tiệm toàn cục
import '../../models/store_model.dart';
import '../../models/service_model.dart';
import '../../models/nail_model.dart';
import '../../theme/app_colors.dart'; // Bảng màu thương hiệu
import '../../theme/app_typography.dart'; // Hệ thống kiểu chữ
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_nail_collection.dart';

// Import các Tab con để hiển thị trong TabBarView
import 'store_tab_most_service.dart';
import 'store_tab_review.dart';
import 'store_tab_portfolio.dart';
import 'store_tab_location.dart';
import 'chat_screen.dart';
import 'service_details.dart';
import 'flashsale_detail.dart';
import '../detail/nail_detail_screen.dart';

/// ===========================================================================
/// CLASS STOREDETAILS: MÀN HÌNH CHI TIẾT CỦA MỘT CỬA HÀNG CỤ THỂ
/// ===========================================================================
class StoreDetails extends StatefulWidget {
  final String storeId;
  const StoreDetails({super.key, required this.storeId});

  @override
  State<StoreDetails> createState() => _StoreDetailsState();
}

class _StoreDetailsState extends State<StoreDetails> {
  final ScrollController _scrollController = ScrollController();
  Timer? _flashSaleTimer;
  Duration _remainingTime = const Duration(hours: 20, minutes: 0, seconds: 0);
  final PageController _headerPageController = PageController();
  int _currentImageIndex = 0;

  bool isFavorite = false;
  bool isFavoriteLoading = false;
  bool _isFollowed = false;
  bool _isFollowing = false;
  int _hoveredIndex = -1;

  // FIX NHÁY ẢNH: Khai báo biến Stream cố định
  Stream<QuerySnapshot>? _featuredNailsStream;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _checkFavoriteStatus();
    _checkFollowStatus();

    _featuredNailsStream = FirebaseFirestore.instance
        .collection('nails')
        .where('store_Ids', arrayContains: widget.storeId)
    // .orderBy('likes', descending: true)
        .limit(10)
        .snapshots();

    Future.microtask(() =>
        Provider.of<StoreProvider>(context, listen: false).fetchStore(widget.storeId));
  }

  // --- LOGIC 1: WISHLIST ---
  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wishlist_store')
          .where('user_id', isEqualTo: user.uid)
          .where('store_id', isEqualTo: widget.storeId)
          .get();
      if (mounted) setState(() => isFavorite = snapshot.docs.isNotEmpty);
    } catch (e) {
      debugPrint("Lỗi kiểm tra wishlist: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập")));
      return;
    }
    setState(() => isFavoriteLoading = true);
    final ref = FirebaseFirestore.instance.collection('wishlist_store');
    try {
      if (isFavorite) {
        final snap = await ref.where('user_id', isEqualTo: user.uid).where('store_id', isEqualTo: widget.storeId).get();
        for (var doc in snap.docs) await doc.reference.delete();
      } else {
        await ref.add({'user_id': user.uid, 'store_id': widget.storeId, 'created_at': FieldValue.serverTimestamp()});
      }
      setState(() => isFavorite = !isFavorite);
    } catch (e) {
      debugPrint("Lỗi cập nhật wishlist: $e");
    } finally {
      setState(() => isFavoriteLoading = false);
    }
  }

  // --- LOGIC 2: ĐẾM NGƯỢC ---
  void _startCountdown() {
    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        if (mounted) setState(() => _remainingTime -= const Duration(seconds: 1));
      } else {
        _flashSaleTimer?.cancel();
      }
    });
  }

  // 1. Kiểm tra xem người dùng đã follow tiệm này chưa khi vừa mở trang
  Future<void> _checkFollowStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('follows_store')
          .where('user_id', isEqualTo: user.uid)
          .where('store_id', isEqualTo: widget.storeId)
          .get();
      if (mounted) setState(() => _isFollowed = snapshot.docs.isNotEmpty);
    } catch (e) {
      debugPrint("Error checking follow status: $e");
    }
  }

// 2. Thực hiện Follow hoặc Unfollow và lưu lên server
  Future<void> _toggleFollow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to follow")));
      return;
    }

    setState(() => _isFollowing = true); // Bắt đầu loading
    final ref = FirebaseFirestore.instance.collection('follows_store');

    try {
      if (_isFollowed) {
        // Nếu đã follow rồi -> Xóa khỏi database (Unfollow)
        final snap = await ref.where('user_id', isEqualTo: user.uid).where('store_id', isEqualTo: widget.storeId).get();
        for (var doc in snap.docs) await doc.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unfollowed successfully")));
      } else {
        // Nếu chưa follow -> Thêm vào database
        await ref.add({
          'user_id': user.uid,
          'store_id': widget.storeId,
          'followed_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Followed successfully")));
      }
      setState(() => _isFollowed = !_isFollowed); // Toggle trạng thái sau thành công
    } catch (e) {
      debugPrint("Error updating follow: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isFollowing = false); // Kết thúc loading
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flashSaleTimer?.cancel();
    _headerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        // BƯỚC 1: KIỂM TRA TRẠNG THÁI TẢI DỮ LIỆU TRƯỚC
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final store = provider.currentStore;
        if (store == null) {
          return const Scaffold(
            body: Center(child: Text("Store not found")),
          );
        }

        // BƯỚC 2: CHỈ BẮT ĐẦU ANIMATION KHI ĐÃ CÓ DỮ LIỆU
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic, // Thêm curve để hiệu ứng "bay" mượt mà hơn
          builder: (context, value, child) {
            return Opacity(
              opacity: value, // Hiệu ứng mờ dần (Fade-in)
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)), // Hiệu ứng bay nhẹ từ dưới lên (30px)
                child: child,
              ),
            );
          },
          // BƯỚC 3: ĐƯA TOÀN BỘ UI VÀO BIẾN CHILD CỦA TWEENANIMATIONBUILDER
          child: Scaffold(
            backgroundColor: AppColors.white,
            body: DefaultTabController(
              length: 4, // Đã bỏ Giftcard
              child: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _buildAppBar(store),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildStoreHeader(store),
                            const SizedBox(height: 24),
                            _buildSectionHeader("Featured Designs", () => _navigateToCollection(store)),
                            const SizedBox(height: 8),
                            _buildFeaturedCollection(store), // Bộ sưu tập Nail
                            const SizedBox(height: 16),
                            _buildSectionHeader("Quick Services", null),
                            const SizedBox(height: 8),
                            _buildServiceGrid(store.services, store),
                            const SizedBox(height: 16),
                            // Chỉ hiển thị Flashsale nếu danh sách không rỗng
                            if (store.flashsales.isNotEmpty) ...[
                              _buildFlashsaleHeader(),
                              const SizedBox(height: 16),
                              _buildFlashsaleList(store.flashsales),
                              const SizedBox(height: 0),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildStickyTabBar(), // TabBar dính trên đỉnh khi cuộn
                  ];
                },
                body: TabBarView(
                  children: [
                    MostServiceTab(store: store),
                    ReviewsTab(store: store),
                    PortfolioTab(store: store),
                    LocationTab(store: store),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildStoreHeader(Store store) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PHẦN MỚI: ICON VÀ TÊN TIỆM ---
              Row(
                children: [
                  const Icon(
                    Icons.store_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 8), // Khoảng cách giữa icon và text

                  Expanded(
                    child: Text(
                      store.name,
                      style: AppTypography.headlineLG.copyWith(fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Mô tả ngắn dưới tên tiệm
              Text(
                "Premium Beauty Salon",
                style: AppTypography.textXS.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        _buildFollowButton(), // Nút Follow bên phải
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedCollection(Store store) {
    return SizedBox(
      height: 150,
      child: StreamBuilder<QuerySnapshot>(
        stream: _featuredNailsStream, // Dùng stream cố định để ảnh không bị nháy
        builder: (context, snapshot) {
          // Chỉ hiện vòng xoay nếu thực sự chưa có dữ liệu nào
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

          final nails = snapshot.data!.docs.map((doc) => Nail.fromFirestore(doc)).toList();
          return ListView.builder(
            key: const PageStorageKey('featured_nails'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: nails.length,
            itemBuilder: (context, index) => _buildCollectionItem(nails[index], store, index),
          );
        },
      ),
    );
  }

  Widget _buildCollectionItem(Nail nail, Store store, int index) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hoveredIndex = index), // Khi chạm vào: gán index
      onTapCancel: () => setState(() => _hoveredIndex = -1),  // Khi trượt ra ngoài: reset
      onTapUp: (_) => setState(() => _hoveredIndex = -1),      // Khi nhấc tay: reset
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => NailDetailScreen(nail: nail, store: store)
      )),
      // GIẢI PHÁP: Dùng AnimatedScale bọc ngoài Container
      child: AnimatedScale(
        scale: _hoveredIndex == index ? 0.95 : 1.0, // Thu nhỏ 5% khi nhấn
        duration: const Duration(milliseconds: 150), // Thời gian chuyển động
        curve: Curves.easeInOut,
        child: Container(
          width: 110,
          margin: const EdgeInsets.only(right: 12, bottom: 8, top: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                // Dùng withValues thay cho withOpacity để tránh cảnh báo lỗi thời
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6)
              )
            ],
          ),
          child: Column(
            children: [
              // Ảnh phía trên
              Expanded(
                  child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: Hero(tag: nail.id, child: _buildSmartImage(nail.imgUrl))
                  )
              ),
              // Tên móng phía dưới
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                      nail.name,
                      style: AppTypography.textXS.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildServiceGrid(List<Service> services, Store store) {
    const Map<String, String> iconMapping = {
      "Nail Art": "assets/icons/nails.svg", "Gel Polish": "assets/icons/nails.svg", "Manicure": "assets/icons/facial.svg", "Medicure": "assets/icons/massage.svg",
    };
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final iconPath = iconMapping[service.name];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailsScreen(service: service, store: store))),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 2, top: 2, bottom: 2),
              child: Column(
                children: [
                  Container(
                    width: 65, height: 65,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Center(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle), child: iconPath != null ? SvgPicture.asset(iconPath, colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn), width: 22) : const Icon(Icons.spa_rounded, color: AppColors.primary, size: 22))),
                  ),
                  const SizedBox(height: 8),
                  Text(service.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.textXS.copyWith(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 10.5)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(Store store) {
    final List<String> images = [store.imgUrl, store.imgUrl, store.imgUrl];
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: _buildCircleAction(Icons.arrow_back, () => Navigator.pop(context))),
      actions: [
        _buildCircleAction(Icons.share_outlined, () {}),
        const SizedBox(width: 8),
        _buildCircleAction(isFavorite ? Icons.favorite : Icons.favorite_border, _toggleFavorite, iconColor: isFavorite ? Colors.red : Colors.white, isLoading: isFavoriteLoading),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)), child: PageView.builder(controller: _headerPageController, onPageChanged: (index) => setState(() => _currentImageIndex = index), itemCount: images.length, itemBuilder: (context, index) => _buildSmartImage(images[index]))),
            _buildCustomIndicator(images.length),
            _buildContactButtons(store),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButtons(Store store) {
    return Positioned(
      bottom: 15,
      left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconButton(Icons.chat_bubble_outline, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(storeId: store.id, storeName: store.name)));
          }),
          const SizedBox(width: 16),
          _buildIconButton(Icons.phone_outlined, () => _showHotlineBottomSheet(context, store.hotline)),
          const SizedBox(width: 16),
          Builder(builder: (innerContext) {
            return _buildIconButton(Icons.location_on_outlined, () {
              // FIX ĐIỀU HƯỚNG: Chuyển Tab Contact (Index 3 vì đã xóa Giftcard)
              DefaultTabController.of(innerContext).animateTo(3);
              _scrollController.animateTo(280.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
            });
          }),
        ],
      ),
    );
  }

  // --- HELPERS ---

  // --- HÀM BUILD NÚT FOLLOW  ---
  Widget _buildFollowButton() {
    return OutlinedButton(
      // FIX 1: Nút chỉ bị khóa khi đang trong quá trình gửi dữ liệu (loading)
      // Không được khóa khi đã Follow để người dùng còn có thể Unfollow
      onPressed: _isFollowing ? null : _toggleFollow,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _isFollowed ? Colors.grey : AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: _isFollowed ? Colors.grey[100] : Colors.white,
      ),
      // FIX 2: Chỉ hiện vòng xoay khi biến _isFollowing (loading) là TRUE
      child: _isFollowing
          ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hiện Icon check nếu đã Follow, icon cộng nếu chưa
          Icon(
              _isFollowed ? Icons.check : Icons.add,
              size: 18,
              color: _isFollowed ? Colors.grey : AppColors.primary
          ),
          const SizedBox(width: 8),
          // Hiện chữ tương ứng với trạng thái lưu trên Firebase
          Text(
              _isFollowed ? "Following" : "Follow",
              style: TextStyle(
                  color: _isFollowed ? Colors.grey : AppColors.primary,
                  fontWeight: FontWeight.bold
              )
          ),
        ],
      ),
    );
  }
  Widget _buildCircleAction(IconData icon, VoidCallback onTap, {Color iconColor = Colors.white, bool isLoading = false}) {
    return Center(child: GestureDetector(onTap: isLoading ? null : onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle), child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, color: iconColor, size: 20))));
  }

  Widget _buildCustomIndicator(int count) {
    return Positioned(bottom: 65, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(count, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 6, width: _currentImageIndex == index ? 28 : 8, decoration: BoxDecoration(color: _currentImageIndex == index ? AppColors.primary : Colors.black12, borderRadius: BorderRadius.circular(3))))));
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]), child: Icon(icon, color: AppColors.primary, size: 22)));
  }

  Widget _buildSmartImage(String path) {
    if (path.isEmpty) return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
    if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover);
    return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
  }

  SliverPersistentHeader _buildStickyTabBar() {
    return SliverPersistentHeader(pinned: true, delegate: _SliverAppBarDelegate(const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, labelColor: AppColors.primary, unselectedLabelColor: Colors.grey, indicatorColor: AppColors.primary, tabs: [Tab(text: 'Most Service'), Tab(text: 'Reviews'), Tab(text: 'Portfolio'), Tab(text: 'Contact')])));
  }

  void _navigateToCollection(Store store) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => StoreNailCollectionScreen(store: store)));
  }

  Widget _buildFlashsaleHeader() {
    String h = _remainingTime.inHours.toString().padLeft(2, '0');
    String m = _remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    String s = _remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(children: [Text("Flashsale", style: AppTypography.headlineSM), const Spacer(), Text("Closing in ", style: AppTypography.textXS), const SizedBox(width: 4), _buildTimeBox(h), _buildTimeDivider(), _buildTimeBox(m), _buildTimeDivider(), _buildTimeBox(s)]);
  }

  Widget _buildTimeBox(String v) => Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)), child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)));
  Widget _buildTimeDivider() => const Text(" : ", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold));

  Widget _buildFlashsaleList(List<Flashsale> sales) {
    return SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: sales.length, itemBuilder: (context, index) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FlashSaleDetailScreen(flashsale: sales[index], initialRemainingTime: _remainingTime))), child: Container(width: 110, margin: const EdgeInsets.only(right: 12, bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _buildSmartImage(sales[index].imageUrl))))));
  }

  void _showHotlineBottomSheet(BuildContext context, String phone) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))), const SizedBox(height: 24), Text("Tap to call", style: AppTypography.labelLG), const SizedBox(height: 8), Text(phone.isNotEmpty ? phone : "Not updated", style: AppTypography.headlineSM.copyWith(color: AppColors.primary)), const SizedBox(height: 32), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("Call Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(height: 12), TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey)))])));
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(context, shrinkOffset, overlapsContent) => Container(color: Colors.white, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}