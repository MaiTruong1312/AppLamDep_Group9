import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../models/store_model.dart';
import '../../UI/store/store_details.dart';
import '../../UI/store/store_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/nail_model.dart';
import '../detail/nail_detail_screen.dart';
import 'search_screen.dart';
import '../../widgets/nail_card.dart';
import '../../widgets/store_card.dart';
import '../../utils/seed_sample_data.dart'; // Import file seed data

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

  // Biến để kiểm soát nút seed (chỉ hiện trong dev mode)
  bool _showSeedButton = false;
  int _secretTapCount = 0;
  DateTime? _lastTapTime;
  final SampleDataSeeder _seeder = SampleDataSeeder();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userName = user.displayName ?? user.email;
    }
    final provider = Provider.of<StoreProvider>(context, listen: false);
    provider.fetchUserLocation().then((_) => provider.fetchAllStores());

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

                        // ---------------- SEED DATA BUTTON (Tạm thời) ----------------
                        if (_showSeedButton) _buildSeedDataButton(),

                        const SizedBox(height: 60), // Thêm padding cuối
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
  // ===================== SEED DATA BUTTON =====================
  // ============================================================

  Widget _buildSeedDataButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_mode, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text( // BỎ const
                'Developer Tools',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text( // BỎ const
            'Seed data for testing purposes only',
            style: TextStyle(
              color: Colors.orange.shade800, // ĐƯỢC vì không còn const
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Button 1: Enhance Stores
              ElevatedButton.icon(
                onPressed: () => _showSeedDialog('stores'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.store, size: 18),
                label: const Text('Enhance Stores'),
              ),

              // Button 2: Enhance Nails
              ElevatedButton.icon(
                onPressed: () => _showSeedDialog('nails'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.brush, size: 18),
                label: const Text('Enhance Nails'),
              ),

              // Button 3: Show Indexes
              ElevatedButton.icon(
                onPressed: () => _showSeedDialog('indexes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.list, size: 18),
                label: const Text('Show Indexes'),
              ),

              // Button 4: Hide Button
              ElevatedButton.icon(
                onPressed: () => setState(() => _showSeedButton = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.visibility_off, size: 18),
                label: const Text('Hide'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ===================== SECRET TAP HANDLER ===================
  // ============================================================

  void _handleSecretTap() {
    final now = DateTime.now();

    // Reset counter nếu quá 3 giây
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 3)) {
      _secretTapCount = 1;
    } else {
      _secretTapCount++;
    }

    _lastTapTime = now;

    // Hiện nút seed nếu tap 5 lần
    if (_secretTapCount >= 5) {
      setState(() {
        _showSeedButton = true;
        _secretTapCount = 0;
      });

      // Hiện snackbar thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Developer tools activated'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ============================================================
  // ===================== SEED DIALOG ==========================
  // ============================================================

  Future<void> _showSeedDialog(String type) async {
    String title = '';
    String message = '';
    Future<void> Function()? onConfirm; // Thay đổi kiểu dữ liệu

    switch (type) {
      case 'stores':
        title = 'Enhance Stores';
        message = 'This will add search-friendly fields to all stores. Continue?';
        onConfirm = _seedStores; // Không cần gọi () ở đây
        break;
      case 'nails':
        title = 'Enhance Nails';
        message = 'This will add search-friendly fields to all nails. Continue?';
        onConfirm = _seedNails; // Không cần gọi () ở đây
        break;
      case 'indexes':
        title = 'Required Indexes';
        message = 'This will show required Firestore indexes.';
        onConfirm = null;
        break;
    }

    if (type == 'indexes') {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Required Firestore indexes:'),
                const SizedBox(height: 16),
                const Text('📌 Stores Collection:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• name_lowercase (Asc), __name__ (Asc)'),
                const Text('• address_lowercase (Asc), __name__ (Asc)'),
                const Text('• tags (Array Contains), __name__ (Asc)'),
                const SizedBox(height: 12),
                const Text('📌 Nails Collection:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• name_lowercase (Asc), __name__ (Asc)'),
                const Text('• tags (Array Contains), __name__ (Asc)'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[50],
                  child: const Text(
                    'Go to: Firebase Console → Firestore → Indexes → Add Index',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true && onConfirm != null) {
        await onConfirm(); // BÂY GIỜ có thể await vì onConfirm trả về Future<void>
      }
    }
  }

  // ============================================================
  // ===================== SEED FUNCTIONS =======================
  // ============================================================

  Future<void> _seedStores() async {
    final scaffoldContext = ScaffoldMessenger.of(context);

    // Show loading
    scaffoldContext.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 16),
            Text('Enhancing stores...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      await _seeder.enhanceExistingStores();

      // Remove loading snackbar
      scaffoldContext.hideCurrentSnackBar();

      // Show success
      scaffoldContext.showSnackBar(
        const SnackBar(
          content: Text('✅ Stores enhanced successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      scaffoldContext.hideCurrentSnackBar();

      scaffoldContext.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _seedNails() async {
    final scaffoldContext = ScaffoldMessenger.of(context);

    // Show loading
    scaffoldContext.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 16),
            Text('Enhancing nails...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      await _seeder.enhanceExistingNails();

      // Remove loading snackbar
      scaffoldContext.hideCurrentSnackBar();

      // Show success
      scaffoldContext.showSnackBar(
        const SnackBar(
          content: Text('✅ Nails enhanced successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      scaffoldContext.hideCurrentSnackBar();

      scaffoldContext.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showIndexes() async {
    // Already handled in _showSeedDialog
  }

  // ============================================================
  // ===================== CÁC PHẦN KHÁC GIỮ NGUYÊN =============
  // ============================================================

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: _accentColor, size: 26),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Search services, salons...',
                      style: TextStyle(
                        color: Color(0xFF9098B1),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Các phương thức cũ giữ nguyên từ đây xuống...
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
              fontWeight: FontWeight.w800,
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
                  height: 170,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF25278).withOpacity(0.25),
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
              Colors.black.withOpacity(0.6),
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
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? _accentColor : Colors.grey.shade300,
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
                    // final store = storesMap[nail.storeId];
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
                          0.5 + (0.1 * index),
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
                          0.6 + (0.1 * index),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<StoreProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (provider.error != null) {
            return Text('Error: ${provider.error}', style: AppTypography.textSM.copyWith(color: AppColors.error500));
          }
          if (provider.stores.isEmpty) {
            return const Text('No stores nearby', style: TextStyle(fontSize: 16));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Salons Near You',
                    style: const TextStyle(
                      color: Color(0xFF313235),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StoreList()),
                      );
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.primary500,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: provider.stores.length,
                  itemBuilder: (context, index) {
                    Store store = provider.stores[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreDetails(storeId: store.id),
                          ),
                        );
                      },
                      child: Container(
                        width: 300,
                        margin: const EdgeInsets.only(right: 12),
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
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Builder(
                                builder: (context) {
                                  // Trường hợp 1: Dữ liệu là đường dẫn Asset (như bạn muốn)
                                  if (store.imgUrl.startsWith('assets/')) {
                                    return Image.asset(
                                      store.imgUrl,
                                      height: 166,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                                    );
                                  }
                                  // Trường hợp 2: Dữ liệu là link mạng (để app không bị văng nếu data thay đổi)
                                  else if (store.imgUrl.startsWith('http')) {
                                    return Image.network(
                                      store.imgUrl,
                                      height: 166,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                                    );
                                  }
                                  // Trường hợp 3: Fallback cuối cùng nếu không thỏa mãn cả 2 (BẮT BUỘC)
                                  else {
                                    return _buildErrorImage();
                                  }
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
                                          store.name, // Rút gọn lại chỉ hiện tên tiệm
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.black),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // THÊM: Khoảng cách hiện đại ở góc phải
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "${store.distance.toStringAsFixed(1)} km",
                                          style: AppTypography.textXS.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${store.rating} (${store.reviewsCount})',
                                        style: const TextStyle(fontSize: 13, color: AppColors.neutral900),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Giữ địa chỉ ở dưới cùng
                                  Text(
                                    store.address,
                                    style: const TextStyle(color: AppColors.neutral800, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildErrorImage() {
    return Container(
      height: 166,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }
}