import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class StoreCard extends StatefulWidget {
  final String storeId;
  final Map<String, dynamic> storeData;
  final bool isSearchResult;
  final VoidCallback? onBookmarkChanged;

  const StoreCard({
    Key? key,
    required this.storeId,
    required this.storeData,
    this.isSearchResult = false,
    this.onBookmarkChanged,
  }) : super(key: key);

  @override
  _StoreCardState createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _currentUser;
  bool _isBookmarked = false;
  bool _isProcessing = false;
  StreamSubscription<QuerySnapshot>? _bookmarkSubscription;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _checkIfBookmarked();
    }
  }

  void _checkIfBookmarked() {
    _bookmarkSubscription?.cancel();

    _bookmarkSubscription = _firestore
        .collection('wishlist_store')
        .where('user_id', isEqualTo: _currentUser!.uid)
        .where('store_id', isEqualTo: widget.storeId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _isBookmarked = snapshot.docs.isNotEmpty;
        });
      }
    });
  }

  Future<void> _toggleBookmark() async {
    if (_currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để lưu cửa hàng'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final wishlistQuery = _firestore
          .collection('wishlist_store')
          .where('user_id', isEqualTo: _currentUser!.uid)
          .where('store_id', isEqualTo: widget.storeId);

      final existingDocs = await wishlistQuery.get();

      if (existingDocs.docs.isNotEmpty) {
        await existingDocs.docs.first.reference.delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã xóa khỏi danh sách yêu thích'),
              duration: const Duration(seconds: 1),
              action: SnackBarAction(
                label: 'Hoàn tác',
                onPressed: () => _undoBookmarkRemoval(),
              ),
            ),
          );
        }
      } else {
        await _firestore.collection('wishlist_store').add({
          'user_id': _currentUser!.uid,
          'store_id': widget.storeId,
          'store_name': widget.storeData['name'] ?? '',
          'store_image': widget.storeData['img_url'] ?? '',
          'created_at': Timestamp.now(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm vào danh sách yêu thích'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      widget.onBookmarkChanged?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _undoBookmarkRemoval() async {
    try {
      await _firestore.collection('wishlist_store').add({
        'user_id': _currentUser!.uid,
        'store_id': widget.storeId,
        'store_name': widget.storeData['name'] ?? '',
        'store_image': widget.storeData['img_url'] ?? '',
        'created_at': Timestamp.now(),
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _bookmarkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.storeData['name'] ?? 'Chưa có tên';
    final String address = widget.storeData['address'] ?? 'Chưa có địa chỉ';
    final String imgUrl = widget.storeData['img_url']?.toString() ?? '';
    final double? rating = widget.storeData['rating']?.toDouble();
    final int? reviewCount = widget.storeData['review_count']?.toInt();

    // DEBUG: Kiểm tra data
    // print('StoreCard - ID: ${widget.storeId}, Name: $name, Image: $imgUrl');

    if (widget.isSearchResult) {
      return _buildSearchResultCard(name, address, imgUrl, rating, reviewCount);
    }

    return _buildStandardCard(name, address, imgUrl, rating, reviewCount);
  }

  Widget _buildSearchResultCard(
      String name,
      String address,
      String imgUrl,
      double? rating,
      int? reviewCount,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Image - Sử dụng phương thức mới
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildStoreImage(imgUrl, 80),
            ),
            const SizedBox(width: 12),

            // Store Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2022),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildBookmarkButton(),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (rating != null && reviewCount != null)
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount đánh giá)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
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

  Widget _buildStandardCard(
      String name,
      String address,
      String imgUrl,
      double? rating,
      int? reviewCount,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E2E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildStoreImage(imgUrl, 150),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _buildBookmarkButton(
                  size: 28,
                  padding: 4,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (rating != null && reviewCount != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount đánh giá)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (widget.storeData['distance'] != null)
                        Text(
                          '${widget.storeData['distance'].toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================= PHƯƠNG THỨC MỚI =======================
  // Xử lý cả asset và network images
  Widget _buildStoreImage(String imgUrl, double height) {
    if (imgUrl.isEmpty) {
      return _buildPlaceholderImage(height);
    }

    // Kiểm tra loại image
    final isAssetImage = imgUrl.startsWith('assets/');
    final isNetworkImage = imgUrl.startsWith('http') || imgUrl.startsWith('https');

    if (isNetworkImage) {
      // Network image
      return Image.network(
        imgUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Network image error: $error for URL: $imgUrl');
          return _buildPlaceholderImage(height);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder(height);
        },
      );
    } else if (isAssetImage) {
      // Asset image
      return Image.asset(
        imgUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Asset image error: $error for path: $imgUrl');
          return _buildPlaceholderImage(height);
        },
      );
    } else {
      // Invalid image path
      print('Invalid image path: $imgUrl');
      return _buildPlaceholderImage(height);
    }
  }

  Widget _buildLoadingPlaceholder(double height) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildBookmarkButton({double size = 24, double padding = 0}) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isProcessing
          ? SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.amber.shade700,
          ),
        ),
      )
          : IconButton(
        iconSize: size,
        padding: EdgeInsets.zero,
        icon: Icon(
          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: _isBookmarked ? Colors.amber.shade700 : Colors.grey.shade600,
        ),
        onPressed: _toggleBookmark,
      ),
    );
  }

  Widget _buildPlaceholderImage(double height) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: height * 0.3,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Store Image',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}