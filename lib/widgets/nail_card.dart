import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../ui/detail/nail_detail_screen.dart';

class NailCard extends StatefulWidget {
  final String nailId;
  final Map<String, dynamic> productData;

  const NailCard({
    Key? key,
    required this.nailId,
    required this.productData,
  }) : super(key: key);

  @override
  State<NailCard> createState() => _NailCardState();
}

class _NailCardState extends State<NailCard> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- LOGIC GIỮ NGUYÊN ---
  Future<void> _toggleLike() async {
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final nailRef = firestore.collection('nails').doc(widget.nailId);
    final wishlistDocId = '${user!.uid}_${widget.nailId}';
    final wishlistRef = firestore.collection('wishlist_nail').doc(wishlistDocId);

    try {
      await firestore.runTransaction((transaction) async {
        final wishlistSnapshot = await transaction.get(wishlistRef);
        final nailSnapshot = await transaction.get(nailRef);

        if (!nailSnapshot.exists) return;

        int currentLikes = nailSnapshot.data()?['likes'] ?? 0;

        if (wishlistSnapshot.exists) {
          transaction.delete(wishlistRef);
          transaction.update(nailRef, {'likes': currentLikes - 1});
        } else {
          transaction.set(wishlistRef, {
            'user_id': user!.uid,
            'nail_id': widget.nailId,
            'created_at': FieldValue.serverTimestamp(),
            'name': widget.productData['name'],
            'price': widget.productData['price'],
            'img_url': widget.productData['img_url'],
          });
          transaction.update(nailRef, {'likes': currentLikes + 1});
        }
      });
    } catch (e) {
      debugPrint("Lỗi khi like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ép kiểu dữ liệu an toàn
    final String name = widget.productData['name'] ?? 'No Name';
    final String imgUrl = widget.productData['img_url'] ?? 'assets/images/nail1.png';
    final int price = widget.productData['price'] is int
        ? widget.productData['price']
        : int.tryParse(widget.productData['price'].toString()) ?? 0;
    final int likes = widget.productData['likes'] is int
        ? widget.productData['likes']
        : int.tryParse(widget.productData['likes'].toString()) ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => NailDetailScreen(nailId: widget.nailId)),
        );
      },
      child: Container(
        width: 170, // Chiều rộng cố định hợp lý
        margin: const EdgeInsets.only(bottom: 8), // Khoảng cách nhẹ dưới chân để bóng không bị cắt
        decoration: BoxDecoration(
          color: Colors.white, // Nền trắng tinh khôi
          borderRadius: BorderRadius.circular(24), // Bo góc tròn mềm mại hơn
          boxShadow: [
            // Bóng đổ mềm mại, sang trọng
            BoxShadow(
              color: const Color(0xFF9098B1).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PHẦN ẢNH VÀ NÚT TIM ---
            Stack(
              children: [
                // Ảnh sản phẩm
                Padding(
                  padding: const EdgeInsets.all(8.0), // Padding nhỏ để ảnh nằm gọn trong khung
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1 / 1, // Tỉ lệ khung hình vuông (Instagram style)
                      child: Image.asset(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),

                // Nút tim (Floating)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9), // Bán trong suốt
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('wishlist_nail')
                            .doc('${user?.uid}_${widget.nailId}')
                            .snapshots(),
                        builder: (context, snapshot) {
                          bool isLiked = snapshot.hasData && snapshot.data!.exists;
                          return Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isLiked ? const Color(0xFFFF4747) : const Color(0xFFDBDEE4),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --- 2. PHẦN THÔNG TIN ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Urbanist', // Nếu có font này thì đẹp, không thì mặc định
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1E2022), // Màu đen xám đậm
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 8), // Khoảng cách thoáng hơn

                  // Row chứa Giá và Số like
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Giá tiền
                      Text(
                        '\$$price',
                        style: const TextStyle(
                          color: Color(0xFFF25278), // Màu hồng chủ đạo
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      // Số lượt thích + Icon nhỏ
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text(
                            '$likes',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF777E90), // Màu xám trung tính
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}