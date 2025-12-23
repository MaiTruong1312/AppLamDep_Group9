import 'dart:io'; // Để sử dụng File khi hiển thị ảnh preview từ thiết bị
import 'package:flutter/material.dart';
// Provider để gọi fetchStore() làm mới dữ liệu tiệm ngay lập tức sau khi gửi review
import 'package:provider/provider.dart';
// Firebase Auth để lấy UID người dùng hiện tại (ẩn danh hóa tên)
import 'package:firebase_auth/firebase_auth.dart';
// Firestore để lưu review vào mảng reviews của tiệm
import 'package:cloud_firestore/cloud_firestore.dart';
// ImagePicker để chọn ảnh từ thư viện điện thoại
import 'package:image_picker/image_picker.dart';

import '../../models/store_model.dart';   // Model Store chứa danh sách reviews và review_count
import '../../models/review_model.dart'; // Model Review (rating, comment, createdAt, mediaUrl...)
import '../../theme/app_colors.dart';     // Màu sắc ứng dụng (primary là hồng)
import '../../theme/app_typography.dart'; // Các style chữ đã định nghĩa sẵn
import '../../providers/store_provider.dart'; // Provider quản lý dữ liệu tiệm

/// Widget hiển thị tab "Reviews" trong trang chi tiết tiệm
/// Chức năng chính:
/// - Hiển thị tóm tắt rating trung bình và biểu đồ phân bố sao
/// - Hiển thị danh sách review (mới nhất lên đầu)
/// - Cho phép người dùng viết review mới kèm chọn sao, bình luận và ảnh
class ReviewsTab extends StatelessWidget {
  final Store store; // Thông tin tiệm được truyền từ StoreDetails
  const ReviewsTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16), // Khoảng cách đều 16dp quanh tab
      children: [
        // 1. Phần tóm tắt rating (tính tự động từ dữ liệu)
        _buildRatingSummaryHeader(store),
        const Divider(height: 40, color: Color(0xFFF3F4F6)), // Đường kẻ phân cách nhẹ
        // Nút viết review nổi bật
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
        // 2. Danh sách review
        if (store.reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No reviews yet."),
            ),
          )
        else
        // Sắp xếp review mới nhất lên đầu bằng .reversed
          ...store.reviews.reversed.map((review) => _buildReviewItem(review)).toList(),
      ],
    );
  }

  /// Widget tạo phần tóm tắt rating: điểm trung bình lớn + biểu đồ thanh ngang
  /// Tính toán hoàn toàn tự động từ danh sách review hiện tại
  Widget _buildRatingSummaryHeader(Store store) {
    // Đếm số lượng từng mức sao (1-5)
    Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double totalPoints = 0;

    // Duyệt qua từng review để tính toán
    for (Review r in store.reviews) {
      int s = r.rating.toInt();
      if (counts.containsKey(s)) counts[s] = counts[s]! + 1;
      totalPoints += r.rating;
    }

    int totalReviews = store.reviews.length;
    // Tính trung bình sao (làm tròn 1 chữ thập phân)
    double averageRating = totalReviews > 0 ? totalPoints / totalReviews : 0.0;

    return Row(
      children: [
        // Cột trái: điểm lớn + sao + tổng số review
        Column(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: AppTypography.headlineLG.copyWith(fontSize: 48),
            ),
            Row(
              children: List.generate(5, (i) => Icon(
                i < averageRating.floor() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$totalReviews Reviews",
              style: AppTypography.textXS.copyWith(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(width: 30),
        // Cột phải: biểu đồ thanh ngang cho từng mức sao
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              // Tỷ lệ phần trăm của mức sao này
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

  /// Widget hiển thị một review riêng lẻ
  Widget _buildReviewItem(Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar mặc định (ẩn danh)
              const CircleAvatar(radius: 20, child: Icon(Icons.person, size: 20)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị 5 ký tự đầu của userId để ẩn danh
                  Text(
                    review.userId.length > 5 ? review.userId.substring(0, 5) : review.userId,
                    style: AppTypography.textSM.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // Ngày review
                  Text(
                    "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                    style: AppTypography.textXS.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              // Hiển thị sao của review này
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
          // Nội dung bình luận
          Text(review.comment, style: AppTypography.textSM.copyWith(height: 1.5)),
          // Nếu có ảnh thì hiển thị (bo góc, kích thước vừa phải)
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Hàm gửi review lên Firestore và cập nhật UI tức thì
  /// - Tăng review_count bằng 1
  /// - Thêm review mới vào mảng reviews
  /// - Reload dữ liệu tiệm để UI tự động cập nhật
  Future<void> _submitReview(
      BuildContext context,
      Store store,
      double userRating,
      String comment,
      XFile? imageFile,
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Hiển thị loading toàn màn hình
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Chuẩn bị dữ liệu review mới
      Map<String, dynamic> newReviewData = {
        'user_id': user.uid,
        'rating': userRating,
        'comment': comment,
        'created_at': Timestamp.now(),
        'media_url': null, // Sẽ upload ảnh lên Storage ở giai đoạn sau
      };

      // Cập nhật document tiệm trong Firestore
      await FirebaseFirestore.instance.collection('stores').doc(store.id).update({
        'review_count': FieldValue.increment(1),
        'reviews': FieldValue.arrayUnion([newReviewData]),
      });

      // Cập nhật tức thì: gọi Provider để tải lại dữ liệu tiệm mới nhất
      if (context.mounted) {
        await Provider.of<StoreProvider>(context, listen: false).fetchStore(store.id);
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted!")),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint("Error: $e");
    }
  }

  /// Hiển thị Bottom Sheet để viết review
  /// Sử dụng StatefulBuilder để cập nhật UI trong modal (sao, ảnh preview)
  void _showReviewBottomSheet(BuildContext context, Store store) {
    double selectedRating = 5.0; // Mặc định 5 sao
    final commentController = TextEditingController();
    XFile? pickedImage; // Ảnh được chọn từ thư viện
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép mở rộng khi bàn phím hiện
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          // Đẩy nội dung lên trên bàn phím
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Your review", style: AppTypography.labelLG),
              const SizedBox(height: 16),
              // Chọn số sao
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (index) => IconButton(
                    onPressed: () => setModalState(() => selectedRating = index + 1.0),
                    icon: Icon(
                      Icons.star,
                      color: index < selectedRating ? Colors.amber : Colors.grey[300],
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Ô nhập bình luận
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: "Write your feeling...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Phần thêm ảnh (căn giữa)
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) setModalState(() => pickedImage = image);
                  },
                  child: pickedImage == null
                      ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined),
                        SizedBox(width: 8),
                        Text("Upload a picture"),
                      ],
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(pickedImage!.path),
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Nút gửi đánh giá
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _submitReview(context, store, selectedRating, commentController.text, pickedImage);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Send review",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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