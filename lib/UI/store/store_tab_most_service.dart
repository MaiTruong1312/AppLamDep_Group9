import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../models/service_model.dart';
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

class MostServiceTab extends StatelessWidget {
  final Store store;
  const MostServiceTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // THANH TÌM KIẾM
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), // Màu xám nhạt chuẩn thiết kế
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search services, salons...",
                hintStyle: AppTypography.textSM.copyWith(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // DANH SÁCH DỊCH VỤ
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: store.services.length,
            itemBuilder: (context, index) {
              final service = store.services[index];
              return _buildServiceCard(service);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8)
            )
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hình ảnh dịch vụ (Lấy từ imageUrl trong Firebase)
          ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: _buildSmartImage(service.imageUrl ?? ''),
              )
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Tên dịch vụ
                Text(
                    service.name,
                    style: AppTypography.textMD.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text(
                    "Premium beauty service with quality care.",
                    style: AppTypography.textSM.copyWith(color: Colors.grey)
                ),
                const SizedBox(height: 12),

                // 3. Thông số: Bookings & Nút đặt lịch
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                        "${service.bookings}+ bookings",
                        style: AppTypography.textXS.copyWith(color: Colors.grey)
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // Logic đặt lịch
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                          "Book",
                          style: AppTypography.textSM.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          )
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),

                // 4. Thời gian thực hiện dịch vụ
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 14),
                    const SizedBox(width: 4),
                    Text(
                        "Time: ${service.duration}",
                        style: AppTypography.textXS.copyWith(color: Colors.grey)
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}