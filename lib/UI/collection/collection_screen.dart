import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  late Future<Map<String, String>> _storesFuture;

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
    _nailsStream = FirebaseFirestore.instance.collection('nails').snapshots();
    _bannerPageController = PageController(viewportFraction: 0.84);
    _storesFuture = _loadStores();
  }

  Future<Map<String, String>> _loadStores() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('stores').get();
    final storesMap = <String, String>{};
    for (var doc in snapshot.docs) {
      storesMap[doc.id] = (doc.data()['name'] as String? ?? 'Unknown Store');
    }
    return storesMap;
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
      body: FutureBuilder<Map<String, String>>(
          future: _storesFuture,
          builder: (context, storeSnapshot) {
            if (storeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (storeSnapshot.hasError) {
              return const Center(child: Text('Failed to load store data.'));
            }

            if (!storeSnapshot.hasData || storeSnapshot.data!.isEmpty) {
              return const Center(child: Text('No stores found.'));
            }

            final storesMap = storeSnapshot.data!;

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
                        _buildNailGrid(storesMap),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios, size: 22),
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
                  final img = data['image_url']
                      as String? ?? ''; // Assuming image_url in Firestore

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

  Widget _buildSingleBanner({
    required String title,
    required String subtitle,
    required String desc,
    required String img,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Container(
            width: 160,
            decoration: const BoxDecoration(
              color: Color(0xFFF25278),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white,
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: Colors.black),
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
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH BOX
  Widget _buildSearchBox() {
    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F1),
        borderRadius: BorderRadius.circular(10),
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
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.filter_alt_outlined),
    );
  }

  Widget _buildCategoryItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
      ),
    );
  }

  // GRID NAIL ITEMS
  Widget _buildNailGrid(Map<String, String> storesMap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _nailsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No nails found.'));
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['name'] as String? ?? 'No Name';
              final likes = (data['likes'] as num? ?? 0).toString();
              final img = data['img_url'] as String? ?? '';
              final storeId = data['store_id'] as String? ?? '';

              return _buildNailCard(
                title: title,
                storeId: storeId,
                likes: likes,
                img: img,
                storesMap: storesMap,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNailCard({
    required String title,
    required String storeId,
    required String likes,
    required String img,
    required Map<String, String> storesMap,
  }) {
    final storeName = storesMap[storeId] ?? 'Unknown Store';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {}, // For ripple effect
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F7),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img.isNotEmpty
                        ? Image.asset(
                            img,
                            width: double.infinity,
                            height: 135,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: 140,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.favorite_border,
                          size: 16, color: Color(0xFFF25278)),
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF313235),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(), // Use Spacer to push the bottom row down
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF67686B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              size: 14, color: Color(0xFFF25278)),
                          const SizedBox(width: 2),
                          Text(
                            likes,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313235),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
                  const Icon(Icons.add_circle,
                      size: 24, color: Color(0xFFF25278)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
