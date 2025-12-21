import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
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
        // 1. Phần tóm tắt Rating (Tính toán tự động)
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
        // 2. Danh sách bình luận (Mới nhất lên đầu)
        if (store.reviews.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("No reviews yet.")))
        else
          ...store.reviews.reversed.map((review) => _buildReviewItem(review)).toList(),
      ],
    );
  }

  // LOGIC TÍNH RATING TỰ ĐỘNG ĐỂ KHỚP VỚI BIỂU ĐỒ
  Widget _buildRatingSummaryHeader(Store store) {
    Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double totalPoints = 0;

    for (Review r in store.reviews) {
      int s = r.rating.toInt();
      if (counts.containsKey(s)) counts[s] = counts[s]! + 1;
      totalPoints += r.rating;
    }

    int totalReviews = store.reviews.length;
    // Tự động tính trung bình thay vì lấy giá trị mặc định 4.7
    double averageRating = totalReviews > 0 ? totalPoints / totalReviews : 0.0;

    return Row(
      children: [
        Column(
          children: [
            Text(averageRating.toStringAsFixed(1), style: AppTypography.headlineLG.copyWith(fontSize: 48)),
            Row(
              children: List.generate(5, (i) => Icon(
                  i < averageRating.floor() ? Icons.star : Icons.star_border,
                  color: Colors.amber, size: 18)
              ),
            ),
            const SizedBox(height: 8),
            Text("$totalReviews Reviews", style: AppTypography.textXS.copyWith(color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 30),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              double value = totalReviews > 0 ? (counts[star] ?? 0) / totalReviews : 0.0;
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

  Widget _buildReviewItem(Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20, child: Icon(Icons.person, size: 20)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.userId.length > 5 ? review.userId.substring(0, 5) : review.userId, style: AppTypography.textSM.copyWith(fontWeight: FontWeight.bold)),
                  Text("${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}", style: AppTypography.textXS.copyWith(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              Row(children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment, style: AppTypography.textSM.copyWith(height: 1.5)),
          if (review.mediaUrl != null && review.mediaUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(review.mediaUrl!, height: 120, width: 120, fit: BoxFit.cover)),
            ),
        ],
      ),
    );
  }

  // LOGIC CẬP NHẬT TỨC THÌ SAO KHI GỬI
  Future<void> _submitReview(BuildContext context, Store store, double userRating, String comment, XFile? imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Hiển thị vòng quay loading
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      // 1. Chuẩn bị dữ liệu bình luận mới
      Map<String, dynamic> newReviewData = {
        'user_id': user.uid,
        'rating': userRating,
        'comment': comment,
        'created_at': Timestamp.now(),
        'media_url': null, // Chỗ này sẽ gán URL ảnh sau khi upload Storage
      };

      // 2. Gửi lên Firestore
      await FirebaseFirestore.instance.collection('stores').doc(store.id).update({
        'review_count': FieldValue.increment(1),
        'reviews': FieldValue.arrayUnion([newReviewData]),
      });

      // 3. CẬP NHẬT TỨC THÌ: Gọi Provider làm mới dữ liệu
      if (context.mounted) {
        await Provider.of<StoreProvider>(context, listen: false).fetchStore(store.id);
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted!")));
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint("Error: $e");
    }
  }

  void _showReviewBottomSheet(BuildContext context, Store store) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();
    XFile? pickedImage;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Đánh giá của bạn", style: AppTypography.labelLG),
              const SizedBox(height: 16),
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
                decoration: InputDecoration(hintText: "Cảm nhận...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // PHẦN UP ẢNH MỚI THÊM & SỬA LỖI ALIGN
              Align(
                alignment: Alignment.center, // FIX: Đổi từ CrossAxisAlignment sang Alignment
                child: GestureDetector(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) setModalState(() => pickedImage = image);
                  },
                  child: pickedImage == null
                      ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.camera_alt_outlined), SizedBox(width: 8), Text("Thêm hình ảnh")]),
                  )
                      : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(pickedImage!.path), height: 100, width: 100, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _submitReview(context, store, selectedRating, commentController.text, pickedImage);
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