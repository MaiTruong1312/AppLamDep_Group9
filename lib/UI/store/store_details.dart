import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:applamdep/providers/store_provider.dart'; // Quản lý dữ liệu tiệm toàn cục
import '../../models/store_model.dart';
import '../../models/review_model.dart';
import '../../models/service_model.dart';
import '../../theme/app_colors.dart'; // Bảng màu thương hiệu
import '../../theme/app_typography.dart'; // Hệ thống kiểu chữ
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import các Tab con để hiển thị trong TabBarView
import 'store_tab_most_service.dart';
import 'store_tab_review.dart';
import 'store_tab_portfolio.dart';
import 'store_tab_giftcard.dart';
import 'store_tab_location.dart';
import 'chat_screen.dart';
import 'service_details.dart';
import 'flashsale_detail.dart';

/// ===========================================================================
/// CLASS STOREDETAILS: MÀN HÌNH CHI TIẾT CỦA MỘT CỬA HÀNG CỤ THỂ
/// ===========================================================================
/// Sử dụng NestedScrollView để tạo hiệu ứng cuộn mượt mà: Ảnh bìa sẽ thu nhỏ
/// khi cuộn lên và TabBar sẽ được giữ cố định (Sticky Header).
class StoreDetails extends StatefulWidget {
  final String storeId; // Nhận ID tiệm để truy vấn dữ liệu từ Firestore
  const StoreDetails({super.key, required this.storeId});

  @override
  State<StoreDetails> createState() => _StoreDetailsState();
}

class _StoreDetailsState extends State<StoreDetails> {
  final ScrollController _scrollController = ScrollController();
  Timer? _flashSaleTimer; // Bộ đếm thời gian cho Flashsale
  Duration _remainingTime = const Duration(hours: 20, minutes: 0, seconds: 0); // Thời gian giả định
  final PageController _headerPageController = PageController();
  int _currentImageIndex = 0; // Theo dõi vị trí ảnh hiện tại trên Header

  bool isFavorite = false; // Trạng thái yêu thích (Lưu vào wishlist_store)
  bool isFavoriteLoading = false; // Trạng thái chờ khi đang thực hiện lưu/xóa
  bool _isFollowed = false; // Trạng thái theo dõi tiệm (Follow)

  /// -------------------------------------------------------------------------
  /// HÀM INITSTATE: KHỞI TẠO DỮ LIỆU KHI VÀO TRANG
  /// -------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _startCountdown(); // Bắt đầu chạy bộ đếm ngược
    _checkFavoriteStatus(); // Kiểm tra xem tiệm này đã được user yêu thích chưa

