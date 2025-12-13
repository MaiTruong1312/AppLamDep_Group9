import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../detail/nail_detail_screen.dart';

// ------------------ HOME SCREEN ------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _userName;
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userName = user.displayName ?? user.email;
    }
    _pageController = PageController(initialPage: 0, viewportFraction: 0.85);

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    );

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimationController.forward();
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            width: double.infinity,
            height: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
            child: Stack(
                children: [
                // ---------------- MAIN SCROLL AREA ----------------
                Positioned.fill(
                top: 52,
                bottom: 0,
                child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            _buildTopSection(),
                      const SizedBox(height: 20),
                              // ---------------- SPECIAL OFFERS ----------------
                              _buildSpecialOffers(),
                              const SizedBox(height: 20),

                              // ---------------- SERVICES GRID ----------------
                              _buildServicesList(),
                              const SizedBox(height: 20),

                              // ---------------- MOST MONTHLY ----------------
                              _buildMostMonthly(),
                              const SizedBox(height: 20),

                              // ---------------- SALONS NEAR YOU ----------------
                              _buildSalonsNearYou(),

                              const SizedBox(height: 40),
                            ],
                        ),
                      ),
                    ),
                ),
                ),

                  // ---------------- FAKE STATUS BAR ----------------
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                      ),
                    ),
                  ),
                ],
            ),
        ),
    );
  }

  // ============================================================
  // ===================== TOP SECTION =========================
  // ============================================================

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting + Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, Welcome 👋',
                    style: TextStyle(
                      color: Color(0xFF7B7D87),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName ?? 'Guest',
                    style: const TextStyle(
                      color: Color(0xFF313235),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              // Notification icon with better shadow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Icon(Icons.notifications_outlined, size: 24),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------- SEARCH BAR ----------------
          Container(
            width: double.infinity,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0F1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Color(0xFFB8BCC1), size: 24),
                SizedBox(width: 12),
                Text(
                  'Search services, salons...',
                  style: TextStyle(
                    color: Color(0xFFB8BCC1),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ===================== SPECIAL OFFERS =======================
  // ============================================================

  Widget _buildSpecialOffers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Or a placeholder
        }

        final offers = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Special Offers',
                    style: TextStyle(
                      color: Color(0xFF313235),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Banner
                SizedBox(
                  height: 166,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: offers.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      final offerData = offers[index].data() as Map<String, dynamic>;
                      final imageUrl = offerData['image_url'] as String? ?? '';
                      final percent = offerData['percent'] as String? ?? '0%';

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = (_pageController.page ?? 0) - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                          }
                          return Center(
                            child: SizedBox(
                              height: Curves.easeOut.transform(value) * 166,
                              width: Curves.easeOut.transform(value) * 284,
                              child: child,
                            ),
                          );
                        },
                        child: _buildOfferBanner(
                          image: imageUrl,
                          percent: percent,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    offers.length,
                        (index) => _indicator(active: _currentPage == index),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- Banner Card -------------------
  Widget _buildOfferBanner({required String image, required String percent}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.pinkAccent.withOpacity(0.90),
              Colors.pinkAccent.withOpacity(0.5),
              Colors.pinkAccent.withOpacity(0.0),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 40),
          child: Text(
            percent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Indicator dot
  Widget _indicator({bool active = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 30 : 10,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF25278) : const Color(0xFFE0E2E5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ============================================================
  // ======================= SERVICES ============================
  // ============================================================

  Widget _buildServicesList() {
    final services = [
      {'label': 'Nails', 'icon': Icons.spa},
      {'label': 'Eye', 'icon': Icons.visibility},
      {'label': 'Facial', 'icon': Icons.face},
      {'label': 'Hair Cut', 'icon': Icons.content_cut},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Services',
                style: TextStyle(
                  color: Color(0xFF313235),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFFDE2057),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(services.length, (index) {
              final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _listAnimationController,
                  curve: Interval(
                    0.1 * index, 0.5 + 0.1 * index,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              );

              return AnimatedBuilder(
                animation: _listAnimationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: Transform.translate(
                      offset: Offset(0.0, 50 * (1.0 - animation.value)),
                      child: child,
                    ),
                  );
                },
                child: _buildServiceItem(
                    services[index]['label'] as String, services[index]['icon'] as IconData),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFFF25278), size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ============================================================
  // ===================== MOST MONTHLY ==========================
  // ============================================================

  Widget _buildMostMonthly() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Most Monthly',
                style: TextStyle(
                  color: Color(0xFF313235),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFFDE2057),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250, // Give a fixed height to the horizontal list
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('nails').orderBy('likes', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No nails found"));
              }

              final products = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(products.length, (index) {
                    final productData = products[index].data() as Map<String, dynamic>;
                    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _listAnimationController,
                        curve: Interval(
                          0.4 + (0.1 * index),
                          0.8 + (0.1 * index),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );

                    return AnimatedBuilder(
                      animation: _listAnimationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: Transform.translate(
                            offset: Offset(50 * (1.0 - animation.value), 0.0),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Pass product data to the detail screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NailDetailScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: _buildProductCard(
                            name: productData['name'] ?? 'No Name',
                            price: (productData['price'] ?? 0).toString(),
                            likes: (productData['likes'] ?? 0).toString(),
                            imgUrl: productData['img_url'] ?? 'assets/images/nail1.png',
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- PRODUCT CARD -------------------
  Widget _buildProductCard(
      {required String name, required String price, required String likes, required String imgUrl}) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imgUrl,
                  width: 152,
                  height: 152,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 152,
                      height: 152,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 14,
                  child: Icon(
                    Icons.favorite_border,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          Text(
            '${(int.tryParse(likes) ?? 0)} likes',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 5),

          Text(
            '\$$price',
            style: const TextStyle(
              color: Color(0xFFF25278),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  // ---------------- SALON CARD -------------------
  Widget _buildSalonCard({required String name, required String address, required String imgUrl}) {
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
              height: 166,
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
                    const Icon(Icons.bookmark_border, size: 22),
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
  // ============================================================
  // ==================== SALONS NEAR YOU ========================
  // ============================================================

  Widget _buildSalonsNearYou() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Salons Near You',
                style: TextStyle(
                  color: Color(0xFF313235),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFFDE2057),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No stores found"));
            }

            final stores = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final storeData = stores[index].data() as Map<String, dynamic>;
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      0.7 + (0.1 * index).clamp(0.0, 0.3), // Stagger the animation
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                );

                return AnimatedBuilder(
                  animation: _listAnimationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: Transform.translate(
                        offset: Offset(0.0, 50 * (1.0 - animation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildSalonCard(
                      name: storeData['name'] ?? 'No Name',
                      address: storeData['address'] ?? 'No Address',
                      imgUrl: storeData['img_url'] ?? 'assets/images/store1.png',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
