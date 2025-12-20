import 'dart:async';
import 'dart:io';
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


class NailDetailScreen extends StatefulWidget {
  final Nail nail;

  const NailDetailScreen({Key? key, required this.nail}) : super(key: key);

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
        _buildTimeCard(hours, ' giờ'),
        SizedBox(width: 5),
        _buildTimeCard(minutes, ' phút'),
        SizedBox(width: 5),
        _buildTimeCard(seconds, ' giây'),
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

class _NailDetailScreenState extends State<NailDetailScreen> {
  File? _imageFile;
  final picker = ImagePicker();

  void _showReviewDialog() {
    double _rating = 0;
    final _commentController = TextEditingController();
    _imageFile = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              title: Text('Viết đánh giá'),
              content: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đánh giá của bạn:'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setDialogState(() {
                                _rating = index + 1.0;
                              });
                            },
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        }),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận của bạn...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pickedFile =
                              await picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setDialogState(() {
                              _imageFile = File(pickedFile.path);
                            });
                          }
                        },
                        icon: Icon(Icons.add_a_photo),
                        label: Text('Thêm Ảnh/Video'),
                      ),
                      if (_imageFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Image.file(
                            _imageFile!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Vui lòng đăng nhập để đánh giá.')),
                      );
                      return;
                    }

                    if (_rating == 0 || _commentController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Vui lòng chọn sao và viết bình luận.')),
                      );
                      return;
                    }

                    String? mediaUrl;
                    if (_imageFile != null) {
                      final cloudinary = CloudinaryPublic(
                          'dofkwgiv9', 'applamdep',
                          cache: false);
                      try {
                        CloudinaryResponse response =
                            await cloudinary.uploadFile(
                          CloudinaryFile.fromFile(_imageFile!.path,
                              resourceType: CloudinaryResourceType.Image),
                        );
                        mediaUrl = response.secureUrl;
                      } on CloudinaryException catch (e) {
                        print(e.message);
                        print(e.request);
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
                      SnackBar(content: Text('Đánh giá của bạn đã được gửi.')),
                    );
                  },
                  child: Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget nailImage;
    if (widget.nail.imgUrl.startsWith('http')) {
      nailImage = Image.network(
        widget.nail.imgUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      );
    } else {
      nailImage = Image.asset(
        widget.nail.imgUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nail.name),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nailImage,
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nail.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 4),
                      // This will be dynamic later
                      Text('4.8 (320 reviews)', style: TextStyle(fontSize: 16)),
                      Spacer(),
                      Text(
                        '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(widget.nail.price)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildStoreInfo(),
                  SizedBox(height: 16),
                  _buildVoucherSection(),
                  SizedBox(height: 16),
                  Text(
                    'Mô tả',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.nail.description,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 24),
                  _buildReviewSection(),
                  SizedBox(height: 24),
                  _buildRelatedNailsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBookingBar(),
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
        // 346: Chuyển sang dùng Store Model vì đang lấy dữ liệu từ collection 'stores'
        final store = Store.fromFirestore(snapshot.data!);

        ImageProvider imageProvider;
// Kiểm tra nếu imgUrl (đúng tên biến trong model Store) bắt đầu bằng 'http'
        if (store.imgUrl.startsWith('http')) {
          imageProvider = NetworkImage(store.imgUrl);
        } else {
          // Nếu là đường dẫn assets/images/...
          imageProvider = AssetImage(store.imgUrl);
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  // Text(store.address,
                  //     style: TextStyle(color: Colors.grey[600]),
                  //     overflow: TextOverflow.ellipsis),
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

  Widget _buildReviewSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('nail_id', isEqualTo: widget.nail.id)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              children: [
                Text('Chưa có đánh giá nào.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showReviewDialog,
                  icon: Icon(Icons.rate_review),
                  label: Text('Viết đánh giá'),
                )
              ],
            ),
          );
        }

        final reviews = snapshot.data!.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đánh giá (${reviews.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _showReviewDialog,
                  child: Text('Viết đánh giá'),
                )
              ],
            ),
            SizedBox(height: 16),
            ...reviews.map((review) => _buildReviewItem(review)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildReviewItem(Review review) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(review.userId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: Colors.grey[200], radius: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Đang tải...')),
              ],
            ),
          );
        }

        final user = UserModel.fromFirestore(userSnapshot.data!);

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null ? Icon(Icons.person) : null,
                    radius: 20,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name ?? 'Anonymous',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(review.comment),
              if (review.mediaUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(review.mediaUrl!, height: 100),
                ),
              SizedBox(height: 8),
              Text(
                DateFormat('dd/MM/yyyy').format(review.createdAt),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelatedNailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mẫu nail liên quan',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          height: 220, // Adjust height as needed
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('nails')
                .where('store_id', isEqualTo: widget.nail.storeId)
                .where(FieldPath.documentId, isNotEqualTo: widget.nail.id)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('Không có mẫu nail liên quan.'));
              }

              final relatedNails = snapshot.data!.docs
                  .map((doc) => Nail.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relatedNails.length,
                itemBuilder: (context, index) {
                  final relatedNail = relatedNails[index];
                  Widget relatedNailImage;
                  if (relatedNail.imgUrl.startsWith('http')) {
                    relatedNailImage = Image.network(
                      relatedNail.imgUrl,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          width: 150,
                          color: Colors.grey[200],
                          child:
                              Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    );
                  } else {
                    relatedNailImage = Image.asset(
                      relatedNail.imgUrl,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          width: 150,
                          color: Colors.grey[200],
                          child:
                              Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    );
                  }
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NailDetailScreen(nail: relatedNail),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      margin: EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: relatedNailImage,
                          ),
                          SizedBox(height: 8),
                          Text(
                            relatedNail.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(relatedNail.price)}',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement booking logic
              },
              child: Text('Đặt lịch ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 12),
          IconButton(
            onPressed: () {
              // TODO: Implement chat logic
            },
            icon: Icon(Icons.chat_bubble_outline),
            iconSize: 28,
            color: Colors.pink,
          ),
        ],
      ),
    );
  }
}
