import 'package:applamdep/models/nail_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ui/detail/nail_detail_screen.dart';

class NailCard extends StatelessWidget {
  final Nail nail;

  const NailCard({
    Key? key,
    required this.nail,
  }) : super(key: key);

  Future<void> _toggleLike(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thích sản phẩm.')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final nailRef = firestore.collection('nails').doc(nail.id);
    final wishlistDocId = '${user.uid}_${nail.id}';
    final wishlistRef = firestore.collection('wishlist_nail').doc(wishlistDocId);

    try {
      await firestore.runTransaction((transaction) async {
        final wishlistSnapshot = await transaction.get(wishlistRef);
        final nailSnapshot = await transaction.get(nailRef);

        if (!nailSnapshot.exists) return;

        int currentLikes = nailSnapshot.data()?['likes'] ?? 0;

        if (wishlistSnapshot.exists) {
          transaction.delete(wishlistRef);
          transaction.update(nailRef, {'likes': (currentLikes - 1).clamp(0, 999999)});
        } else {
          transaction.set(wishlistRef, {
            'user_id': user.uid,
            'nail_id': nail.id,
            'created_at': FieldValue.serverTimestamp(),
            'name': nail.name,
            'price': nail.price,
            'img_url': nail.imgUrl,
          });
          transaction.update(nailRef, {'likes': currentLikes + 1});
        }
      });
    } catch (e) {
      debugPrint("Lỗi khi like: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final Color accentColor = nail.isBestChoice ? const Color(0xFFE53935) : const Color(0xFFF25278);
    final Color shadowColor = nail.isBestChoice ? Colors.red.withOpacity(0.25) : const Color(0xFF9098B1).withOpacity(0.15);

    final imageUrl = nail.imgUrl;
    final imageProvider = imageUrl.startsWith('assets/')
        ? AssetImage(imageUrl) as ImageProvider
        : NetworkImage(imageUrl);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NailDetailScreen(nail: nail)),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: nail.isBestChoice ? Border.all(color: accentColor.withOpacity(0.7), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _toggleLike(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: user != null
                              ? FirebaseFirestore.instance.collection('wishlist_nail').doc('${user.uid}_${nail.id}').snapshots()
                              : null,
                          builder: (context, snapshot) {
                            bool isLiked = user != null && snapshot.hasData && snapshot.data!.exists;
                            return Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isLiked ? const Color(0xFFFF4747) : const Color(0xFFDBDEE4),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (nail.isBestChoice)
                    Positioned(
                      top: 18,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'BEST',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nail.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1E2022),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(nail.price),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            nail.likes.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF777E90),
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
