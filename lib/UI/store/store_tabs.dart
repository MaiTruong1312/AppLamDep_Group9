import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/store_model.dart';
import '../../models/review_model.dart';
import '../../models/service_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/store_provider.dart';

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

class ReviewsTab extends StatelessWidget {
  final Store store;
  const ReviewsTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Phần tóm tắt Rating (Rating Summary)
        _buildRatingSummaryHeader(store),
        const Divider(height: 40, color: Color(0xFFF3F4F6)),
        OutlinedButton.icon(
          onPressed: () => _showReviewBottomSheet(context, store),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text("Review this store"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        // 2. DANH SÁCH ĐÁNH GIÁ THỰC TẾ
        if (store.reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("Chưa có đánh giá nào cho cửa hàng này."),
            ),
          )
        else
        // Lặp qua danh sách reviews trong đối tượng store
          ...store.reviews.map((review) => _buildReviewItem(review)).toList(),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // HIỂN THỊ ẢNH NGƯỜI DÙNG
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                // Nếu review có thông tin photoUrl của người dùng
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HIỂN THỊ TÊN NGƯỜI DÙNG
                  Text(
                    "${review.userId.length > 5 ? review.userId.substring(0, 5) : review.userId}",
                    style: AppTypography.textSM.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // HIỂN THỊ NGÀY ĐĂNG
                  Text(
                    "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                    style: AppTypography.textXS.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              // HIỂN THỊ SỐ SAO ĐÁNH GIÁ
              Row(
                children: List.generate(
                  5,
                      (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // NỘI DUNG BÌNH LUẬN
          Text(
            review.comment,
            style: AppTypography.textSM.copyWith(height: 1.5, color: Colors.black87),
          ),
          // HIỂN THỊ ẢNH ĐÍNH KÈM (Nếu có)
          if (review.mediaUrl != null && review.mediaUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  review.mediaUrl!,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Hàm phụ trợ hiển thị Header Rating
  Widget _buildRatingSummaryHeader(Store store) {
    Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (Review r in store.reviews) {
      int s = r.rating.toInt();
      counts[s] = (counts[s] ?? 0) + 1;
    }
    int total = store.reviews.length;

    return Row(
      children: [
        Column(
          children: [
            Text(store.rating.toString(), style: AppTypography.headlineLG.copyWith(fontSize: 48)),
            Row(
              children: List.generate(5, (i) => Icon(
                  i < store.rating.floor() ? Icons.star : Icons.star_border,
                  color: Colors.amber, size: 18)
              ),
            ),
            const SizedBox(height: 8),
            Text("${store.reviewsCount} Reviews", style: AppTypography.textXS.copyWith(color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 30),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              double value = total > 0 ? (counts[star] ?? 0) / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text("$star", style: AppTypography.textXS),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey[100],
                        color: AppColors.primary,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
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

  // Hàm gửi đánh giá và cập nhật điểm số chuyên nghiệp
  Future<void> _submitReview(BuildContext context, Store store, double userRating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập để đánh giá")));
      return;
    }

    // Công thức tính Rating trung bình mới
    // NewRating = ((OldRating * OldCount) + UserRating) / (OldCount + 1)
    int newCount = store.reviewsCount + 1;
    double newRating = ((store.rating * store.reviewsCount) + userRating) / newCount;

    Map<String, dynamic> newReviewData = {
      'user_id': user.uid,
      'rating': userRating,
      'comment': comment,
      'created_at': Timestamp.now(), // Cần import cloud_firestore
      'media_url': null,
    };

    try {
      // 1. Cập nhật dữ liệu lên Firestore
      await FirebaseFirestore.instance.collection('stores').doc(store.id).update({
        'review_count': newCount,
        'rating': double.parse(newRating.toStringAsFixed(1)), // Làm tròn chuẩn 1 chữ số
        'reviews': FieldValue.arrayUnion([newReviewData]),
      });

      // 2. LOGIC QUAN TRỌNG: Làm mới dữ liệu trong Provider ngay lập tức
      await Provider.of<StoreProvider>(context, listen: false).fetchStore(store.id);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cảm ơn bạn đã đánh giá!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
    }
  }

  void _showReviewBottomSheet(BuildContext context, Store store) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder( // Dùng StatefulBuilder để cập nhật số sao khi nhấn
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Đánh giá của bạn", style: AppTypography.labelLG),
              const SizedBox(height: 16),
              // Hàng chọn sao
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () => setModalState(() => selectedRating = index + 1.0),
                  icon: Icon(Icons.star, color: index < selectedRating ? Colors.amber : Colors.grey[300], size: 32),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: "Nhập cảm nhận của bạn...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _submitReview(context, store, selectedRating, commentController.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Gửi đánh giá", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

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