import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:applamdep/providers/store_provider.dart';
import '../../models/store_model.dart';
import '../../models/review_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreDetails extends StatefulWidget {
  final String storeId;
  const StoreDetails({super.key, required this.storeId});

  @override
  State<StoreDetails> createState() => _StoreDetailsState();
}

class _StoreDetailsState extends State<StoreDetails> {
  Timer? _flashSaleTimer;
  Duration _remainingTime = const Duration(hours: 20, minutes: 0, seconds: 0);
  final PageController _headerPageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    Future.microtask(() =>
        Provider.of<StoreProvider>(context, listen: false).fetchStore(widget.storeId));
  }

  void _startCountdown() {
    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() => _remainingTime -= const Duration(seconds: 1));
      } else {
        _flashSaleTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _flashSaleTimer?.cancel();
    _headerPageController.dispose();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        final store = provider.currentStore;
        if (store == null) return const Scaffold(body: Center(child: Text("Cửa hàng không tồn tại")));

        return Scaffold(
          backgroundColor: AppColors.white,
          body: DefaultTabController(
            length: 5,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildAppBar(store),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Service Of ${store.name}"),
                          const SizedBox(height: 16),
                          // ĐÃ SỬA: Dùng store.services (số nhiều) đúng với model
                          _buildServiceGrid(store.services),
                          const SizedBox(height: 24),
                          _buildFlashsaleHeader(),
                          const SizedBox(height: 12),
                          _buildFlashsaleList(store.flashsales),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  _buildStickyTabBar(),
                ];
              },
              body: TabBarView(
                children: [
                  _buildMostServiceTab(store),
                  _buildReviewsTab(store),
                  _buildPortfolioTab(store),
                  const Center(child: Text("Giftcard Content")),
                  _buildLocationTab(store),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI COMPONENTS ---

  SliverAppBar _buildAppBar(Store store) {
    final List<String> images = [store.imgUrl, store.imgUrl, store.imgUrl];
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: const BackButton(color: Colors.white),
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
            _buildContactButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomIndicator(int count) {
    return Positioned(
      bottom: 65,
      left: 0,
      right: 0,
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

  Widget _buildServiceGrid(List<Service> services) {
    const Map<String, String> iconMapping = {
      "Hair Removal": "assets/icons/hair_removal.svg",
      "Hair Cut": "assets/icons/hair_cut.svg",
      "Hair Style": "assets/icons/hair_style.svg",
      "Facial": "assets/icons/facial.svg",
      "Massage": "assets/icons/massage.svg",
      "Nails": "assets/icons/nails.svg",
      "Makeup": "assets/icons/makeup.svg",
      "Med Spa": "assets/icons/med_spa.svg",
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: 0.76, // Tỷ lệ chuẩn 70x92
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        // ĐÃ SỬA: Lấy đúng thuộc tính từ object Service
        final service = services[index];
        final iconPath = iconMapping[service.name];

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: iconPath != null
                  ? SvgPicture.asset(iconPath, colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn), width: 30, height: 30)
                  : const Icon(Icons.spa, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              service.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSM.copyWith(fontWeight: FontWeight.w600, color: AppColors.neutral950),
            ),
          ],
        );
      },
    );
  }

  // --- FLASH SALE & TABS ---

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
        _buildTimeBox(hours),
        _buildTimeDivider(),
        _buildTimeBox(minutes),
        _buildTimeDivider(),
        _buildTimeBox(seconds),
      ],
    );
  }

  Widget _buildFlashsaleList(List<Flashsale> sales) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sales.length,
        itemBuilder: (context, index) => Container(
          width: 110,
          margin: const EdgeInsets.only(right: 12, bottom: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildSmartImage(sales[index].imageUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildMostServiceTab(Store store) {
    return Column(
      children: [
        // THANH TÌM KIẾM
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), // Màu xám nhạt chuẩn thiết kế
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search services, salons...",
                hintStyle: AppTypography.textSM.copyWith(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // DANH SÁCH DỊCH VỤ
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: store.services.length,
            itemBuilder: (context, index) {
              final service = store.services[index];
              return _buildServiceCard(service);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: _buildSmartImage(service.imageUrl),
              )
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: AppTypography.textMD.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Premium beauty service with quality care.", style: AppTypography.textSM.copyWith(color: Colors.grey)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(" ${service.rating} - ${service.bookings}+ bookings", style: AppTypography.textXS),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // Bo góc 16px
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                          "Book",
                          style: AppTypography.textSM.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          )
                      ),
                    )
                  ],
                ),
                Text("Time: ${service.duration}", style: AppTypography.textXS.copyWith(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- HELPERS ---

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
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
    );
  }

  Widget _buildContactButtons() {
    return Positioned(
      bottom: 15,
      left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconButton(Icons.chat_bubble_outline),
          const SizedBox(width: 16),
          _buildIconButton(Icons.phone_outlined),
          const SizedBox(width: 16),
          _buildIconButton(Icons.location_on_outlined),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800));

  Widget _buildLocationTab(Store store) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Location"),
          const SizedBox(height: 12),

          // 1. BẢN ĐỒ ĐỘNG CHÍNH XÁC
          if (store.location != null)
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(store.location!.latitude, store.location!.longitude),
                    zoom: 16, // Zoom gần để thấy rõ đường Lý Quốc Sư
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(store.id),
                      position: LatLng(store.location!.latitude, store.location!.longitude),
                      infoWindow: InfoWindow(title: store.name, snippet: store.address),
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            )
          else
            const Center(child: Text("Đang tải vị trí...")),

          const SizedBox(height: 24),

          // 2. THÔNG TIN LIÊN HỆ
          _buildContactInfoTile(Icons.location_on, store.address, "Address"),
          _buildContactInfoTile(Icons.phone, store.phone, "Phone"),
          _buildContactInfoTile(Icons.email, store.email, "Email"),
          _buildContactInfoTile(Icons.language, store.website, "Website"),

          const SizedBox(height: 32),

          // 3. GIỜ MỞ CỬA CHI TIẾT
          _buildSectionTitle("Opening Hours"),
          const SizedBox(height: 12),
          _buildOpeningHoursTable(store.openingHours),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Widget hỗ trợ hiển thị dòng liên hệ
  Widget _buildContactInfoTile(IconData icon, String value, String label) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey)),
                Text(value, style: AppTypography.textSM.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị bảng giờ mở cửa
  Widget _buildOpeningHoursTable(Map<String, dynamic> hours) {
    if (hours.isEmpty) return const Text("Thông tin đang được cập nhật...");
    final days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: days.map((day) {
          final time = hours[day];
          final isToday = DateTime.now().weekday == (days.indexOf(day) + 1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day[0].toUpperCase() + day.substring(1),
                    style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? AppColors.primary : Colors.black87)),
                Text(time != null ? "${time['open']} - ${time['close']}" : "Closed",
                    style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

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
  Widget _buildReviewsTab(Store store) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Phần tóm tắt Rating (Rating Summary)
        _buildRatingSummaryHeader(store),
        const Divider(height: 40, color: Color(0xFFF3F4F6)),
        OutlinedButton.icon(
          onPressed: () => _showReviewBottomSheet(context, store),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text("Review this store"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        // 2. DANH SÁCH ĐÁNH GIÁ THỰC TẾ
        if (store.reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("Chưa có đánh giá nào cho cửa hàng này."),
            ),
          )
        else
        // Lặp qua danh sách reviews trong đối tượng store
          ...store.reviews.map((review) => _buildReviewItem(review)).toList(),
      ],
    );

  }

  Widget _buildReviewItem(Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // HIỂN THỊ ẢNH NGƯỜI DÙNG
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                // Nếu review có thông tin photoUrl của người dùng
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HIỂN THỊ TÊN NGƯỜI DÙNG
                  Text(
                    "${review.userId.length > 5 ? review.userId.substring(0, 5) : review.userId}",
                    style: AppTypography.textSM.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // HIỂN THỊ NGÀY ĐĂNG
                  Text(
                    "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                    style: AppTypography.textXS.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              // HIỂN THỊ SỐ SAO ĐÁNH GIÁ
              Row(
                children: List.generate(
                  5,
                      (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // NỘI DUNG BÌNH LUẬN
          Text(
            review.comment,
            style: AppTypography.textSM.copyWith(height: 1.5, color: Colors.black87),
          ),
          // HIỂN THỊ ẢNH ĐÍNH KÈM (Nếu có)
          if (review.mediaUrl != null && review.mediaUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  review.mediaUrl!,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Hàm phụ trợ hiển thị Header Rating
  Widget _buildRatingSummaryHeader(Store store) {
    return Row(
      children: [
        Column(
          children: [
            Text(store.rating.toString(), style: AppTypography.headlineLG.copyWith(fontSize: 48)),
            Row(
              children: List.generate(5, (i) => Icon(
                  i < store.rating.floor() ? Icons.star : Icons.star_border,
                  color: Colors.amber, size: 18)
              ),
            ),
            const SizedBox(height: 8),
            Text("${store.reviewsCount} Reviews", style: AppTypography.textXS.copyWith(color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 30),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text("$star", style: AppTypography.textXS),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: star == 5 ? 0.8 : (star == 4 ? 0.15 : 0.05),
                      backgroundColor: Colors.grey[100],
                      color: AppColors.primary,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
  Widget _buildPortfolioTab(Store store) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // THANH THÔNG SỐ TỔNG QUAN (STATS BAR)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.brush, "${store.totalNails}", "Mẫu móng"),
              _buildStatItem(Icons.people, "${store.followerCount}", "Người theo dõi"),
              _buildStatItem(Icons.visibility, "${store.viewCount}", "Lượt xem"),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle("Bộ sưu tập tác phẩm"),
        const SizedBox(height: 12),

        // LƯỚI ẢNH (GIỮ NGUYÊN LOGIC CŨ)
        if (store.portfolio.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text("Chưa có tác phẩm nào để hiển thị"),
          ))
        else
          GridView.builder(
            shrinkWrap: true, // Quan trọng để cuộn trong ListView
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: store.portfolio.length,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildSmartImage(store.portfolio[index]),
              ),
            ),
          ),
      ],
    );
  }

// Widget con để hiển thị từng mục thông số
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey)),
      ],
    );
  }

  // Hàm gửi đánh giá và cập nhật điểm số chuyên nghiệp
  Future<void> _submitReview(Store store, double userRating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập để đánh giá")));
      return;
    }

    // Công thức tính Rating trung bình mới
    // NewRating = ((OldRating * OldCount) + UserRating) / (OldCount + 1)
    int newCount = store.reviewsCount + 1;
    double newRating = ((store.rating * store.reviewsCount) + userRating) / newCount;

    Map<String, dynamic> newReviewData = {
      'user_id': user.uid,
      'rating': userRating,
      'comment': comment,
      'created_at': Timestamp.now(), // Cần import cloud_firestore
      'media_url': null,
    };

    try {
      // 1. Cập nhật dữ liệu lên Firestore
      await FirebaseFirestore.instance.collection('stores').doc(store.id).update({
        'review_count': newCount,
        'rating': double.parse(newRating.toStringAsFixed(1)), // Làm tròn chuẩn 1 chữ số
        'reviews': FieldValue.arrayUnion([newReviewData]),
      });

      // 2. LOGIC QUAN TRỌNG: Làm mới dữ liệu trong Provider ngay lập tức
      if (mounted) {
        await Provider.of<StoreProvider>(context, listen: false).fetchStore(store.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cảm ơn bạn đã đánh giá!")));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
      }
    }
  }
  void _showReviewBottomSheet(BuildContext context, Store store) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder( // Dùng StatefulBuilder để cập nhật số sao khi nhấn
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Đánh giá của bạn", style: AppTypography.labelLG),
              const SizedBox(height: 16),
              // Hàng chọn sao
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () => setModalState(() => selectedRating = index + 1.0),
                  icon: Icon(Icons.star, color: index < selectedRating ? Colors.amber : Colors.grey[300], size: 32),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: "Nhập cảm nhận của bạn...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _submitReview(store, selectedRating, commentController.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Gửi đánh giá", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  // Widget hiển thị Hotline, Email, Website
  Widget _buildContactInfoSection(Store store) {
    return Column(
      children: [
        _buildContactTile(Icons.location_on, store.address, "Address"),
        _buildContactTile(Icons.phone, store.phone, "Phone"),
        _buildContactTile(Icons.email, store.email, "Email"),
        _buildContactTile(Icons.language, store.website, "Website"),
      ],
    );
  }

  Widget _buildContactTile(IconData icon, String value, String label) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey)),
                Text(value, style: AppTypography.textSM.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị danh sách giờ mở cửa từ Monday -> Sunday
  Widget _buildOpeningHoursList(Map<String, dynamic> hours) {
    if (hours.isEmpty) return const Text("Thông tin đang được cập nhật...");

    final days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: days.map((day) {
          final time = hours[day];
          final isToday = DateTime.now().weekday == (days.indexOf(day) + 1);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    day[0].toUpperCase() + day.substring(1),
                    style: AppTypography.textSM.copyWith(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? AppColors.primary : Colors.black87
                    )
                ),
                Text(
                    time != null ? "${time['open']} - ${time['close']}" : "Closed",
                    style: AppTypography.textSM.copyWith(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
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