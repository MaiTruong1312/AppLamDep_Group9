import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/store_model.dart';
import '../../models/review_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/store_provider.dart';

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