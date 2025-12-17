import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

import '../../models/nail_model.dart';
import '../detail/nail_detail_screen.dart';
import '../../widgets/nail_card.dart';
import '../../widgets/store_card.dart';

// ------------------ HOME SCREEN ------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // --- GIỮ NGUYÊN LOGIC & STATE ---
  String? _userName;
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _listAnimationController;
  late ConfettiController _confettiController;

  // Màu chủ đạo (Accent Color) - Dùng đồng bộ
  final Color _accentColor = const Color(0xFFF25278);
  final Color _primaryText = const Color(0xFF313235);
  final Color _bgGrey = const Color(0xFFFAFAFA); // Nền sáng hơn một chút

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
      duration: const Duration(milliseconds: 800), // Tăng thời gian fade nhẹ
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOutQuart, // Curve mượt hơn
    );

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    // Play confetti animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if(mounted) {
        _confettiController.play();
      }
    });

    _fadeAnimationController.forward();
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeAnimationController.dispose();
    _listAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey, // Sử dụng màu nền mới
      body: Container(
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.antiAlias,
        // Thêm gradient nhẹ cho nền để tạo chiều sâu cao cấp
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  _bgGrey,
                  _bgGrey,
                ]
            )
        ),
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
                  padding: const EdgeInsets.symmetric(vertical: 24), // Tăng padding dọc
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopSection(),
                        const SizedBox(height: 24),
                        // ---------------- SPECIAL OFFERS ----------------
                        _buildSpecialOffers(),
                        const SizedBox(height: 24),

                        // ---------------- MOST MONTHLY ----------------
                        _buildMostMonthly(),
                        const SizedBox(height: 24),

                        // ---------------- HOT TREND ----------------
                        _buildHotTrendNails(),
                        const SizedBox(height: 24),

                        // ---------------- BEST CHOICE ----------------
                        _buildBestChoiceNails(),
                        const SizedBox(height: 24),

                        // ---------------- SALONS NEAR YOU ----------------
                        _buildSalonsNearYou(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---------------- FAKE STATUS BAR (Translucent) ----------------
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.0),
                        ]
                    )
                ),
              ),
            ),
            
            // --- CONGRATULATORY CONFETTI ---
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive, // Shoots in all directions
                shouldLoop: false,
                colors: const [
                  Colors.red, Colors.amber, Colors.blue, Colors.pinkAccent, Colors.purpleAccent, Colors.greenAccent
                ], // Brighter, more festive colors
                createParticlePath: (size) { // Custom path for a star shape
                  final path = Path();
                  path.addOval(Rect.fromCircle(center: Offset.zero, radius: 6)); // Bigger particles
                  return path;
                },
                emissionFrequency: 0.02,    // Burst denser
                numberOfParticles: 50,      // More particles for a bigger "wow"
                gravity: 0.3,               // A bit faster
                particleDrag: 0.05,           // Slows down particles over time
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ===================== TOP SECTION (Cải tiến) =================
  // ============================================================

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20), // Tăng padding ngang
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting + Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Welcome 👋',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _userName ?? 'Guest',
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 22, // Font lớn hơn chút
                      fontWeight: FontWeight.w800, // Đậm hơn
                    ),
                  ),
                ],
              ),

              // Notification icon - Soft Shadow
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08), // Shadow nhẹ hơn
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(Icons.notifications_none_rounded, size: 26, color: _primaryText),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ---------------- SEARCH BAR (Cải tiến) ----------------
          Container(
            width: double.infinity,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white, // Nền trắng tinh
              borderRadius: BorderRadius.circular(18), // Bo tròn nhiều hơn
              border: Border.all(color: Colors.grey.shade100), // Viền rất nhẹ
              boxShadow: [
                BoxShadow(
                  // Shadow màu hồng nhẹ tạo cảm giác "glow"
                  color: _accentColor.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: _accentColor, size: 26), // Icon màu accent
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Search services, salons...',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
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
  // ===================== SPECIAL OFFERS (Giữ nguyên logic) =====
  // ============================================================

  // Helper widget cho tiêu đề section
  Widget _buildSectionHeader(String title, VoidCallback onSeeAllTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800, // Đậm hơn
            ),
          ),
          InkWell(
            onTap: onSeeAllTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'See all',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSpecialOffers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Placeholder đẹp hơn khi loading
          return Container(
            height: 166,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20)
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final offers = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Special Offers',
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Horizontal Banner
                SizedBox(
                  height: 170, // Tăng nhẹ chiều cao
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
                          // Thêm opacity effect khi scale
                          final opacity = Curves.easeOut.transform((1 - (value.abs() * 0.5)).clamp(0.0, 1.0));
                          return Center(
                            child: Opacity(
                              opacity: opacity,
                              child: SizedBox(
                                height: Curves.easeOut.transform(value) * 170,
                                width: Curves.easeOut.transform(value) * 300, // Rộng hơn chút
                                child: child,
                              ),
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

  // ---------------- Banner Card (Cải tiến shadow) -------------------
  Widget _buildOfferBanner({required String image, required String percent}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Thêm margin dọc để tránh cắt shadow
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // Bo góc lớn hơn
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF25278).withOpacity(0.25), // Shadow màu hồng
              blurRadius: 14,
              offset: const Offset(0, 6),
              spreadRadius: -2
          )
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.6), // Gradient tối hơn chút để nổi bật chữ
              Colors.transparent,
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: const Text("Limited Time", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),)
              ),
              const SizedBox(height: 4),
              Text(
                '$percent OFF',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5
                ),
              ),
              const Text(
                'On your first booking',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Indicator dot
  Widget _indicator({bool active = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8, // Ngắn hơn chút
      height: 8,
      decoration: BoxDecoration(
        color: active ? _accentColor : Colors.grey.shade300, // Màu inactive nhạt hơn
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ============================================================
  // ===================== MOST MONTHLY =========================
  // ============================================================

  Widget _buildMostMonthly() {
    return Column(
      children: [
        _buildSectionHeader('Most Popular', () {}),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: StreamBuilder<QuerySnapshot>(
            // ... (Giữ nguyên logic StreamBuilder)
            stream: FirebaseFirestore.instance.collection('nails').orderBy('likes', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: _accentColor));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No nails found"));
              }

              final products = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(products.length, (index) {
                    final nail = Nail.fromFirestore(products[index]);
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
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: NailCard(nail: nail),
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

  // ============================================================
  // ===================== HOT TREND NAILS ======================
  // ============================================================

  Widget _buildHotTrendNails() {
    return Column(
      children: [
        _buildSectionHeader('Hot Trend', () {}),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('nails').where('tags', arrayContains: 'Hot Trend').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: _accentColor));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hot trend nails found"));
              }

              final products = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(products.length, (index) {
                    final nail = Nail.fromFirestore(products[index]);
                    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _listAnimationController,
                        curve: Interval(
                          0.5 + (0.1 * index), // Adjust animation timing
                          0.9 + (0.1 * index),
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
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: NailCard(nail: nail),
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

  // ============================================================
  // ===================== BEST CHOICE NAILS ====================
  // ============================================================

  Widget _buildBestChoiceNails() {
    return Column(
      children: [
        _buildSectionHeader('Best Choice', () {}),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('nails').where('tags', arrayContains: 'Best Choice').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: _accentColor));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No best choice nails found"));
              }

              final products = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(products.length, (index) {
                    final nail = Nail.fromFirestore(products[index]);
                    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _listAnimationController,
                        curve: Interval(
                          0.6 + (0.1 * index), // Adjust animation timing
                          1.0 + (0.1 * index),
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
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: NailCard(nail: nail),
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


  // ============================================================
  // ==================== SALONS NEAR YOU =======================
  // ============================================================

  Widget _buildSalonsNearYou() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Salons Near You', () {}),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _accentColor));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No stores found"));
            }

            final stores = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final storeId = stores[index].id;
                final storeData = stores[index].data() as Map<String, dynamic>;
                // ... (Animation giữ nguyên)
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      0.7 + (0.1 * index).clamp(0.0, 0.3),
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: StoreCard(
                      storeId: storeId,
                      storeData: storeData,
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