// lib/UI/your_appointment_screen.dart
import 'package:applamdep/UI/booking/book_now.dart';
import 'package:flutter/material.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/UI/booking/booking_screen.dart'; // Import trang Booking

class YourAppointmentScreen extends StatefulWidget {
  const YourAppointmentScreen({super.key});

  @override
  State<YourAppointmentScreen> createState() => _YourAppointmentScreenState();
}

class _YourAppointmentScreenState extends State<YourAppointmentScreen> {
  // Danh sách coupon (trượt ngang)
  final List<Coupon> coupons = [
    Coupon(
      title: '30% Welcome Offer',
      description: '30% OFF your first manicure or pedicure service for new customers!',
      code: 'WELCOUPON',
    ),
    Coupon(
      title: '20% Summer Special',
      description: 'Enjoy 20% off all nail services this summer!',
      code: 'SUMMER20',
    ),
    Coupon(
      title: 'Buy 5 Get 1 Free',
      description: 'Get one free service after 5 bookings',
      code: 'BUY5FREE1',
    ),
    Coupon(
      title: '15% Weekday Discount',
      description: '15% off on weekdays (Mon-Thu)',
      code: 'WEEKDAY15',
    ),
    Coupon(
      title: '50% First Gel Polish',
      description: 'Half price for your first gel polish service',
      code: 'GEL50',
    ),
  ];

  // Danh sách hot recommendations (hardcode với assets local + tên store)
  final List<HotNail> hotNails = [
    HotNail(
      name: 'Milky White Pearl',
      store: 'Nail Haven Studio',
      likes: 1234,
      imagePath: 'assets/images/nail1.png',
    ),
    HotNail(
      name: 'Pastel Dream Garden',
      store: 'Nail Haven Studio',
      likes: 2130,
      imagePath: 'assets/images/nail2.png',
    ),
    HotNail(
      name: 'Galaxy Shimmer Night',
      store: 'LumiNail Boutique',
      likes: 2361,
      imagePath: 'assets/images/nail3.png',
    ),
    HotNail(
      name: 'Pink Daisy Cutie',
      store: 'LumiNail Boutique',
      likes: 3410,
      imagePath: 'assets/images/nail4.png',
    ),
    HotNail(
      name: 'Chrome Silver Mirror',
      store: 'Glow & Gloss Nails',
      likes: 1465,
      imagePath: 'assets/images/nail5.png',
    ),
  ];

  bool couponCopied = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Your Appointment',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= NO APPOINTMENTS =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Text(
                    'No Appointments',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Book your appointment now and let us\ncreate the perfect look for you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Chuyển sang trang BookingScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookNowScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF25278),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Book now',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================= COUPONS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer_outlined, color: Colors.pink),
                    SizedBox(width: 8),
                    Text(
                      'Coupons',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs cho coupon: HOT - Near expiration - New
            Row(
              children: [
                _buildCouponTab('HOT', true),
                _buildCouponTab('Near expiration', false),
                _buildCouponTab('New', false),
              ],
            ),
            const SizedBox(height: 16),

            // Danh sách coupon trượt ngang
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  return _buildCouponItem(coupon);
                },
              ),
            ),

            const SizedBox(height: 32),

            // ================= HOT RECOMMENDATIONS =================
            Row(
              children: [
                const Icon(Icons.whatshot, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Hot recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF25278),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'The perfect suggestion for your beauty session',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Danh sách hot nails trượt ngang
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hotNails.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final nail = hotNails[index];
                  return _buildHotNailItem(nail);
                },
              ),
            ),

            const SizedBox(height: 100), // Chừa chỗ cho bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildCouponTab(String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: const Color(0xFFF25278)) : null,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFFF25278) : Colors.grey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCouponItem(Coupon coupon) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            coupon.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            coupon.description,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, size: 16, color: Colors.pink),
                    const SizedBox(width: 6),
                    Text(
                      coupon.code,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon copied!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF25278),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'COPY',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotNailItem(HotNail nail) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              nail.imagePath,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nail.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  nail.store,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.pink),
                    const SizedBox(width: 4),
                    Text(
                      '${nail.likes}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Model cho Coupon
class Coupon {
  final String title;
  final String description;
  final String code;

  Coupon({
    required this.title,
    required this.description,
    required this.code,
  });
}

// Model cho Hot Nail
class HotNail {
  final String name;
  final String store;
  final int likes;
  final String imagePath;

  HotNail({
    required this.name,
    required this.store,
    required this.likes,
    required this.imagePath,
  });
}