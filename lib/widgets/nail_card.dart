import 'package:applamdep/models/nail_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../ui/detail/nail_detail_screen.dart';

class NailCard extends StatefulWidget {
  final Nail nail;

  const NailCard({
    Key? key,
    required this.nail,
  }) : super(key: key);

  @override
  State<NailCard> createState() => _NailCardState();
}

class _NailCardState extends State<NailCard> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _toggleLike() async {
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final nailRef = firestore.collection('nails').doc(widget.nail.id);
    final wishlistDocId = '${user!.uid}_${widget.nail.id}';
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
            'nail_id': widget.nail.id,
            'created_at': FieldValue.serverTimestamp(),
            'name': widget.nail.name,
            'price': widget.nail.price,
            'img_url': widget.nail.imgUrl,
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
    final Color accentColor = widget.nail.isBestChoice ? const Color(0xFFE53935) : const Color(0xFFF25278);
    final Color shadowColor = widget.nail.isBestChoice ? Colors.red.withOpacity(0.25) : const Color(0xFF9098B1).withOpacity(0.15);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => NailDetailScreen(nail: widget.nail)),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: widget.nail.isBestChoice ? Border.all(color: accentColor.withOpacity(0.7), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: Image.asset(
                        widget.nail.imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
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
                            .doc('${user?.uid}_${widget.nail.id}')
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
                if (widget.nail.isBestChoice)
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
                        boxShadow: [
                           BoxShadow(
                             color: accentColor.withOpacity(0.3),
                             blurRadius: 8,
                             offset: const Offset(2, 2)
                           )
                        ]
                      ),
                      child: const Text(
                        'BEST',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nail.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Urbanist',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1E2022),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$${widget.nail.price}',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: widget.nail.isBestChoice ? Colors.amber[600] : const Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.nail.likes}',
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
