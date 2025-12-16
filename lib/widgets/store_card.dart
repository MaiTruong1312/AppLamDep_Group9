import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StoreCard extends StatefulWidget {
  final String storeId;
  final Map<String, dynamic> storeData;

  const StoreCard({
    Key? key,
    required this.storeId,
    required this.storeData,
  }) : super(key: key);

  @override
  _StoreCardState createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _currentUser;
  bool _isBookmarked = false;
  bool _isProcessing = false; // To prevent rapid-fire clicks

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _checkIfBookmarked();
    }
  }

  // Check if the store is already in the user's wishlist
  void _checkIfBookmarked() {
    _firestore
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

  // Toggle the bookmark status
  Future<void> _toggleBookmark() async {
    if (_currentUser == null) {
      // Handle case where user is not logged in, maybe show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save to wishlist')),
      );
      return;
    }
    if (_isProcessing) return; // Prevent multiple simultaneous requests

    setState(() {
      _isProcessing = true;
    });

    final wishlistQuery = _firestore
        .collection('wishlist_store')
        .where('user_id', isEqualTo: _currentUser!.uid)
        .where('store_id', isEqualTo: widget.storeId);

    final existingDocs = await wishlistQuery.get();

    try {
      if (existingDocs.docs.isNotEmpty) {
        // It's already bookmarked, so remove it
        for (var doc in existingDocs.docs) {
          await doc.reference.delete();
        }
      } else {
        // It's not bookmarked, so add it
        await _firestore.collection('wishlist_store').add({
          'user_id': _currentUser!.uid,
          'store_id': widget.storeId,
          'created_at': Timestamp.now(),
        });
      }
    } catch (e) {
      // Handle potential errors
    }


    if (mounted) {
      setState(() {
        _isProcessing = false;
        // The state of _isBookmarked is updated by the stream listener,
        // but we can set it here for immediate feedback
        _isBookmarked = !_isBookmarked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.storeData['name'] ?? 'No Name';
    final String address = widget.storeData['address'] ?? 'No Address';
    final String imgUrl = widget.storeData['img_url'] ?? 'assets/images/store1.png';

    return Container(
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Image.asset(
              imgUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 166,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Using a GestureDetector on an Icon for more control
                    GestureDetector(
                      onTap: _toggleBookmark,
                      child: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: _isBookmarked ? Colors.amber : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
