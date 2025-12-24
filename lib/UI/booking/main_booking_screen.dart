// lib/UI/booking/main_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:applamdep/UI/main_layout.dart'; // THÊM IMPORT NÀY
import 'package:applamdep/UI/booking/your_appointment_screen.dart';

class MainBookingScreen extends StatefulWidget {
  const MainBookingScreen({Key? key}) : super(key: key);

  @override
  State<MainBookingScreen> createState() => _MainBookingScreenState();
}

class _MainBookingScreenState extends State<MainBookingScreen> {
  // Hàm chuyển đến Collection tab (index 1)
  void _navigateToCollection(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainLayout(initialTabIndex: 1), // XÓA 'const'
      ),
          (route) => false,
    );
  }

  // Hàm xem lịch sử đặt lịch
  void _viewBookingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const YourAppointmentScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Booking',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Illustration với hiệu ứng glass
            _buildGlassCircle(
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 100,
                color: Color(0xFFF25278),
              ),
            ),

            const SizedBox(height: 40),

            // Title
            const Text(
              'Start scheduling',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2022),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose your favorite nail design from our collection and book an appointment with a professional nail technician.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // NÚT GLASS - DISCOVER NAIL DESIGNS
            _buildGlassButton(
              context: context,
              icon: Icons.grid_view,
              title: 'DISCOVER NAIL DESIGNS',
              subtitle: 'View the full collection',
              onPressed: () => _navigateToCollection(context),
            ),

            const SizedBox(height: 20),

            // Nút thứ cấp - Xem lịch sử
            _buildSecondaryButton(
              icon: Icons.history,
              title: 'VIEW BOOKING HISTORY',
              onPressed: _viewBookingHistory,
            ),

            const SizedBox(height: 30),

            // Features
            _buildFeatureItem(
              icon: Icons.brush,
              title: '1000+ Nail Designs',
              subtitle: 'Weekly updates',
            ),

            _buildFeatureItem(
              icon: Icons.verified,
              title: 'Professional nail technician',
              subtitle: 'Well-trained',
            ),

            _buildFeatureItem(
              icon: Icons.schedule,
              title: 'Flexible scheduling',
              subtitle: '24/7, free cancellation',
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // Widget tạo hiệu ứng glass circle
  Widget _buildGlassCircle({required Widget child}) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: const ColorFilter.mode(
            Colors.transparent,
            BlendMode.srcOver,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  // Widget tạo nút với hiệu ứng glass
  Widget _buildGlassButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: const ColorFilter.mode(
              Colors.transparent,
              BlendMode.srcOver,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 28, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget nút thứ cấp
  Widget _buildSecondaryButton({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFFF25278), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFFF25278)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF25278),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFF25278)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2022),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}