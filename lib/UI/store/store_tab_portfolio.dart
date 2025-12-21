import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Đảm bảo đã thêm intl vào pubspec.yaml
import '../../models/store_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class PortfolioTab extends StatelessWidget {
  final Store store;
  const PortfolioTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. NGÀY THÀNH LẬP (Established Date) - Lấy từ Firebase
        if (store.establishedDate != null) _buildEstablishedDate(store.establishedDate!),
        const SizedBox(height: 24),

        // 2. MÔ TẢ (Studio Story) - Lấy từ Firebase
        _buildAboutSection(),
        const SizedBox(height: 32),

        // 3. TỔNG QUAN SỐ LƯỢNG (Stats Bar)
        _buildStatsBar(),
        const SizedBox(height: 32),

        // 4. GIỜ MỞ CỬA (Business Hours)
        _buildOpeningHoursSection(),

        const SizedBox(height: 40),
      ],
    );
  }

  // --- CÁC HÀM UI COMPONENTS PHẢI NẰM TRONG CLASS NÀY ---

  Widget _buildSectionTitle(String title) => Text(
      title,
      style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800)
  );

  Widget _buildEstablishedDate(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            // Định dạng: 10/12/2021
            "Established Since ${date.day}/${date.month}/${date.year}",
            style: AppTypography.textSM.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Studio Story"),
        const SizedBox(height: 12),
        Text(
          // Hiển thị description từ Firebase
          store.description.isNotEmpty
              ? store.description
              : "Welcome to our studio, where beauty meets artistry.",
          style: AppTypography.textSM.copyWith(color: Colors.black87, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8)
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.brush, "${store.totalNails}", "Artworks"),
          _buildStatItem(Icons.people_outline, "${store.followerCount}", "Followers"),
          _buildStatItem(Icons.visibility_outlined, "${store.viewCount}", "Total Views"),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 26),
        const SizedBox(height: 10),
        Text(value, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildOpeningHoursSection() {
    if (store.openingHours.isEmpty) return const SizedBox.shrink();
    final days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];
    final int todayIndex = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Business Hours"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: days.map((day) {
              final time = store.openingHours[day];
              final bool isToday = days.indexOf(day) == todayIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day[0].toUpperCase() + day.substring(1),
                      style: AppTypography.textSM.copyWith(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    Text(
                      time != null ? "${time['open']} - ${time['close']}" : "Closed",
                      style: AppTypography.textSM.copyWith(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}