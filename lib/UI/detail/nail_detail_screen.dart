import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/review_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/models/user_model.dart';
import 'package:applamdep/widgets/nail_card.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:applamdep/UI/booking/booking_screen.dart';
class NailDetailScreen extends StatefulWidget {
  final Nail nail;
  final Store? store;
  const NailDetailScreen({Key? key, required this.nail,this.store,}) : super(key: key);

  @override
  _NailDetailScreenState createState() => _NailDetailScreenState();
}

class _CountdownTimer extends StatefulWidget {
  @override
  __CountdownTimerState createState() => __CountdownTimerState();
}

class __CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  Duration _duration = Duration(hours: 1, minutes: 30, seconds: 0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _duration = _duration - Duration(seconds: 1);
        if (_duration.isNegative) {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_duration.inHours);
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeCard(hours, ' h'),
        SizedBox(width: 5),
        _buildTimeCard(minutes, ' m'),
        SizedBox(width: 5),
        _buildTimeCard(seconds, ' s'),
      ],
    );
  }

  Widget _buildTimeCard(String time, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        time + label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.pink,
          fontSize: 14,
        ),
      ),
    );
  }
}

// Clipper để tạo đường cong bo góc
class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final curveHeight = 40.0;

    path.lineTo(0, size.height - curveHeight);
    path.quadraticBezierTo(
        size.width / 2,
        size.height,
        size.width,
        size.height - curveHeight
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
class _NailDetailScreenState extends State<NailDetailScreen> {
  final picker = ImagePicker();
  File? _imageFile;

  // --- LOGIC HELPERS ---

  void _showReviewDialog() {
    double _rating = 0;
    final _commentController = TextEditingController();
    _imageFile = null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header với close button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Viết đánh giá',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 24),

                            // Phần rating - Glass card
                            // Phần rating với stars - SỬA LẠI
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Bạn đánh giá thế nào?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Container(
                                      constraints: BoxConstraints(maxWidth: 300),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: List.generate(5, (index) {
                                          return GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                _rating = index + 1.0;
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(
                                                index < _rating
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                                size: 36,
                                                color: index < _rating
                                                    ? Colors.amber.shade300
                                                    : Colors.white.withOpacity(0.6),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    if (_rating > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          '${_rating.toInt()}.0 sao',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber.shade300,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Phần comment - Glass card
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bình luận',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _commentController,
                                      maxLines: 4,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Chia sẻ trải nghiệm của bạn...',
                                        hintStyle: TextStyle(color: Colors.black26.withOpacity(0.5)),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 20),

                            // Phần thêm ảnh - Glass card
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thêm hình ảnh (tuỳ chọn)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () async {
                                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                      if (pickedFile != null) {
                                        setDialogState(() {
                                          _imageFile = File(pickedFile.path);
                                        });
                                      }
                                    },
                                    child: Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: _imageFile == null
                                          ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 40,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Thêm ảnh/video',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                          : ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 28),

                            // Nút gửi
                            Row(
                              children: [
                                // Nút hủy - Glass
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Hủy',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(width: 16),

                                // Nút gửi - Pink gradient
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Vui lòng đăng nhập để đánh giá.')),
                                        );
                                        return;
                                      }

                                      if (_rating == 0 || _commentController.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('Vui lòng chọn sao và viết bình luận.')),
                                        );
                                        return;
                                      }

                                      String? mediaUrl;
                                      if (_imageFile != null) {
                                        final cloudinary = CloudinaryPublic('dofkwgiv9', 'applamdep', cache: false);
                                        try {
                                          CloudinaryResponse response = await cloudinary.uploadFile(
                                            CloudinaryFile.fromFile(_imageFile!.path,
                                                resourceType: CloudinaryResourceType.Image),
                                          );
                                          mediaUrl = response.secureUrl;
                                        } on CloudinaryException catch (e) {
                                          print(e.message);
                                        }
                                      }

                                      await FirebaseFirestore.instance.collection('reviews').add({
                                        'nail_id': widget.nail.id,
                                        'user_id': user.uid,
                                        'rating': _rating,
                                        'comment': _commentController.text,
                                        'created_at': Timestamp.now(),
                                        'media_url': mediaUrl,
                                      });

                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đánh giá của bạn đã được gửi.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.pink.shade400.withOpacity(0.9),
                                            Colors.pink.shade600.withOpacity(0.9),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.pink.withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Gửi đánh giá',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// Helper function để tạo glass card
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // --- UI BUILD HELPERS ---
  Widget _buildImageHeader() {
    return SliverAppBar(
      expandedHeight: 450.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      // Bỏ leading và actions cũ, dùng flexibleSpace để tự vẽ nút
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.constrainHeight();
          final isExpanded = top > kToolbarHeight;
          final appBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Ảnh nền với hiệu ứng parallax
              Positioned.fill(
                child: Hero(
                  tag: widget.nail.id,
                  child: ClipPath(
                    clipper: _CurvedClipper(),
                    child: widget.nail.imgUrl.startsWith('http')
                        ? Image.network(
                      widget.nail.imgUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    )
                        : Image.asset(
                      widget.nail.imgUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              // Thanh navigation trên cùng
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nút back
                      _buildGlassButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                        iconColor: Colors.white,
                      ),

                      // Nhóm nút bên phải
                      Row(
                        children: [
                          // Nút share
                          _buildGlassButton(
                            icon: Icons.share_rounded,
                            onPressed: () {
                              // TODO: Share functionality
                            },
                            iconColor: Colors.white,
                          ),

                          SizedBox(width: 12),

                          // Nút favorite với stream để hiển thị trạng thái
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('wishlist_nail')
                                .doc('${FirebaseAuth.instance.currentUser?.uid}_${widget.nail.id}')
                                .snapshots(),
                            builder: (context, snapshot) {
                              bool isLiked = snapshot.hasData && snapshot.data!.exists;
                              return _buildGlassButton(
                                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                onPressed: _toggleLike,
                                iconColor: isLiked ? Colors.pink : Colors.white,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // // Indicator dots ở dưới (nếu có nhiều ảnh)
              // if (isExpanded)
              //   Positioned(
              //     bottom: 30,
              //     left: 0,
              //     right: 0,
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Container(
              //           width: 8,
              //           height: 8,
              //           margin: EdgeInsets.symmetric(horizontal: 4),
              //           decoration: BoxDecoration(
              //             color: Colors.white,
              //             borderRadius: BorderRadius.circular(4),
              //             boxShadow: [
              //               BoxShadow(
              //                 color: Colors.black.withOpacity(0.2),
              //                 blurRadius: 2,
              //                 spreadRadius: 1,
              //               ),
              //             ],
              //           ),
              //         ),
              //         Container(
              //           width: 8,
              //           height: 8,
              //           margin: EdgeInsets.symmetric(horizontal: 4),
              //           decoration: BoxDecoration(
              //             color: Colors.white.withOpacity(0.5),
              //             borderRadius: BorderRadius.circular(4),
              //             boxShadow: [
              //               BoxShadow(
              //                 color: Colors.black.withOpacity(0.2),
              //                 blurRadius: 2,
              //                 spreadRadius: 1,
              //               ),
              //             ],
              //           ),
              //         ),
              //         Container(
              //           width: 8,
              //           height: 8,
              //           margin: EdgeInsets.symmetric(horizontal: 4),
              //           decoration: BoxDecoration(
              //             color: Colors.white.withOpacity(0.5),
              //             borderRadius: BorderRadius.circular(4),
              //             boxShadow: [
              //               BoxShadow(
              //                 color: Colors.black.withOpacity(0.2),
              //                 blurRadius: 2,
              //                 spreadRadius: 1,
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
            ],
          );
        },
      ),
    );
  }

// Widget cho nút glassmorphism
  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
        ),
      ),
    );
  }

// Widget cho nút minimal (style tối giản)
  Widget _buildMinimalButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }

// Widget cho nút floating (style nổi)
  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.nail.storeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final store = Store.fromFirestore(snapshot.data!);
        final String imageUrl = store.imgUrl;

        ImageProvider imageProvider;
        if (imageUrl.isNotEmpty) {
          if (imageUrl.startsWith('http')) {
            imageProvider = NetworkImage(imageUrl);
          } else {
            imageProvider = AssetImage(imageUrl);
          }
        } else {
          imageProvider = const AssetImage('assets/images/default_store.png');
        }

        return Row(
          children: [
            CircleAvatar(
              backgroundImage: imageProvider,
              radius: 25,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text(store.address,
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              child: Text('Xem cửa hàng'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.pink,
                side: BorderSide(color: Colors.pink),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: Colors.pink, size: 20),
              SizedBox(width: 8),
              Text(
                'Mã giảm giá',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.pink.shade800),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Giảm 20% cho đơn hàng tiếp theo của bạn. Đừng bỏ lỡ!',
            style: TextStyle(color: Colors.black87),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kết thúc sau:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              _CountdownTimer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: Colors.grey[200], radius: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 100, color: Colors.grey[200]),
                SizedBox(height: 4),
                Container(height: 14, width: 80, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedReviewItem(Review review, UserModel? user) {
    final userName = user?.name ?? 'Người dùng ẩn danh';
    final userPhotoUrl = user?.photoUrl ?? 'https://i.pravatar.cc/150?u=${review.userId}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(userPhotoUrl),
                radius: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(
                          5,
                              (index) => Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          )),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(review.createdAt),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            ],
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 52.0),
            child: Text(review.comment, style: TextStyle(height: 1.5)),
          ),
          if (review.mediaUrl != null && review.mediaUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 52.0, top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  review.mediaUrl!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('nail_id', isEqualTo: widget.nail.id)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, reviewSnapshot) {
        if (reviewSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (reviewSnapshot.hasData) {
          print('Total reviews found: ${reviewSnapshot.data!.docs.length}');
          reviewSnapshot.data!.docs.forEach((doc) {
            print('Review doc ID: ${doc.id}');
            print('Review data: ${doc.data()}');
            print('Nail ID in review: ${doc['nail_id']}');
            print('Current nail ID: ${widget.nail.id}');
          });
        }
        if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              children: [
                Text('Chưa có đánh giá nào.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 16),
                Material(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showReviewDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.pink.shade400,
                            Colors.pink.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Viết đánh giá',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final reviewDocs = reviewSnapshot.data!.docs;
        final reviews = reviewDocs
            .map((doc) => Review.fromFirestore(doc))
            .where((r) => r.userId.isNotEmpty)
            .toList();

        if (reviews.isEmpty) {
            return Center(
              child: Column(
              children: [
                Text('Chưa có đánh giá nào.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showReviewDialog,
                  icon: Icon(Icons.rate_review),
                  label: Text('Viết đánh giá'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                )
              ],
            ),
            );
        }

        final userIds = reviews.map((r) => r.userId).toSet().toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: userIds).snapshots(),
          builder: (context, userSnapshot) {
            Widget content;
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              content = Column(
                children: List.generate(reviews.length, (index) => _buildReviewPlaceholder()),
              );
            } else {
              final userMap = userSnapshot.hasData
                  ? {for (var doc in userSnapshot.data!.docs) doc.id: UserModel.fromFirestore(doc)}
                  : <String, UserModel>{};

              content = Column(
                children: reviews.map((review) {
                  final user = userMap[review.userId];
                  return _buildCombinedReviewItem(review, user);
                }).toList(),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đánh giá (${reviews.length})',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _showReviewDialog,
                      child: Text('Viết đánh giá'),
                      style: TextButton.styleFrom(foregroundColor: Colors.pink),
                    )
                  ],
                ),
                SizedBox(height: 16),
                content,
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRelatedNailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mẫu nail khác',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Container(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('nails')
                .where('store_id', isEqualTo: widget.nail.storeId)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();

              final nails = snapshot.data!.docs
                  .map((doc) => Nail.fromFirestore(doc))
                  .where((nail) => nail.id != widget.nail.id)
                  .take(5)
                  .toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relatedNails.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: NailCard(nail: nails[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('nail_id', isEqualTo: widget.nail.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(height: 20);
        }

        final reviews = snapshot.data!.docs;
        double averageRating = 0;
        if (reviews.isNotEmpty) {
          averageRating = reviews
              .map((doc) => (doc.data() as Map)['rating'] as num)
              .reduce((a, b) => a + b) /
              reviews.length;
        }

        return Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            SizedBox(width: 5),
            Text(averageRating.toStringAsFixed(1),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(width: 8),
            Text("(${reviews.length} Đánh giá)",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        );
      },
    );
  }
  Widget _buildTags() {
    if (widget.nail.tags == null || widget.nail.tags!.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: widget.nail.tags!.map((tag) {
          return Chip(
            label: Text(tag, style: TextStyle(color: Colors.pink.shade800, fontWeight: FontWeight.w500)),
            backgroundColor: Colors.pink.shade50,
            side: BorderSide(color: Colors.pink.shade100),
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          );
        }).toList(),
      ),
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildImageHeader(),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.nail.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              currencyFormat.format(widget.nail.price),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.pink,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        _buildRatingSummary(),
                        _buildTags(),
                        Divider(height: 30, thickness: 1, color: Colors.grey[200]),
                        _buildStoreInfo(),
                        SizedBox(height: 20),
                        _buildVoucherSection(),
                        SizedBox(height: 30),
                        Text(
                          'Thông tin chi tiết',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          widget.nail.description,
                          style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.6),
                        ),
                        SizedBox(height: 30),
                        _buildReviewSection(),
                        SizedBox(height: 30),
                        _buildRelatedNailsSection(),
                        SizedBox(height: 100),
                      ],
                    )
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBookingBar(),
      extendBody: true,
    );
  }

  Widget _buildBookingBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nút chat
          IconButton(
            onPressed: _handleChat,
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),

          // Đường phân cách
          const VerticalDivider(
            color: Colors.white24,
            indent: 15,
            endIndent: 15,
            thickness: 1,
          ),

          // Nút đặt lịch
          Expanded(
            child: InkWell(
              onTap: _handleBooking,
              child: const Center(
                child: Text(
                  'ĐẶT LỊCH NGAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Xử lý chat với cửa hàng
  void _handleChat() {
    // Kiểm tra store có null không
    if (widget.store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin cửa hàng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('Chat với cửa hàng: ${widget.store!.name}');

    // Có thể mở màn hình chat hoặc liên kết Zalo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Liên hệ: ${widget.store!.phone}'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Gọi',
          textColor: Colors.white,
          onPressed: () {
            // launch('tel:${widget.store!.phone}');
          },
        ),
      ),
    );
  }

  // Xử lý đặt lịch
  // Xử lý đặt lịch
  void _handleBooking() {
    // Kiểm tra xem BookingScreen có tồn tại không
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(
            selectedNail: widget.nail,
            selectedStore: widget.store,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to BookingScreen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở màn hình đặt lịch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Các widget khác...
  Widget _buildNailImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(widget.nail.imgUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildNailInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.nail.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '4.8',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.favorite_border, color: Colors.grey[600], size: 20),
              const SizedBox(width: 4),
              Text(
                '${widget.nail.likes}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(widget.nail.price)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF25278),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.nail.description,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // TODO: Thêm danh sách đánh giá
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Chưa có đánh giá nào',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