    // Gọi Provider để fetch thông tin chi tiết tiệm từ Firebase
    Future.microtask(() =>
        Provider.of<StoreProvider>(context, listen: false).fetchStore(widget.storeId));
  }

  /// -------------------------------------------------------------------------
  /// LOGIC 1: QUẢN LÝ TRẠNG THÁI YÊU THÍCH (WISHLIST)
  /// -------------------------------------------------------------------------

  // Kiểm tra tiệm đã nằm trong danh sách yêu thích của User hiện tại chưa
  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wishlist_store')
          .where('user_id', isEqualTo: user.uid)
          .where('store_id', isEqualTo: widget.storeId)
          .get();

      if (mounted) {
        setState(() => isFavorite = snapshot.docs.isNotEmpty);
      }
    } catch (e) {
      debugPrint("Lỗi kiểm tra wishlist: $e");
    }
  }

  // Hàm xử lý việc Nhấn icon Trái tim: Thêm hoặc Xóa khỏi Firestore
  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để lưu tiệm yêu thích")),
      );
      return;
    }

    setState(() => isFavoriteLoading = true);
    final collectionRef = FirebaseFirestore.instance.collection('wishlist_store');

    try {
      if (isFavorite) {
        // Nếu đã yêu thích -> Thực hiện XÓA
        final snapshot = await collectionRef
            .where('user_id', isEqualTo: user.uid)
            .where('store_id', isEqualTo: widget.storeId)
            .get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } else {
        // Nếu chưa yêu thích -> Thực hiện THÊM MỚI
        await collectionRef.add({
          'user_id': user.uid,
          'store_id': widget.storeId,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      setState(() => isFavorite = !isFavorite);
    } catch (e) {
      debugPrint("Lỗi cập nhật wishlist: $e");
    } finally {
      setState(() => isFavoriteLoading = false);
    }
  }

  /// -------------------------------------------------------------------------
  /// LOGIC 2: CHIA SẺ VÀ ĐẾM NGƯỢC
  /// -------------------------------------------------------------------------

  void _shareStore(Store store) {
    debugPrint("Sharing store: ${store.name}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đang chuẩn bị link chia sẻ tiệm ${store.name}...")),
    );
  }

  // Khởi động Timer: Mỗi 1 giây sẽ trừ đi 1 giây trong bộ đếm
  void _startCountdown() {
    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        if (mounted) setState(() => _remainingTime -= const Duration(seconds: 1));
      } else {
        _flashSaleTimer?.cancel();
      }
    });
  }

  /// -------------------------------------------------------------------------
  /// LOGIC 3: CHỨC NĂNG THEO DÕI (FOLLOW)
  /// -------------------------------------------------------------------------

  void _toggleFollow() {
    setState(() => _isFollowed = !_isFollowed);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowed ? "You are now following this store!" : "Unfollowed."),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // Xây dựng nút Follow đồng bộ với tông màu App
  Widget _buildFollowButton() {
    return OutlinedButton(
      onPressed: _toggleFollow,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _isFollowed ? Colors.grey : AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: _isFollowed ? Colors.grey[100] : Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isFollowed ? Icons.check : Icons.add,
            size: 18,
            color: _isFollowed ? Colors.grey : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _isFollowed ? "Following" : "Follow",
            style: TextStyle(
              color: _isFollowed ? Colors.grey : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flashSaleTimer?.cancel(); // Hủy Timer để tránh rò rỉ bộ nhớ (Memory leak)
    _headerPageController.dispose();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// -------------------------------------------------------------------------
  /// HÀM BUILD CHÍNH: QUẢN LÝ TOÀN BỘ GIAO DIỆN
  /// -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        // HIỂN THỊ LOADING TRƯỚC KHI CÓ DỮ LIỆU
        if (provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }

        final store = provider.currentStore;
        // XỬ LÝ TRƯỜNG HỢP KHÔNG TÌM THẤY TIỆM
        if (store == null) return const Scaffold(body: Center(child: Text("Cửa hàng không tồn tại")));

        return Scaffold(
          backgroundColor: AppColors.white,
          body: DefaultTabController(
            length: 5,
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildAppBar(store), // 1. Ảnh bìa và các nút chức năng
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. TÊN TIỆM VÀ NÚT FOLLOW
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.name,
                                      style: AppTypography.headlineLG.copyWith(fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("Premium Beauty Salon", style: AppTypography.textXS.copyWith(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              _buildFollowButton(),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 3. DANH SÁCH DỊCH VỤ DƯỚI DẠNG GRID
                          _buildSectionTitle("Service Of ${store.name}"),
                          const SizedBox(height: 16),
                          _buildServiceGrid(store.services),
                          const SizedBox(height: 24),

                          // 4. LOGIC QUAN TRỌNG: CHỈ HIỂN THỊ FLASHSALE NẾU CÓ DỮ LIỆU
                          if (store.flashsales.isNotEmpty) ...[
                            _buildFlashsaleHeader(),
                            const SizedBox(height: 12),
                            _buildFlashsaleList(store.flashsales),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildStickyTabBar(), // 5. TabBar cố định khi cuộn
                ];
              },
              // PHẦN NỘI DUNG CỦA TỪNG TAB
              body: TabBarView(
                children: [
                  MostServiceTab(store: store),
                  ReviewsTab(store: store),
                  PortfolioTab(store: store),
                  const Center(child: Text("Giftcard is coming soon")),
                  LocationTab(store: store),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// CÁC THÀNH PHẦN GIAO DIỆN CON (WIDGETS)
  /// -------------------------------------------------------------------------

  // Xây dựng SliverAppBar chứa ảnh PageView và các nút Action
  SliverAppBar _buildAppBar(Store store) {
    final List<String> images = [store.imgUrl, store.imgUrl, store.imgUrl];
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildCircleAction(Icons.arrow_back, () => Navigator.pop(context)),
      ),
      actions: [
        _buildCircleAction(Icons.share_outlined, () => _shareStore(store)),
        const SizedBox(width: 8),
        _buildCircleAction(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          _toggleFavorite,
          iconColor: isFavorite ? Colors.red : Colors.white,
          isLoading: isFavoriteLoading,
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              child: PageView.builder(
                controller: _headerPageController,
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                itemCount: images.length,
                itemBuilder: (context, index) => _buildSmartImage(images[index]),
              ),
            ),
            _buildCustomIndicator(images.length),
            _buildContactButtons(store), // Các nút Chat, Call, Map
          ],
        ),
      ),
    );
  }

  // Widget nút tròn mờ trên AppBar
  Widget _buildCircleAction(IconData icon, VoidCallback onTap, {Color iconColor = Colors.white, bool isLoading = false}) {
    return Center(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  // Hiển thị thanh trượt chỉ báo ảnh (Dots indicator)
  Widget _buildCustomIndicator(int count) {
    return Positioned(
      bottom: 65,
      left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          bool isActive = _currentImageIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: isActive ? 28 : 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.black12,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  // Xây dựng Grid danh sách dịch vụ nhanh (Quick Services)
  Widget _buildServiceGrid(List<Service> services) {
    const Map<String, String> iconMapping = {
      "Nail Art": "assets/icons/nails.svg",
      "Gel Polish": "assets/icons/nails.svg",
      "Manicure": "assets/icons/facial.svg",
      "Medicure": "assets/icons/massage.svg",
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final iconPath = iconMapping[service.name];

        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailsScreen(service: service))),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20)),
                  child: Center(
                    child: iconPath != null
                        ? SvgPicture.asset(iconPath, colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn), width: 32)
                        : const Icon(Icons.spa, color: AppColors.primary, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(service.name, textAlign: TextAlign.center, maxLines: 1, style: AppTypography.textXS.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  // Xây dựng tiêu đề đếm ngược Flashsale
  Widget _buildFlashsaleHeader() {
    String hours = _twoDigits(_remainingTime.inHours);
    String minutes = _twoDigits(_remainingTime.inMinutes.remainder(60));
    String seconds = _twoDigits(_remainingTime.inSeconds.remainder(60));

    return Row(
      children: [
        Text("Flashsale", style: AppTypography.headlineSM),
        const Spacer(),
        Text("Closing in ", style: AppTypography.textXS),
        const SizedBox(width: 4),
        _buildTimeBox(hours), _buildTimeDivider(),
        _buildTimeBox(minutes), _buildTimeDivider(),
        _buildTimeBox(seconds),
      ],
    );
  }

  // Danh sách các mục Flashsale trượt ngang
  Widget _buildFlashsaleList(List<Flashsale> sales) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final sale = sales[index];
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => FlashSaleDetailScreen(flashsale: sale, initialRemainingTime: _remainingTime),
            )),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _buildSmartImage(sale.imageUrl)),
            ),
          );
        },
      ),
    );
  }

  // --- CÁC HÀM TRỢ GIÚP (HELPERS) ---

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTimeDivider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2),
    child: Text(":", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
  );

  Widget _buildSmartImage(String path) {
    if (path.isEmpty) return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
    if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover);
    return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
  }

  // Xây dựng bộ nút liên hệ: Chat, Call, Map
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
              DefaultTabController.of(innerContext).animateTo(4); // Chuyển Tab Map
              _scrollController.animateTo(280.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
            });
          }),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800));

  SliverPersistentHeader _buildStickyTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [Tab(text: 'Most Service'), Tab(text: 'Reviews'), Tab(text: 'Portfolio'), Tab(text: 'Giftcard'), Tab(text: 'Contact')],
        ),
      ),
    );
  }

  // Hiển thị BottomSheet khi nhấn nút Gọi hotline
  void _showHotlineBottomSheet(BuildContext context, String phoneNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.phone_forwarded_rounded, color: AppColors.primary, size: 32)),
            const SizedBox(height: 16),
            Text("Tap to call", style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(phoneNumber.isNotEmpty ? phoneNumber : "Not updated", style: AppTypography.headlineSM.copyWith(color: AppColors.primary, letterSpacing: 1.2)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: const Text("Call Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

/// LỚP ĐIỀU KHIỂN CHIỀU CAO TABBAR KHI CUỘN (SLIVER PERSISTENT HEADER)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(context, shrinkOffset, overlapsContent) => Container(color: Colors.white, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}