import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:applamdep/providers/store_provider.dart';
import '../../models/store_model.dart';
import '../../models/review_model.dart';
import '../../models/service_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_tab_most_service.dart';
import 'store_tab_review.dart';
import 'store_tab_portfolio.dart';
import 'store_tab_giftcard.dart';
import 'store_tab_location.dart';
import 'chat_screen.dart';



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
                  MostServiceTab(store: store),
                  ReviewsTab(store: store),
                  PortfolioTab(store: store),
                  const Center(child: Text("Giftcard Content")),
                  LocationTab(store: store),
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
            _buildContactButtons(store),
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
      "Nail Art": "assets/icons/hair_removal.svg",
      "Crystal Embellishment": "assets/icons/hair_cut.svg",
      "Airbrush Design": "assets/icons/hair_style.svg",
      "3d Sculpture": "assets/icons/facial.svg",
      "Special Occasion Nails": "assets/icons/nails.svg",
      "Nails": "assets/icons/nails.svg",
      "Manicure": "assets/icons/facial.svg",
      "Med Spa": "assets/icons/med_spa.svg",
      "Medicure": "assets/icons/massage.svg",
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
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildSmartImage(sales[index].imageUrl),
          ),
        ),
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

  Widget _buildContactButtons(Store store) {
    return Positioned(
      bottom: 15,
      left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconButton(Icons.chat_bubble_outline, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(storeId: store.id, storeName: store.name),
              ),
            );
          }),
          const SizedBox(width: 16),
          _buildIconButton(Icons.phone_outlined, () {
            _showHotlineBottomSheet(context,
                store.hotline);
          }),
          const SizedBox(width: 16),
          Builder(builder: (context) {
            return _buildIconButton(Icons.location_on_outlined, () {
              DefaultTabController.of(context).animateTo(4);
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

  void _showHotlineBottomSheet(BuildContext context, String phoneNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Để lộ bo góc phía dưới
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Tự động co dãn theo nội dung
          children: [
            Text("Hotline", style: AppTypography.textXS.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              phoneNumber.isNotEmpty ? phoneNumber : "Chưa cập nhật",
              style: AppTypography.headlineSM.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Nút Hủy
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                // Nút Gọi
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Cần cài đặt thêm package url_launcher để thực hiện cuộc gọi thật
                      Navigator.pop(context);
                      print("Đang thực hiện cuộc gọi tới $phoneNumber");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
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