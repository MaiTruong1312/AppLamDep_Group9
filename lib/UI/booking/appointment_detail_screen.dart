import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Để mở call/map
import 'package:applamdep/UI/chatbot/home.dart'; // Trang chat

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}


class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  // Danh sách dịch vụ (giống giỏ hàng)
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

  List<ServiceItem> services = [
    ServiceItem(
      name: 'Milky White Pearl',
      price: 18,
      imagePath: 'assets/images/nail1.png',
      quantity: 1,
    ),
    ServiceItem(
      name: 'Pastel Dream Garden',
      price: 23,
      imagePath: 'assets/images/nail2.png',
      quantity: 0,
    ),
    ServiceItem(
      name: 'Galaxy Shimmer Night',
      price: 36,
      imagePath: 'assets/images/nail3.png',
      quantity: 0,
    ),
  ];

  double get totalPrice {
    return services.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
  int get totalServices {
    return services.fold(0, (sum, item) => sum + item.quantity);
  }

  // Tab hiện tại
  String currentTab = 'Booked';

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
        title: const Text('Your Appointment', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh salon
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/store1.png', width: double.infinity, height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),

            // 4 icon hành động
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.chat_bubble_outline, 'Chat', () {
                  // TODO: Mở chat với salon
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatBotPageV2()),
                  );
                }),
                _buildActionButton(Icons.phone_outlined, 'Call', () async {
                  // Giữ nguyên mở dialer (vì không có trang gọi điện riêng)
                  final Uri launchUri = Uri(scheme: 'tel', path: '+1234567890');
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot open dialer')),
                    );
                  }
                }),
                _buildActionButton(Icons.location_on_outlined, 'Map', () {
                  // Chuyển sang trang bản đồ salon (tạo tạm nếu chưa có)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatBotPageV2()),
                  );
                }),
                _buildActionButton(Icons.share_outlined, 'Share', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatBotPageV2()),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs cuộn ngang: Booked, Reviews, Invoice, Gift
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDetailTab('Booked', currentTab == 'Booked', () => setState(() => currentTab = 'Booked')),
                  _buildDetailTab('Reviews', currentTab == 'Reviews', () => setState(() => currentTab = 'Reviews')),
                  _buildDetailTab('Invoice', currentTab == 'Invoice', () => setState(() => currentTab = 'Invoice')),
                  _buildDetailTab('Gift', currentTab == 'Gift', () => setState(() => currentTab = 'Gift')),
                  _buildDetailTab('Contact', currentTab == 'Contact', () => setState(() => currentTab = 'Contact')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nội dung theo tab (ở đây chỉ làm chi tiết cho Booked, các tab khác có thể thêm sau)
            if (currentTab == 'Booked') ...[
              // Thông tin khách, salon, time, seats...
              _buildInfoRow(Icons.person_outline, 'Tam Nguyen (+123-456-1234)'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on_outlined, '6101 San Felipe St, Houston, TX,\nUnited States, Texas'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.store_outlined, 'Honey Saloon\n6101 San Felipe St, Houston, TX, United States, Texas'),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: _buildTimeSeatCard(icon: Icons.access_time, title: 'Time', value: '16:00\n2025 July 26')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimeSeatCard(icon: Icons.event_seat_outlined, title: 'Number of seats', value: '01 - 1h30mins', hasSparkle: true)),
                ],
              ),
              const SizedBox(height: 32),

              // Service - giống giỏ hàng
              const Text('Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  if (service.quantity == 0) return const SizedBox.shrink();
                  return _buildServiceCartItem(service, index);
                },
              ),
              const SizedBox(height: 24),

              // Tổng tiền
              _buildPriceRow('Points Amount', totalPrice),
              _buildPriceRow('Payment', totalPrice),
              _buildPriceRow('Consultation', 'Free', isFree: true),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('You will get', style: TextStyle(fontSize: 16)),
                  Text('\$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                ],
              ),
            ] else
              Center(child: Text('Coming soon: $currentTab section')),
            const Text(
              'Cashing to',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset('assets/images/cash_logo.png', width: 60), // Bạn có thể thêm logo Visa nếu có
                  const SizedBox(width: 16),
                  const Text('Pay on arrival salon'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF25278),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
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

  // Các widget hỗ trợ (giữ nguyên và bổ sung counter cho service)
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.grey[200], child: Icon(icon, color: const Color(0xFFF25278))),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDetailTab(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? const Color(0xFFF25278) : Colors.transparent, width: 3)),
        ),
        child: Text(
          title,
          style: TextStyle(color: isActive ? const Color(0xFFF25278) : Colors.grey, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildServiceCartItem(ServiceItem service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(service.imagePath, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text('${service.name} x${service.quantity}', style: const TextStyle(fontWeight: FontWeight.w600))),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    if (service.quantity > 0) service.quantity--;
                  });
                },
              ),
              Text('${service.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF25278)),
                onPressed: () {
                  setState(() {
                    service.quantity++;
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
          Text('\$${ (service.price * service.quantity).toStringAsFixed(2) }', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
        ],
      ),
    );
  }

// Các widget khác (_buildInfoRow, _buildTimeSeatCard, _buildPriceRow, v.v.) giữ nguyên như file trước
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF25278), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  Widget _buildTimeSeatCard({required IconData icon, required String title, required String value, bool hasSparkle = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF25278)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          if (hasSparkle) const Spacer() else const SizedBox(),
          if (hasSparkle)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFF25278), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }
  Widget _buildServiceItem(ServiceItem service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              service.imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('\$${service.price} }',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    if (service.quantity > 0) service.quantity--;
                  });
                },
              ),
              Text('${service.quantity}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFFF25278)),
                onPressed: () {
                  setState(() {
                    if (totalServices < 3) service.quantity++;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildPriceRow(String title, dynamic value, {bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(
            isFree ? 'Free' : '\$$value',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isFree ? Colors.grey : const Color(0xFFF25278)),
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

class ServiceItem {
  String name;
  double price;
  int quantity;
  String imagePath;

  ServiceItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imagePath,
  });
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