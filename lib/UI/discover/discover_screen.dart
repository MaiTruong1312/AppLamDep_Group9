// lib/UI/discover_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/UI/Main/home.dart';
import 'package:applamdep/UI/detail/nail_detail_screen.dart';
import 'package:applamdep/UI/profile/Notification_screen.dart';
import 'package:applamdep/UI/ar/home.dart'; // AR Nail Try-on
import 'package:applamdep/UI/chatbot/home.dart'; // AI Nail Assistant
import 'package:applamdep/widgets/nail_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int currentBanner = 0;
  late Stream<QuerySnapshot> _bannersStream;
  late Stream<QuerySnapshot> _nailsStream;
  late PageController _bannerPageController;
  late Future<Map<String, Store>> _storesFuture;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _bannersStream = FirebaseFirestore.instance.collection('banners').snapshots();
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

      if (snapshot.docs.isEmpty) return {};

      final storesMap = <String, Store>{};
      for (var doc in snapshot.docs) {
        try {
          storesMap[doc.id] = Store.fromFirestore(doc);
        } catch (e) {
          // Bỏ qua document lỗi
        }
      }
      return storesMap;
    } catch (e) {
      return {};
    }
  }

  // Toggle wishlist (copy từ CollectionScreen)
  Future<void> _toggleWishlist(String nailId, String nailName, int price, String imgUrl) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to favorites.'), backgroundColor: Colors.orange),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to favorites')));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred.')));
    }
  }

  // Check wishlist status (copy từ CollectionScreen)
  Stream<bool> _isNailInWishlist(String nailId) {
    if (_currentUser == null) return Stream.value(false);
    return FirebaseFirestore.instance
        .collection('wishlist_nail')
        .doc('${_currentUser!.uid}_$nailId')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Xem chi tiết nail
  void _viewNailDetail(Nail nail, Store? store) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => NailDetailScreen(nail: nail, store: store)));
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Lỗi: ${storeSnapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _storesFuture = _loadStores()),
                  child: const Text('Thử lại'),
                ),
              ]),
            );
          }

          final storesMap = storeSnapshot.data ?? {};
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildBannersFromFirestore(),
                  const SizedBox(height: 20),
                  _buildSearchBox(),
                  const SizedBox(height: 16),
                  _buildToolsSection(),
                  const SizedBox(height: 20),
                  storesMap.isEmpty ? _buildNoStoresUI() : _buildNailGrid(storesMap),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // HEADER: Back -> Home, Title "Collection", Notification
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios, size: 22), onPressed: () => const HomeScreen()),
        const Expanded(
          child: Text("Discover", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF313235), fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
        ),
      ]),
    );
  }

  // BANNER CAROUSEL từ Firestore
  Widget _buildBannersFromFirestore() {
    return StreamBuilder<QuerySnapshot>(
      stream: _bannersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox(height: 190, child: Center(child: Text('Something went wrong')));
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 190, child: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox(height: 190, child: Center(child: Text('No banners found.')));

        final bannerDocs = snapshot.data!.docs;
        return Column(children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              itemCount: bannerDocs.length,
              controller: _bannerPageController,
              onPageChanged: (index) => setState(() => currentBanner = index),
              itemBuilder: (context, index) {
                final data = bannerDocs[index].data() as Map<String, dynamic>;
                return _buildSingleBanner(
                  title: data['title'] as String? ?? 'No Title',
                  subtitle: data['subtitle'] as String? ?? 'No Subtitle',
                  desc: data['desc'] as String? ?? 'No Description',
                  img: data['image_url'] as String? ?? 'assets/images/banner1.png',
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(bannerDocs.length, (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentBanner == index ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentBanner == index ? const Color(0xFFF25278) : const Color(0xFFE0E2E5),
                borderRadius: BorderRadius.circular(20),
              ),
            )),
          ),
        ]);
      },
    );
  }

  Widget _buildSingleBanner({required String title, required String subtitle, required String desc, required String img}) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: img.startsWith('http') ? NetworkImage(img) : AssetImage(img) as ImageProvider,)),
        child: Stack(children: [
          Container(
            width: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFFF25278)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            ),
          ),
          Positioned(left: 24, top: 28, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700))),
          Positioned(
            left: 24,
            top: 62,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ),
          Positioned(left: 24, top: 90, right: 20, child: Text(desc, style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  // SEARCH BOX với real-time filter
  Widget _buildSearchBox() {
    return Center(
      child: SizedBox(
        width: 360,
        height: 58,
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search for nail designs, colors, stores...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFFB8BCC1)),
            suffixIcon: IconButton(icon: const Icon(Icons.filter_list, color: Color(0xFFB8BCC1)), onPressed: () {}), // TODO: Filter
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  // TOOLS SECTION: AR + AI
  Widget _buildToolsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tools', style: TextStyle(color: Color(0xFF313235), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            // AR Tool Card
            _buildToolItem(
              icon: Icons.auto_fix_high,
              iconColor: const Color(0xFFF25278),
              bgIcon: const Color(0xFFFFE4E8),
              title: 'AR Nail Try-on',
              subtitle: 'Try out nail designs right on your hand using the camera.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArNailTryOnPage())),
            ),
            const SizedBox(height: 16),
            // AI Assistant Card
            _buildToolItem(
              icon: Icons.smart_toy_outlined,
              iconColor: Colors.blue,
              bgIcon: const Color(0xFFE3F2FD),
              title: 'AI Nail Assistant',
              subtitle: 'Suggestions for nail designs that suit your style.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatBotPageV2())),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required Color iconColor,
    required Color bgIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgIcon, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14))])),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ]),
      ),
    );
  }

  Widget _buildNoStoresUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Store information not found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        const Text('Please check your connection or try again later.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => setState(() => _storesFuture = _loadStores()), child: const Text('Loading')),
      ]),
    );
  }

  // NAIL GRID với NailCard + Search filter + Wishlist
  Widget _buildNailGrid(Map<String, Store> storesMap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _nailsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.brush, size: 60, color: Colors.grey), SizedBox(height: 16), Text('No nail designs found', style: TextStyle(color: Colors.grey, fontSize: 16))]),
            );
          }

          var nails = snapshot.data!.docs.map((doc) => Nail.fromFirestore(doc)).where((nail) => nail.name.toLowerCase().contains(_searchQuery)).toList();
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nails.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 280),
            itemBuilder: (context, index) {
              final nail = nails[index];
              final store = storesMap[nail.storeId];
              return NailCard(
                key: ValueKey(nail.id),
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