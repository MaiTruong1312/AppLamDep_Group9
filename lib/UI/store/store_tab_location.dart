import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/store_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

Widget _buildSectionTitle(String title) => Text(title, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800));

class LocationTab extends StatelessWidget {
  final Store store;
  const LocationTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle("Location"),
              // THÊM: Khoảng cách từ vị trí HVNH đến tiệm
              Text(
                "Away from you: ${store.distance.toStringAsFixed(1)} km",
                style: AppTypography.textSM.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. BẢN ĐỒ ĐỘNG CHÍNH XÁC
          if (store.location != null)
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(store.location!.latitude, store.location!.longitude),
                    zoom: 16, // Zoom gần để thấy rõ đường Lý Quốc Sư
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(store.id),
                      position: LatLng(store.location!.latitude, store.location!.longitude),
                      infoWindow: InfoWindow(title: store.name, snippet: store.address),
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            )
          else
            const Center(child: Text("Đang tải vị trí...")),

          const SizedBox(height: 24),

          // 2. THÔNG TIN LIÊN HỆ
          _buildContactInfoTile(Icons.location_on, store.address, "Address"),
          _buildContactInfoTile(Icons.phone, store.hotline, "Hotline"),
          _buildContactInfoTile(Icons.email, store.email, "Email"),
          _buildContactInfoTile(Icons.language, store.website, "Website"),

          const SizedBox(height: 32),

          // 3. GIỜ MỞ CỬA CHI TIẾT
          _buildSectionTitle("Opening Hours"),
          const SizedBox(height: 12),
          _buildOpeningHoursTable(store.openingHours),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Widget hỗ trợ hiển thị dòng liên hệ
  Widget _buildContactInfoTile(IconData icon, String value, String label) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey)),
                Text(value, style: AppTypography.textSM.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị bảng giờ mở cửa
  Widget _buildOpeningHoursTable(Map<String, dynamic> hours) {
    if (hours.isEmpty) return const Text("Thông tin đang được cập nhật...");
    final days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: days.map((day) {
          final time = hours[day];
          final isToday = DateTime.now().weekday == (days.indexOf(day) + 1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day[0].toUpperCase() + day.substring(1),
                    style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? AppColors.primary : Colors.black87)),
                Text(time != null ? "${time['open']} - ${time['close']}" : "Closed",
                    style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Widget hiển thị Hotline, Email, Website
Widget _buildContactInfoSection(Store store) {
  return Column(
    children: [
      _buildContactTile(Icons.location_on, store.address, "Address"),
      _buildContactTile(Icons.phone, store.hotline, "Hotline"),
      _buildContactTile(Icons.email, store.email, "Email"),
      _buildContactTile(Icons.language, store.website, "Website"),
    ],
  );
}

Widget _buildContactTile(IconData icon, String value, String label) {
  if (value.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey)),
              Text(value, style: AppTypography.textSM.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

// Widget hiển thị danh sách giờ mở cửa từ Monday -> Sunday
Widget _buildOpeningHoursList(Map<String, dynamic> hours) {
  if (hours.isEmpty) return const Text("Thông tin đang được cập nhật...");

  final days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: days.map((day) {
        final time = hours[day];
        final isToday = DateTime.now().weekday == (days.indexOf(day) + 1);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  day[0].toUpperCase() + day.substring(1),
                  style: AppTypography.textSM.copyWith(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppColors.primary : Colors.black87
                  )
              ),
              Text(
                  time != null ? "${time['open']} - ${time['close']}" : "Closed",
                  style: AppTypography.textSM.copyWith(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}