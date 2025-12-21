import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Cần thêm package này vào pubspec.yaml
import '../../models/store_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class LocationTab extends StatelessWidget {
  final Store store;
  const LocationTab({super.key, required this.store});

  // Hàm xử lý mở bản đồ để chỉ đường
  Future<void> _launchNavigation() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${store.location?.latitude},${store.location?.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

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
              _buildSectionTitle("Store Location"),
              Text(
                "${store.distance.toStringAsFixed(1)} km from you",
                style: AppTypography.textSM.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. BẢN ĐỒ VỚI NÚT CHỈ ĐƯỜNG MÔ PHỎNG
          if (store.location != null)
            Stack(
              children: [
                Container(
                  height: 250, // Tăng chiều cao để bản đồ nổi bật hơn
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(store.location!.latitude, store.location!.longitude),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(store.id),
                          position: LatLng(store.location!.latitude, store.location!.longitude),
                          infoWindow: InfoWindow(title: store.name),
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
                // NÚT GET DIRECTIONS NỔI TRÊN BẢN ĐỒ
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _launchNavigation,
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text("Get Directions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    elevation: 4,
                  ),
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          const SizedBox(height: 24),

          // 2. THÔNG TIN LIÊN HỆ (Giữ nguyên giao diện đẹp của bạn)
          _buildSectionTitle("Contact Information"),
          const SizedBox(height: 12),
          _buildContactInfoTile(Icons.location_on, store.address, "Address"),
          _buildContactInfoTile(Icons.phone, store.hotline, "Hotline"),
          _buildContactInfoTile(Icons.email, store.email, "Email"),
          _buildContactInfoTile(Icons.language, store.website, "Website"),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildSectionTitle(String title) => Text(
      title,
      style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)
  );

  Widget _buildContactInfoTile(IconData icon, String value, String label) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey[500])),
                Text(value, style: AppTypography.textSM.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}