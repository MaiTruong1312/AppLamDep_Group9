// lib/UI/your_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:applamdep/UI/booking/your_appointment_screen.dart'; // Import trang Booking để chuyển khi nhấn "Book now"
import 'package:applamdep/UI/booking/booking_screen.dart'; // Import trang Booking

class BookNowScreen extends StatefulWidget {
  const BookNowScreen({super.key});

  @override
  State<BookNowScreen> createState() => _BookNowScreenState();
}

class _BookNowScreenState extends State<BookNowScreen> {
  // Danh sách lịch hẹn mẫu (trạng thái có lịch hẹn)
  final List<Appointment> appointments = [
    Appointment(
      date: 'Thursday · July, 26 2025',
      storeName: 'Online - Honey Nail Salon · KP0274',
      serviceName: 'Nail picks\nx3 slot',
      price: 19.200,
      imagePath: 'assets/images/store1.png',
    ),
    Appointment(
      date: 'Thursday · July, 26 2025',
      storeName: 'Online - Honey Nail Salon · KP0274',
      serviceName: 'Makeup Art\nx1 slot',
      price: 50.200,
      imagePath: 'assets/images/store2.png',
    ),
  ];

  // Danh sách coupon
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs: Active / Paid / Canceled
            Row(
              children: [
                _buildStatusTab('Active', true),
                _buildStatusTab('Paid', false),
                _buildStatusTab('Canceled', false),
              ],
            ),
            const SizedBox(height: 16),

            // Filter: Within 3 month / Within 6 month
            Row(
              children: [
                _buildFilterTab('Within 3 month', true),
                _buildFilterTab('Within 6 month', false),
              ],
            ),
            const SizedBox(height: 24),

            // Danh sách lịch hẹn
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _buildAppointmentCard(appointment);
              },
            ),

            const SizedBox(height: 32),

            // Coupons section
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
                GestureDetector(
                  onTap: () {}, // Có thể mở trang tất cả coupon sau
                  child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Coupon tabs
            Row(
              children: [
                _buildCouponTab('HOT', true),
                _buildCouponTab('Near expiration', false),
                _buildCouponTab('New', false),
              ],
            ),
            const SizedBox(height: 16),

            // Coupons trượt ngang (không có ảnh lớn)
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _buildCouponItem(coupons[index]);
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


  Widget _buildStatusTab(String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
        border: isActive ? Border.all(color: const Color(0xFFF25278)) : null,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFFF25278) : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          border: isActive ? Border.all(color: Colors.grey[400]!) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appointment.date,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'See more',
                style: const TextStyle(color: Color(0xFFF25278)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.pink),
              const SizedBox(width: 4),
              Text(
                appointment.storeName,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  appointment.imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  appointment.serviceName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '\$${appointment.price.toStringAsFixed(3)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25278),
                ),
              ),
            ],
          ),
        ],
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

// Model cho lịch hẹn
class Appointment {
  final String date;
  final String storeName;
  final String serviceName;
  final double price;
  final String imagePath;

  Appointment({
    required this.date,
    required this.storeName,
    required this.serviceName,
    required this.price,
    required this.imagePath,
  });
}

// Model cho Coupon (không có imagePath)
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