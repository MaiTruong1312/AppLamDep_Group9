// main_layout.dart
import 'package:flutter/material.dart';
import 'package:applamdep/UI/Main/Home.dart';
import 'package:applamdep/UI/profile/profile_screen.dart';
import 'package:applamdep/UI/collection/collection_screen.dart';
import 'package:applamdep/UI/booking/main_booking_screen.dart';
import 'package:applamdep/UI/discover/discover_screen.dart';
import 'package:applamdep/UI/ar/home.dart';
import 'package:applamdep/UI/chatbot/home.dart';
import 'package:applamdep/services/booking_cart_service.dart';
import 'package:applamdep/UI/booking/booking_cart_screen.dart'; // Đổi tên file

class MainLayout extends StatefulWidget {
  final int initialTabIndex;

  const MainLayout({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),           // Tab 0
    CollectionScreen(),     // Tab 1
    MainBookingScreen(),    // Tab 2
    DiscoverScreen(),       // Tab 3
    ProfileScreen(),        // Tab 4
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // Floating Action Button với popup menu
      floatingActionButton: Stack(
        children: [
          // Popup Menu Button (AR + Message + Đặt lịch)
          PopupMenuButton<String>(
            offset: const Offset(0, -120),
            onSelected: (String value) {
              if (value == 'ar') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ArNailTryOnPage()),
                );
              } else if (value == 'message') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatBotPage()),
                );
              } else if (value == 'booking_cart') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookingCartScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'ar',
                child: ListTile(
                  leading: Icon(Icons.camera_alt, color: Color(0xFFF25278)),
                  title: Text('AR Thử Nail'),
                  subtitle: Text('Thử nail ảo với camera'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'message',
                child: ListTile(
                  leading: Icon(Icons.message, color: Color(0xFFF25278)),
                  title: Text('Tư vấn AI'),
                  subtitle: Text('Chat với trợ lý ảo'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'booking_cart',
                child: StreamBuilder<int>(
                  stream: BookingCartService().getBookingCartItemCount(),
                  builder: (context, snapshot) {
                    int count = snapshot.data ?? 0;
                    return ListTile(
                      leading: const Icon(Icons.calendar_today, color: Color(0xFFF25278)),
                      title: const Text('Danh sách đặt lịch'),
                      subtitle: const Text('Xem mẫu nail đã chọn'),
                      trailing: count > 0
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : null,
                    );
                  },
                ),
              ),
            ],
            child: Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: const Color(0xFFF25278),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(Icons.auto_awesome, size: 28, color: Colors.white),
            ),
          ),

          // Badge cho danh sách đặt lịch
          Positioned(
            right: 0,
            top: 0,
            child: StreamBuilder<int>(
              stream: BookingCartService().getBookingCartItemCount(),
              builder: (context, snapshot) {
                int count = snapshot.data ?? 0;
                if (count > 0) {
                  return Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 6, bottom: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          border: Border(top: BorderSide(color: Color(0xFFE0E2E5))),
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

  Widget _bottomItem(IconData icon, String label, int index) {
    bool active = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFF25278).withOpacity(0.1) : Colors.transparent,
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
              color: active ? const Color(0xFFF25278) : const Color(0xFF8F929C),
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
                  MaterialPageRoute(builder: (context) => const BookingCartScreen()),
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