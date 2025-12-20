// lib/UI/voucher_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:applamdep/UI/booking/booking_screen.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  late Timer _timer;
  Duration _remainingTime = const Duration(hours: 23, minutes: 59, seconds: 59);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  final List<Coupon> coupons = [
    // Voucher 24h - lên đầu + ảnh voucher1.png
    Coupon(
      title: '40% Flash Sale - Limited 24 Hours!',
      description: 'Huge discount 40% off any service. Only valid within 24 hours!',
      code: 'FLASH24H',
      imagePath: 'assets/images/voucher3.png',
      isLimitedTime: true,
    ),
    Coupon(
      title: '30% Welcome Offer',
      description: '30% OFF your first manicure or pedicure service for new customers!',
      code: 'WELCOUPON',
      imagePath: 'assets/images/voucher1.png',
    ),
    Coupon(
      title: '20% Summer Special',
      description: 'Enjoy 20% off all nail services this summer!',
      code: 'SUMMER20',
      imagePath: 'assets/images/voucher3.png',
    ),
    Coupon(
      title: 'Buy 5 Get 1 Free',
      description: 'Get one free service after 5 bookings',
      code: 'BUY5FREE1',
      imagePath: 'assets/images/voucher1.png',
    ),
    Coupon(
      title: '15% Weekday Discount',
      description: '15% off on weekdays (Mon-Thu)',
      code: 'WEEKDAY15',
      imagePath: 'assets/images/voucher2.png',
    ),
    Coupon(
      title: '50% First Gel Polish',
      description: 'Half price for your first gel polish service',
      code: 'GEL50',
      imagePath: 'assets/images/voucher3.png',
    ),
  ];

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
          'Vouchers',
          style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_offer, color: Color(0xFFF25278), size: 28),
                SizedBox(width: 12),
                Text(
                  'Available Vouchers',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Voucher trượt ngang với ảnh background
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _buildVoucherCard(coupons[index]);
                },
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'All Vouchers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Voucher dọc với ảnh
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: coupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildVoucherCardVertical(coupons[index]);
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Coupon coupon) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Ảnh background
            Image.asset(
              coupon.imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            // Overlay tối để chữ nổi
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            // Nội dung voucher
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (coupon.isLimitedTime) ...[
                    const Text('Limited Time Offer!', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCountdownBox(_remainingTime.inHours.toString().padLeft(2, '0')),
                        const Text(' : ', style: TextStyle(fontSize: 28, color: Colors.white)),
                        _buildCountdownBox((_remainingTime.inMinutes % 60).toString().padLeft(2, '0')),
                        const Text(' : ', style: TextStyle(fontSize: 28, color: Colors.white)),
                        _buildCountdownBox((_remainingTime.inSeconds % 60).toString().padLeft(2, '0')),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(coupon.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(coupon.description, style: const TextStyle(fontSize: 13, color: Colors.white70), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                        child: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: coupon.code));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied "${coupon.code}"!')));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                          child: const Text('COPY', style: TextStyle(color: Color(0xFFF25278))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownBox(String number) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
      child: Text(number, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
    );
  }

  Widget _buildVoucherCardVertical(Coupon coupon) {
    return Container(
      height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.asset(coupon.imagePath, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coupon.isLimitedTime) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCountdownBox(_remainingTime.inHours.toString().padLeft(2, '0')),
                        const Text(' : ', style: TextStyle(fontSize: 28, color: Colors.white)),
                        _buildCountdownBox((_remainingTime.inMinutes % 60).toString().padLeft(2, '0')),
                        const Text(' : ', style: TextStyle(fontSize: 28, color: Colors.white)),
                        _buildCountdownBox((_remainingTime.inSeconds % 60).toString().padLeft(2, '0')),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(coupon.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(coupon.description, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                        child: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: coupon.code));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied "${coupon.code}"!')));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        child: const Text('COPY', style: TextStyle(color: Color(0xFFF25278))),
                      ),
                    ],
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

class Coupon {
  final String title;
  final String description;
  final String code;
  final String imagePath;
  final bool isLimitedTime;

  Coupon({
    required this.title,
    required this.description,
    required this.code,
    required this.imagePath,
    this.isLimitedTime = false,
  });
}