// main_layout.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:applamdep/UI/Main/Home.dart';
import 'package:applamdep/UI/profile/profile_screen.dart';
import 'package:applamdep/UI/collection/collection_screen.dart';
import 'package:applamdep/UI/booking/main_booking_screen.dart';
import 'package:applamdep/UI/discover/discover_screen.dart';
import 'package:applamdep/UI/ar/home.dart';
import 'package:applamdep/UI/chatbot/home.dart';
import 'package:applamdep/services/booking_cart_service.dart';
import 'package:applamdep/UI/booking/booking_cart_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialTabIndex;

  const MainLayout({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  bool _isFabExpanded = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;

  final List<Widget> _pages = const [
    HomeScreen(), // Tab 0
    CollectionScreen(), // Tab 1
    MainBookingScreen(), // Tab 2
    DiscoverScreen(), // Tab 3
    ProfileScreen(), // Tab 4
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;

    // Animation controller cho FAB
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOutBack,
    );

    _fabRotationAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFabMenu() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _navigateToScreen(Widget screen) {
    _toggleFabMenu();
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // Floating Action Button với Circular Glass Menu
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // Overlay khi mở menu
          if (_isFabExpanded)
            GestureDetector(
              onTap: _toggleFabMenu,
              child: Container(
                color: Colors.transparent,
              ),
            ),

          // Các nút action với hiệu ứng glass (xuất hiện khi mở menu)
          ..._buildFabMenuItems(),

          // Nút FAB chính với hiệu ứng glass morphism
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildMainFab(),
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 6, bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _bottomItem(Icons.home, "Trang chủ", 0)),
            Expanded(child: _bottomItem(Icons.grid_view, "Bộ sưu tập", 1)),
            Expanded(child: _bottomItem(Icons.calendar_today, "Đặt lịch", 2)),
            Expanded(child: _bottomItem(Icons.explore_outlined, "Khám phá", 3)),
            Expanded(child: _bottomItem(Icons.person_outline, "Tài khoản", 4)),
          ],
        ),
      ),
    );
  }

  // ================== FAB MENU ITEMS ==================

  List<Widget> _buildFabMenuItems() {
    // SỬA 1: Chỉ ẩn hẳn khi animation đã chạy xong chiều về (reverse)
    if (!_isFabExpanded && _fabAnimationController.isDismissed) return [];

    const double radius = 120;

    return [
      // AR Thử Nail
      _buildFabMenuItem(
        index: 0,
        icon: Icons.camera_alt,
        label: 'AR Thử Nail',
        color: const Color(0xFF6A11CB),
        screen: const ArNailTryOnPage(),
        angle: 0,
      ),
      // Tư vấn AI
      _buildFabMenuItem(
        index: 1,
        icon: Icons.message,
        label: 'Tư vấn AI',
        color: const Color(0xFF2575FC),
        screen: const ChatBotPageV2(),
        angle: 50,
      ),
      // Danh sách đặt lịch - có badge
      StreamBuilder<int>(
        stream: BookingCartService().getBookingCartItemCount(),
        builder: (context, snapshot) {
          final int bookingCount = snapshot.data ?? 0;
          return _buildFabMenuItem(
            index: 2,
            icon: Icons.calendar_today,
            label: 'Danh sách đặt lịch',
            color: const Color(0xFFF7971E),
            screen: const BookingCartScreen(),
            angle: 110,
            badgeCount: bookingCount, // Thêm badge count
          );
        },
      ),
    ];
  }

  Widget _buildFabMenuItem({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required Widget screen,
    required double angle,
    int badgeCount = 0,
  }) {
    final double radian = angle * (pi / 180);

    return Positioned(
      bottom: 20 + 120 * sin(radian),
      right: 20 + 120 * cos(radian),
      child: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FadeTransition(
          opacity: _fabAnimationController,
          child: _buildGlassFabItem(
            icon: icon,
            label: label,
            color: color,
            onTap: () => _navigateToScreen(screen),
            badgeCount: badgeCount, // Truyền badgeCount vào
          ),
        ),
      ),
    );
  }

  Widget _buildGlassFabItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label với hiệu ứng glass
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Icon với hiệu ứng glass morphism và badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.8),
                      color.withOpacity(0.6),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ),

            // Badge cho danh sách đặt lịch (chỉ hiển thị khi có số lượng > 0)
            if (badgeCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainFab() {
    return GestureDetector(
      onTap: _toggleFabMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isFabExpanded
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF25278),
              Color(0xFFFD4F6A),
            ],
          )
              : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF25278),
              Color(0xFFF25278),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: _isFabExpanded ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(_isFabExpanded ? 0.4 : 0.3),
              blurRadius: _isFabExpanded ? 25 : 15,
              spreadRadius: _isFabExpanded ? 3 : 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 400),
          turns: _fabRotationAnimation.value * 0.125,
          child: Icon(
            _isFabExpanded ? Icons.close : Icons.auto_awesome,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ================== BOTTOM NAVIGATION ITEMS ==================

  Widget _bottomItem(IconData icon, String label, int index) {
    bool active = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFF25278).withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: active ? const Color(0xFFF25278) : const Color(0xFF8F929C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
              active ? const Color(0xFFF25278) : const Color(0xFF8F929C),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị icon đặt lịch với badge (có thể dùng ở appBar)
  Widget _buildBookingCartIcon() {
    return StreamBuilder<int>(
      stream: BookingCartService().getBookingCartItemCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Color(0xFFF25278)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BookingCartScreen()),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}