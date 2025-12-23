// nail_card.dart
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/services/booking_cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ui/detail/nail_detail_screen.dart';

class NailCard extends StatefulWidget {
  final Nail nail;
  final Store? store;
  final Function()? onAddedToBookingCart;

  const NailCard({
    Key? key,
    required this.nail,
    this.store,
    this.onAddedToBookingCart,
  }) : super(key: key);

  @override
  State<NailCard> createState() => _NailCardState();
}

class _NailCardState extends State<NailCard> {
  final BookingCartService _bookingCartService = BookingCartService();
  bool _isAddingToCart = false;
  Store? _loadedStore; // Store được load độc lập
  bool _isLoadingStore = false;

  @override
  void initState() {
    super.initState();
    // Nếu không có store được truyền từ parent, tự load
    if (widget.store == null) {
      _loadStore();
    }
  }

  Future<void> _loadStore() async {
    if (widget.nail.storeId.isEmpty) return;

    setState(() {
      _isLoadingStore = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.nail.storeId)
          .get();

      if (doc.exists) {
        final store = Store.fromFirestore(doc);
        if (mounted) {
          setState(() {
            _loadedStore = store;
          });
        }
      } else {
        print('DEBUG: Store ${widget.nail.storeId} not found');
      }
    } catch (e) {
      print('DEBUG: Error loading store: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStore = false;
        });
      }
    }
  }

  // Sử dụng store từ widget hoặc từ _loadedStore
  Store? get _effectiveStore => widget.store ?? _loadedStore;

  // Phần còn lại của các phương thức giữ nguyên...
  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to like nail designs.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final nailRef = firestore.collection('nails').doc(widget.nail.id);
    final wishlistDocId = '${user.uid}_${widget.nail.id}';
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
          _showSnackBar('You unliked the nail design.');
        } else {
          transaction.set(wishlistRef, {
            'user_id': user.uid,
            'nail_id': widget.nail.id,
            'created_at': FieldValue.serverTimestamp(),
            'name': widget.nail.name,
            'price': widget.nail.price,
            'img_url': widget.nail.imgUrl,
          });
          transaction.update(nailRef, {'likes': currentLikes + 1});
          _showSnackBar('Đã thêm vào yêu thích');
        }
      });
    } catch (e) {
      debugPrint("Error when liking/unliking: $e");
      _showSnackBar('An error occurred: $e', isError: true);
    }
  }

  Future<void> _addToBookingCart() async {
    if (_isAddingToCart) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to schedule an appointment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('booking_cart')
          .doc(widget.nail.id)
          .get();

      if (cartSnapshot.exists) {
        _showSnackBar('This nail design is already on the booking list.');
        return;
      }

      await _bookingCartService.addToBookingCart(
        nailId: widget.nail.id,
        nailName: widget.nail.name,
        nailImage: widget.nail.imgUrl,
        price: widget.nail.price.toDouble(),
        storeId: widget.nail.storeId,
        storeName: _effectiveStore?.name ?? 'Undetermined', // Sử dụng effectiveStore
      );

      if (widget.onAddedToBookingCart != null) {
        widget.onAddedToBookingCart!();
      }

      _showSnackBar(
        '"${widget.nail.name}" has been added to the appointment list.',
        isSuccess: true,
        action: SnackBarAction(
          label: 'Look',
          onPressed: () {
            Navigator.pushNamed(context, '/booking_cart');
          },
        ),
      );
    } catch (e) {
      _showSnackBar('ERROR: $e', isError: true);
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false, SnackBarAction? action}) {
    Color backgroundColor = Colors.grey[800]!;
    if (isError) backgroundColor = Colors.red;
    if (isSuccess) backgroundColor = Colors.green;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    );

    final Color accentColor = widget.nail.isBestChoice
        ? const Color(0xFFE53935)
        : const Color(0xFFF25278);

    final Color shadowColor = widget.nail.isBestChoice
        ? Colors.red.withOpacity(0.25)
        : const Color(0xFF9098B1).withOpacity(0.15);

    final imageUrl = widget.nail.imgUrl;
    final imageProvider = imageUrl.startsWith('assets/')
        ? AssetImage(imageUrl) as ImageProvider
        : NetworkImage(imageUrl);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NailDetailScreen(
              nail: widget.nail,
              store: _effectiveStore, // Truyền effectiveStore
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: widget.nail.isBestChoice
              ? Border.all(color: accentColor.withOpacity(0.7), width: 1.5)
              : null,
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
            // Phần hình ảnh
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.photo_outlined,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Nút yêu thích
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
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: user != null
                              ? FirebaseFirestore.instance
                              .collection('wishlist_nail')
                              .doc('${user.uid}_${widget.nail.id}')
                              .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            bool isLiked = user != null &&
                                snapshot.hasData &&
                                snapshot.data!.exists;

                            return Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isLiked
                                  ? const Color(0xFFFF4747)
                                  : const Color(0xFFDBDEE4),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Nút thêm vào danh sách đặt lịch
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: _addToBookingCart,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF25278),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _isAddingToCart
                            ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                            : const Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Badge BEST CHOICE
                  if (widget.nail.isBestChoice)
                    Positioned(
                      top: 18,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(2, 0),
                            ),
                          ],
                        ),
                        child: const Text(
                          'BEST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Phần thông tin
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên mẫu nail
                  Text(
                    widget.nail.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1E2022),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Tên salon với loading state
                  if (_isLoadingStore)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _effectiveStore?.name ??
                          (widget.nail.storeId.isEmpty
                              ? 'Không có salon'
                              : 'Salon ID: ${widget.nail.storeId}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _effectiveStore != null
                            ? Colors.grey[600]
                            : Colors.orange[600],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Giá và số lượt thích
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Giá
                      Text(
                        currencyFormat.format(widget.nail.price),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      // Số lượt thích
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.nail.likes.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
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