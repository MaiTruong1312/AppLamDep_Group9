import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/UI/detail/nail_detail_screen.dart';
import 'package:applamdep/widgets/nail_card.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  int currentBanner = 0;
  late Stream<QuerySnapshot> _bannersStream;
  late Stream<QuerySnapshot> _nailsStream;
  late PageController _bannerPageController;
  late Future<Map<String, Store>> _storesFuture;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final List<String> categories = [
    "Basic",
    "Nail Arts",
    "Facial",
    "Makeup",
  ];

  @override
  void initState() {
    super.initState();
    _bannersStream =
        FirebaseFirestore.instance.collection('banners').snapshots();
    _nailsStream = FirebaseFirestore.instance
        .collection('nails')
        .where('is_active', isEqualTo: true)
        .snapshots();
    _bannerPageController = PageController(viewportFraction: 0.84);
    _storesFuture = _loadStores();
  }

  Future<Map<String, Store>> _loadStores() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isEmpty) {
        return {}; // Trả về map rỗng
      }

      final storesMap = <String, Store>{};

      for (var doc in snapshot.docs) {
        try {
          storesMap[doc.id] = Store.fromFirestore(doc);
        } catch (e) {
          // Bỏ qua document lỗi hoặc tạo store mặc định
        }
      }

      return storesMap;

    } catch (e) {
      // Trả về map rỗng để UI không bị crash
      return {};
    }
  }

  // Hàm toggle wishlist
  Future<void> _toggleWishlist(String nailId, String nailName, int price, String imgUrl) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add to favorites.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final nailRef = firestore.collection('nails').doc(nailId);
    final wishlistDocId = '${_currentUser!.uid}_$nailId';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        } else {
          transaction.set(wishlistRef, {
            'user_id': _currentUser!.uid,
            'nail_id': nailId,
            'created_at': FieldValue.serverTimestamp(),
            'name': nailName,
            'price': price,
            'img_url': imgUrl,
          });
          transaction.update(nailRef, {'likes': currentLikes + 1});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred.')),
      );
    }
  }

  // Hàm check wishlist status
  Stream<bool> _isNailInWishlist(String nailId) {
    if (_currentUser == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('wishlist_nail')
        .doc('${_currentUser!.uid}_$nailId')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Hàm xem chi tiết sản phẩm
  void _viewNailDetail(Nail nail, Store? store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NailDetailScreen(
          nail: nail,
          store: store,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<Map<String, Store>>(
        future: _storesFuture,
        builder: (context, storeSnapshot) {
          if (storeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (storeSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${storeSnapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _storesFuture = _loadStores();
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final storesMap = storeSnapshot.data ?? {};

          // Vẫn hiển thị UI ngay cả khi không có stores
          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 10),
                      _buildBannersFromFirestore(),
                      const SizedBox(height: 20),
                      _buildSearchBox(),
                      const SizedBox(height: 16),
                      _buildCategories(),
                      const SizedBox(height: 20),
                      storesMap.isEmpty
                          ? _buildNoStoresUI()
                          : _buildNailGrid(storesMap),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Collection",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF313235),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(width: 24),
        ],
      ),
    );
  }

  // BANNER FROM FIRESTORE
  Widget _buildBannersFromFirestore() {
    return StreamBuilder<QuerySnapshot>(
      stream: _bannersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            height: 190,
            child: Center(child: Text('Something went wrong')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 190,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(
              height: 190, child: Center(child: Text('No banners found.')));
        }

        final bannerDocs = snapshot.data!.docs;

        return Column(
          children: [
            SizedBox(
              height: 170,
              child: PageView.builder(
                itemCount: bannerDocs.length,
                controller: _bannerPageController,
                onPageChanged: (index) {
                  setState(() => currentBanner = index);
                },
                itemBuilder: (context, index) {
                  final data =
                  bannerDocs[index].data() as Map<String, dynamic>;
                  final title = data['title'] as String? ?? 'No Title';
                  final subtitle =
                      data['subtitle'] as String? ?? 'No Subtitle';
                  final desc = data['desc'] as String? ?? 'No Description';
                  final img = data['image_url'] as String? ?? 'assets/images/banner1.png';

                  return _buildSingleBanner(
                    title: title,
                    subtitle: subtitle,
                    desc: desc,
                    img: img,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                bannerDocs.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentBanner == index ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentBanner == index
                        ? const Color(0xFFF25278)
                        : const Color(0xFFE0E2E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
//Không build gì để xem log lỗi
  Widget _buildNoStoresUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Store information not found.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection or try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {
              _storesFuture = _loadStores();
            }),
            child: const Text('Loading  '),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBanner({
    required String title,
    required String subtitle,
    required String desc,
    required String img,
  }) {
    return GestureDetector(
      onTap: () {
        // Có thể thêm navigation khi nhấn banner
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: img.startsWith('http')
                ? NetworkImage(img) as ImageProvider
                : AssetImage(img),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              width: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFF25278),
                    // Color(0xFFF25278).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 28,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 62,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 90,
              right: 20,
              child: Text(
                desc,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SEARCH BOX
  Widget _buildSearchBox() {
    return GestureDetector(
      onTap: () {
        // Navigate to search screen
        // Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
      },
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        height: 58,
        child: Row(
          children: const [
            Icon(Icons.search, size: 22, color: Color(0xFFB8BCC1)),
            SizedBox(width: 12),
            Text(
              "Search a nail design",
              style: TextStyle(
                color: Color(0xFFB8BCC1),
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CATEGORY FILTER
  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterButton();
          }
          return _buildCategoryItem(categories[index - 1]);
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () {
        // Show filter dialog
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.filter_alt_outlined, color: Color(0xFFF25278)),
      ),
    );
  }

  Widget _buildCategoryItem(String text) {
    return GestureDetector(
      onTap: () {
        // Filter by category
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // GRID NAIL ITEMS
  Widget _buildNailGrid(Map<String, Store> storesMap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _nailsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.brush, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No nail designs found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final nails = snapshot.data!.docs
              .map((doc) => Nail.fromFirestore(doc))
              .toList();

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nails.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 280,
            ),
            itemBuilder: (context, index) {
              final nail = nails[index];
              final store = storesMap[nail.storeId];
              return NailCard(
                nail: nail,
                store: store,
                onAddedToBookingCart: () {},
              );
            },
          );
        },
      ),
    );
  }
}
