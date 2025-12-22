import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/store_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class FlashSaleDetailScreen extends StatefulWidget {
  final Flashsale flashsale;
  final Duration initialRemainingTime; // Nhận thời gian còn lại từ trang Store
  const FlashSaleDetailScreen({
    super.key,
    required this.flashsale,
    required this.initialRemainingTime
  });

  @override
  State<FlashSaleDetailScreen> createState() => _FlashSaleDetailScreenState();
}

class _FlashSaleDetailScreenState extends State<FlashSaleDetailScreen> {
  late Duration _remainingTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialRemainingTime;
    _startCountdown();
  }

  // Logic đếm ngược giống như store_details.dart
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() => _remainingTime -= const Duration(seconds: 1));
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    String hours = _twoDigits(_remainingTime.inHours);
    String minutes = _twoDigits(_remainingTime.inMinutes.remainder(60));
    String seconds = _twoDigits(_remainingTime.inSeconds.remainder(60));

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tiêu đề và Nhãn giảm giá
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.flashsale.title,
                          style: AppTypography.headlineSM.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _buildDiscountBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Bộ đếm ngược (Countdown Clock)
                  _buildCountdownSection(hours, minutes, seconds),
                  const SizedBox(height: 32),

                  // 3. Mô tả chương trình (Description)
                  _buildSectionTitle("Promotion Detail"),
                  const SizedBox(height: 8),
                  Text(
                    widget.flashsale.description,
                    style: AppTypography.textSM.copyWith(color: Colors.black54, height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  // 4. Điều kiện áp dụng (Conditions)
                  _buildSectionTitle("Terms & Conditions"),
                  const SizedBox(height: 8),
                  _buildConditionList(widget.flashsale.conditions),
                  const SizedBox(height: 100), // Khoảng cách cho nút ở dưới
                ],
              ),
            ),
          ),
        ],
      ),
      // bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: _buildCircleAction(Icons.arrow_back, () => Navigator.pop(context)),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildSmartImage(widget.flashsale.imageUrl),
      ),
    );
  }

  Widget _buildDiscountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "-${(widget.flashsale.discount * 100).toInt()}% OFF",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCountdownSection(String h, String m, String s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text("Offer expires in:", style: AppTypography.textXS.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(h), _buildTimeDivider(),
              _buildTimeBox(m), _buildTimeDivider(),
              _buildTimeBox(s),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTimeDivider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text(":", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
  );

  Widget _buildConditionList(String conditions) {
    // Tự động tách các dòng điều kiện nếu bạn dùng dấu chấm hoặc xuống dòng
    return Text(
      conditions,
      style: AppTypography.textSM.copyWith(color: Colors.black54, height: 1.6),
    );
  }

  // Widget _buildBottomAction() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
  //     ),
  //     child: ElevatedButton(
  //       onPressed: () => Navigator.pop(context),
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: AppColors.primary,
  //         minimumSize: const Size(double.infinity, 56),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       ),
  //       child: const Text("USE THIS OFFER NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  //     ),
  //   );
  // }

  Widget _buildSmartImage(String path) {
    if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover);
    return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
  }

  Widget _buildSectionTitle(String title) => Text(title, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w900));

  Widget _buildCircleAction(IconData icon, VoidCallback onTap) => Center(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    ),
  );
}