import 'package:applamdep/UI/booking/booking_screen.dart';
import 'package:applamdep/UI/discover/discover_screen.dart';
import 'package:flutter/material.dart';
import 'package:applamdep/UI/Main/Home.dart';
import 'package:applamdep/UI/profile/profile_screen.dart';
import 'package:applamdep/UI/collection/collection_screen.dart';
import 'package:applamdep/UI/ar/home.dart';
import 'package:applamdep/UI/chatbot/home.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),      // Tab 0
    CollectionScreen(),     // Collection
    BookingScreen(),     // Booking
    DiscoverScreen(),     // Discover
    ProfileScreen(),   // Tab 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------------- BODY GIỮ LẠI UI CỦA HOME ----------------
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // ---------------- FLOATING AI BUTTON ----------------
      floatingActionButton: PopupMenuButton<String>(
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
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'ar',
            child: ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('AR'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'message',
            child: ListTile(
              leading: Icon(Icons.message),
              title: Text('Tin nhắn'),
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

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ---------------- BOTTOM NAVIGATION BAR ----------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 6, bottom: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          border: Border(top: BorderSide(color: Color(0xFFE0E2E5))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _bottomItem(Icons.home, "Home", 0)),
            Expanded(child: _bottomItem(Icons.grid_view, "Collection", 1)),
            Expanded(child: _bottomItem(Icons.calendar_today, "Booking", 2)),
            Expanded(child: _bottomItem(Icons.explore_outlined, "Discover", 3)),
            Expanded(child: _bottomItem(Icons.person_outline, "Profile", 4)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // -------------------- BOTTOM NAV ITEM ------------------------
  // ------------------------------------------------------------

  Widget _bottomItem(IconData icon, String label, int index) {
    bool active = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: active ? const Color(0xFFF25278) : const Color(0xFF8F929C),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
              active ? const Color(0xFFF25278) : const Color(0xFF8F929C),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
