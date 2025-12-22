import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../models/service_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'service_details.dart';


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
  void _navigateToDetail(BuildContext context, Service service, {bool showMessage = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(service: service, store: store),
      ),
    );

    if (showMessage) {
      // Hiển thị thông báo tiếng Anh như yêu cầu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a design to book an appointment"),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
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
              return _buildServiceCard(context, service);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, Service service) {
    return InkWell(
      // 1. Ấn vào card chuyển hướng sang Service Details
      onTap: () => _navigateToDetail(context, service),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8)
              )
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text(
                      service.name,
                      style: AppTypography.textMD.copyWith(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.description.isNotEmpty ? service.description : "Premium beauty service with quality care.",
                    style: AppTypography.textSM.copyWith(color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // 2. Bỏ phần Bookings, hiển thị Time và nút Book
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hiển thị thời gian
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                              "Time: ${service.duration} mins",
                              style: AppTypography.textSM.copyWith(color: Colors.grey, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),

                      // Nút Book
                      ElevatedButton(
                        onPressed: () => _navigateToDetail(context, service, showMessage: true),
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}