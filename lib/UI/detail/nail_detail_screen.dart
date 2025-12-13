import 'dart:async';
import 'package:flutter/material.dart';

class NailDetailScreen extends StatefulWidget {
  // Bạn có thể truyền ID sản phẩm vào đây sau này
  const NailDetailScreen({Key? key}) : super(key: key);

  @override
  State<NailDetailScreen> createState() => _NailDetailScreenState();
}

class _NailDetailScreenState extends State<NailDetailScreen> {
  // Biến cho phần "Read more"
  bool isExpanded = false;

  // Biến cho Countdown Voucher
  late Timer _timer;
  Duration _duration = const Duration(hours: 23, minutes: 2, seconds: 56);

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_duration.inSeconds > 0) {
        setState(() {
          _duration = _duration - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Nail A.01",
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // --- NỘI DUNG CUỘN ---
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Chừa chỗ cho nút Book
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageHeader(),
                const SizedBox(height: 20),
                _buildSectionTitle("About A.01"),
                _buildDescription(),
                const Divider(height: 40, thickness: 1, color: Color(0xFFEEEEEE)),
                _buildVoucherSection(),
                const SizedBox(height: 20),
                _buildColorSection(),
                const Divider(height: 40, thickness: 1, color: Color(0xFFEEEEEE)),
                _buildReviewSummary(),
                _buildUserReviews(),
              ],
            ),
          ),

          // --- NÚT BOOK DƯỚI CÙNG ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Availability Saturday at 16:00 PM",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF25278),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Book",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nút Floating AI nhỏ (giống thiết kế)
          Positioned(
            bottom: 80,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF25278),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  // ---------------- WIDGET CON ----------------

  Widget _buildImageHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              "assets/images/nail1.png", // Thay ảnh thật của bạn vào đây
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 220,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image, size: 50)),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF25278),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "☆ 4.8 (1k + Review)",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildDescription() {
    final text =
        "Nail service, we now offer lash extension, and nail design service. Call for information about lashes and art.";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            maxLines: isExpanded ? null : 2,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF313235), height: 1.5),
          ),
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Text(
              isExpanded ? "Show less" : "Read more",
              style: const TextStyle(
                color: Color(0xFFF25278),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_duration.inHours);
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Voucher",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Text("Closing in: ", style: TextStyle(fontSize: 12)),
                  _buildTimeBox(hours),
                  const Text(" : "),
                  _buildTimeBox(minutes),
                  const Text(" : "),
                  _buildTimeBox(seconds),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            children: [
              _buildVoucherCard(Colors.brown.shade400, "50% OFF"),
              _buildVoucherCard(Colors.amber, "VOUCHER %"),
              _buildVoucherCard(Colors.red.shade800, "SALE"),
              _buildVoucherCard(Colors.purple, "STAR"),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTimeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF25278),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        time,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildVoucherCard(Color color, String text) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style:
        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildColorSection() {
    final colors = [
      const Color(0xFFF25278), // Pink
      const Color(0xFF5D75A8), // Blue Grey
      const Color(0xFF5D6BF8), // Indigo
      const Color(0xFFE040FB), // Purple
      Colors.black,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Suggested color"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: colors.map((color) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildReviewSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Column(
              children: [
                const Text(
                  "5.0/5",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: List.generate(
                      5,
                          (index) => const Icon(Icons.star_outline,
                          color: Colors.amber, size: 20)),
                ),
                const SizedBox(height: 4),
                const Text("Based on 53 reviews",
                    style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  _buildProgressBar(5, 70),
                  _buildProgressBar(4, 1),
                  _buildProgressBar(3, 0),
                  _buildProgressBar(2, 0),
                  _buildProgressBar(1, 0),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int star, int value) {
    return Row(
      children: [
        Text("$star", style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey.shade200,
              color: Colors.amber,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
            width: 20,
            child: Text("$value",
                style: const TextStyle(fontSize: 12, color: Colors.grey))),
      ],
    );
  }

  Widget _buildUserReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Reviews"),
        _buildSingleReviewItem(),
        _buildSingleReviewItem(),
        const SizedBox(height: 100), // Khoảng trống cuối trang
      ],
    );
  }

  Widget _buildSingleReviewItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
                5,
                    (index) =>
                const Icon(Icons.star_outline, color: Colors.amber, size: 20)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hotstyle 2025",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: const [
                  Text("Tammy • July 30 2025",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Icons.check_circle, color: Colors.blue, size: 14)
                ],
              )
            ],
          ),
          const Text("by Honey Nail Salon",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          const Text(
              "Honey Nail Salon is great; very quick, and my nails look fabulous"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("↪ Replied: July 30 2025",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 4),
                Text("Honey Nail Salon",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Yay! So glad you love them!",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(Icons.thumb_up_outlined, "10"),
              const SizedBox(width: 12),
              _buildActionButton(Icons.thumb_down_outlined, "0"),
              const Spacer(),
              _buildActionButton(Icons.flag_outlined, "Report"),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Icon(icon, size: 16),
        ],
      ),
    );
  }
}