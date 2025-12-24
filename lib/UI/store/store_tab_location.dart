import 'package:flutter/material.dart';
// Package chính thức của Google để nhúng bản đồ tương tác vào Flutter
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Package để mở URL bên ngoài (ở đây dùng để mở Google Maps app hoặc trình duyệt)
import 'package:url_launcher/url_launcher.dart';
// Cần thêm vào pubspec.yaml: url_launcher: ^6.3.0

import '../../models/store_model.dart'; // Model chứa thông tin tiệm (bao gồm location GeoPoint và distance)
import '../../theme/app_colors.dart';     // File theme định nghĩa màu sắc ứng dụng (primary là hồng chủ đạo)
import '../../theme/app_typography.dart'; // File theme định nghĩa font size, weight, style

/// Widget hiển thị tab "Contact/Location" trong trang chi tiết tiệm
/// Nhiệm vụ chính:
/// - Hiển thị bản đồ Google Maps với marker vị trí tiệm
/// - Hiển thị khoảng cách từ người dùng đến tiệm
/// - Cung cấp nút chỉ đường nhanh mở Google Maps
/// - Hiển thị thông tin liên hệ (địa chỉ, hotline, email, website)
class LocationTab extends StatelessWidget {
  final Store store; // Thông tin tiệm được truyền từ màn hình cha (StoreDetails)

  const LocationTab({super.key, required this.store});

  /// Hàm mở ứng dụng Google Maps (hoặc trình duyệt) để chỉ đường từ vị trí hiện tại
  /// của người dùng đến tiệm. Sử dụng deep link của Google Maps với tham số:
  /// - destination: tọa độ latitude,longitude của tiệm
  /// - travelmode=driving: chế độ lái xe (có thể thay bằng walking, bicycling...)
  /// mode: LaunchMode.externalApplication → ưu tiên mở app Google Maps nếu có
  Future<void> _launchNavigation() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${store.location?.latitude},${store.location?.longitude}&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Nếu không mở được (hiếm xảy ra), ném lỗi để debug
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Cho phép cuộn khi nội dung dài (đặc biệt trên màn hình nhỏ)
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------- TIÊU ĐỀ + KHOẢNG CÁCH -------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tiêu đề phần vị trí
              _buildSectionTitle("Store Location"),
              // Hiển thị khoảng cách đã được tính sẵn trong StoreProvider (km, 1 chữ số thập phân)
              Text(
                "${store.distance.toStringAsFixed(1)} km from you",
                style: AppTypography.textSM.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ------------------- BẢN ĐỒ GOOGLE MAPS -------------------
          // Chỉ hiển thị bản đồ khi có tọa độ (store.location != null)
          if (store.location != null)
            Stack(
              children: [
                // Container bao bọc bản đồ để tạo shadow và bo góc đẹp
                Container(
                  height: 250, // Chiều cao cố định để bản đồ nổi bật
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    // Bo góc bản đồ đồng bộ với container
                    borderRadius: BorderRadius.circular(24),
                    child: GoogleMap(
                      // Vị trí ban đầu của camera: zoom vào tiệm với mức zoom 15 (phóng to vừa đủ)
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          store.location!.latitude,
                          store.location!.longitude,
                        ),
                        zoom: 15,
                      ),
                      // Thêm một marker duy nhất tại vị trí tiệm
                      markers: {
                        Marker(
                          markerId: MarkerId(store.id), // ID duy nhất của marker
                          position: LatLng(
                            store.location!.latitude,
                            store.location!.longitude,
                          ),
                          infoWindow: InfoWindow(title: store.name), // Hiển thị tên tiệm khi nhấn marker
                        ),
                      },
                      // Tắt nút "My Location" và zoom controls để giao diện sạch hơn
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),

                // ------------------- NÚT "GET DIRECTIONS" NỔI -------------------
                // Nút FAB extended nằm chồng lên bản đồ (góc dưới phải)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _launchNavigation, // Gọi hàm mở Google Maps chỉ đường
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text(
                      "Get Directions",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    elevation: 4, // Đổ bóng nhẹ để nút nổi hơn
                  ),
                ),
              ],
            )
          else
          // Nếu chưa có tọa độ (hiếm), hiển thị loading
            const Center(child: CircularProgressIndicator()),

          const SizedBox(height: 24),

          // ------------------- THÔNG TIN LIÊN HỆ -------------------
          _buildSectionTitle("Contact Information"),
          const SizedBox(height: 12),

          // Các tile thông tin liên hệ (chỉ hiển thị nếu có dữ liệu)
          _buildContactInfoTile(Icons.location_on, store.address, "Address"),
          _buildContactInfoTile(Icons.phone, store.hotline, "Hotline"),
          _buildContactInfoTile(Icons.email, store.email, "Email"),
          _buildContactInfoTile(Icons.language, store.website, "Website"),

          // Khoảng trống cuối để tránh bị che bởi BottomNavigationBar (nếu có)
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ------------------- HELPER WIDGETS -------------------

  /// Widget tạo tiêu đề phần (Store Location, Contact Information)
  /// Sử dụng style label lớn, đậm và letter-spacing nhẹ để hiện đại
  Widget _buildSectionTitle(String title) => Text(
    title,
    style: AppTypography.labelLG.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
  );

  /// Widget tạo một dòng thông tin liên hệ (icon + label + value)
  /// Nếu value rỗng → ẩn hoàn toàn để tránh khoảng trống thừa
  Widget _buildContactInfoTile(IconData icon, String value, String label) {
    if (value.isEmpty) return const SizedBox.shrink(); // Không hiển thị nếu không có dữ liệu

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Icon tròn nền nhạt màu primary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          // Phần text: label nhỏ xám + value đậm đen
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.textXS.copyWith(color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: AppTypography.textSM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}