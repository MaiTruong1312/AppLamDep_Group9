// lib/UI/discover_screen.dart
import 'package:applamdep/UI/ar/home.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/UI/detail/nail_detail_screen.dart';     // Trang chi tiết nail
import 'package:applamdep/UI/booking/booking_screen.dart';  // Trang đặt lịch
import 'package:applamdep/UI/profile/Notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Khám phá',
          style: TextStyle(
            color: Color(0xFF313235),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ===================== SEARCH BAR =====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm mẫu nail, màu sắc, store...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // TODO: Mở bottom sheet filter
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // ===================== TOOLS SECTION =====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Công cụ',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Banner
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/banner1.png', // File PNG của bạn
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Chip(
                                backgroundColor: Color(0xFFF25278),
                                label: Text(
                                  'NEW',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // AR Try-on Card
                        _buildToolItem(
                          icon: Icons.auto_fix_high,
                          iconColor: const Color(0xFFF25278),
                          bgIcon: const Color(0xFFFFE4E8),
                          title: 'AR Nail Try-on',
                          subtitle: 'Thử mẫu nail ngay trên tay bạn bằng camera',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ArNailTryOnPage()),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // AI Assistant Card
                        _buildToolItem(
                          icon: Icons.smart_toy_outlined,
                          iconColor: Colors.blue,
                          bgIcon: const Color(0xFFE3F2FD),
                          title: 'AI Nail Assistant',
                          subtitle: 'Gợi ý mẫu nail phù hợp với phong cách của bạn',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ArNailTryOnPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ===================== HOT TRENDS =====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hot Trends Tháng 12/2025',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildTrendCard('assets/images/nail1.png', 'Chrome Nails'),
                        _buildTrendCard('assets/images/nail2.png', 'Festive Christmas'),
                        _buildTrendCard('assets/images/nail3.png', 'Minimal Art'),
                        _buildTrendCard('assets/images/nail4.png', 'Velvet Cat Eye'),
                        _buildTrendCard('assets/images/nail5.png', '3D Jewel'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ===================== DISCOVERY FEED =====================
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('nails')
                .orderBy('created_at', descending: true) // hoặc orderBy('rating')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: Center(child: Text('Lỗi: ${snapshot.error}')));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Text('Chưa có mẫu nail nào')));
              }

              final List<Nail> nails = snapshot.data!.docs
                  .map((doc) => Nail.fromFirestore(doc))
                  .where((nail) => nail.name.toLowerCase().contains(_searchQuery))
                  .toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final nail = nails[index];
                      return _buildNailDiscoverCard(nail);
                    },
                    childCount: nails.length,
                  ),
                ),
              );
            },
          ),

          // Padding bottom
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ===================== HELPER WIDGETS =====================

  Widget _buildToolItem({
    required IconData icon,
    required Color iconColor,
    required Color bgIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgIcon, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(String assetPath, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              assetPath,
              width: 180,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.error)),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNailDiscoverCard(Nail nail) {
    return GestureDetector(
      onTap: () async {
        Store? store;
        if (nail.storeId != null && nail.storeId!.isNotEmpty) {
          final doc = await FirebaseFirestore.instance.collection('stores').doc(nail.storeId).get();
          if (doc.exists) store = Store.fromFirestore(doc);
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NailDetailScreen(nail: nail, store: store),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh mẫu nail (assets)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                'assets/images/nail3.png', // ví dụ: assets/images/nail_001.png
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.error)),
              ),
            ),

            // Thông tin
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nail.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      const Text('4.8', style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text(
                        '${nail.price.toStringAsFixed(0)}đ',
                        style: const TextStyle(color: Color(0xFFF25278), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(selectedNail: nail),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF25278),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Đặt lịch ngay',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}