import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

Widget _buildSmartImage(String path) {
  if (path.isEmpty) return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
  if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover);
  return Image.network(
    path,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
  );
}

Widget _buildSectionTitle(String title) => Text(title, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800));

class PortfolioTab extends StatelessWidget {
  final Store store;
  const PortfolioTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // THANH THÔNG SỐ TỔNG QUAN (STATS BAR)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.brush, "${store.totalNails}", "Mẫu móng"),
              _buildStatItem(Icons.people, "${store.followerCount}", "Người theo dõi"),
              _buildStatItem(Icons.visibility, "${store.viewCount}", "Lượt xem"),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle("Bộ sưu tập tác phẩm"),
        const SizedBox(height: 12),

        // LƯỚI ẢNH (GIỮ NGUYÊN LOGIC CŨ)
        if (store.portfolio.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text("Chưa có tác phẩm nào để hiển thị"),
          ))
        else
          GridView.builder(
            shrinkWrap: true, // Quan trọng để cuộn trong ListView
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: store.portfolio.length,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildSmartImage(store.portfolio[index]),
              ),
            ),
          ),
      ],
    );
  }

  // Widget con để hiển thị từng mục thông số
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey)),
      ],
    );
  }
}