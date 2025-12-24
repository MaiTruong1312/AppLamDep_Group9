import 'package:applamdep/UI/profile/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:applamdep/UI/Login/mainlogin.dart';
import 'package:applamdep/UI/profile/edit_profile_screen.dart';
import 'package:applamdep/UI/profile/Notification_screen.dart';
import 'package:applamdep/UI/profile/AcountScurity.dart';
import 'package:applamdep/UI/profile/Linked_appearance.dart';
import 'package:applamdep/UI/profile/help_support_screen.dart';
import 'package:applamdep/UI/profile/PaymentMethod.dart';
import 'package:applamdep/UI/profile/my_booking_screen.dart';
import 'package:applamdep/UI/profile/receipts_screen.dart';
import 'package:applamdep/UI/profile/coupons_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = 'Loading...';
  String _userAvatarInitial = '';
  double _completionPercentage = 0.0;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();

      if (mounted && userData.exists) {
        final data = userData.data() as Map<String, dynamic>?;

        // LOGIC TÍNH % HOÀN THÀNH
        int completedFields = 0;
        // 1. Kiểm tra tên
        if (data?['name'] != null && data!['name'].toString().trim().isNotEmpty) completedFields++;
        // 2. Kiểm tra số điện thoại
        if (data?['phone'] != null && data!['phone'].toString().trim().isNotEmpty) completedFields++;
        // 3. Kiểm tra giới tính
        if (data?['gender'] != null && data!['gender'].toString().trim().isNotEmpty) completedFields++;
        // 4. Kiểm tra ngày sinh
        if (data?['dob'] != null && data!['dob'].toString().trim().isNotEmpty) completedFields++;
        // 5. Kiểm tra ảnh đại diện
        if (data?['photoUrl'] != null && data!['photoUrl'].toString().trim().isNotEmpty) completedFields++;

        setState(() {
          _userName = data?['name'] ?? 'No Name';
          _userAvatarInitial = _userName.isNotEmpty ? _userName[0].toUpperCase() : '';

          // Cập nhật % (mỗi trường chiếm 20%)
          _completionPercentage = completedFields / 5;
          _isProfileComplete = completedFields == 5;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám nhạt
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                // Navigate and then refresh data upon returning
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                ).then((_) => _loadUserData());
              },
              child: _buildHeader(),
            ),
            const SizedBox(height: 24),
            _buildCompleteProfileCard(),
            const SizedBox(height: 16),
            _buildMemberCard(),
            const SizedBox(height: 16),
            _buildGridMenu(),
            const SizedBox(height: 16),
            _buildSettingsList(),
            const SizedBox(height: 24),
            _buildLogoutButton(context),
            const SizedBox(height: 40), // Khoảng trống dưới cùng
          ],
        ),
      ),
    );
  }

  // 1. AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F5F5),
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Color(0xFF313235),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFF25278)),
          onPressed: () {
            final user = _auth.currentUser;
            if (user != null) {
              _showMyQRCodeDialog(context, user.uid); // Đổi sang hàm Dialog
            }
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF313235),
          ),
          onPressed: () {},
        ),
      ],
    );
  }
  void _showMyQRCodeDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Giúp khung tự co giãn theo nội dung
            children: [
              const Text(
                'My Member QR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313235),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show this code to the staff at the store',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF7B7D87), fontSize: 14),
              ),
              const SizedBox(height: 32),
              // Mã QR cá nhân trung tâm
              QrImageView(
                data: uid,
                version: QrVersions.auto,
                size: 220.0,
                foregroundColor: const Color(0xFF313235),
              ),
              const SizedBox(height: 24),
              Text(
                _userName, // Hiển thị tên người dùng thực tế từ Firebase
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF313235),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFFF25278), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // 2. Header (Avatar & Name) - Now dynamic
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Color(0xFF2E31A5), // Màu xanh đậm của avatar
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _userAvatarInitial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            _userName,
            style: const TextStyle(
              color: Color(0xFF313235),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(Icons.chevron_right, color: Color(0xFF313235)),
      ],
    );
  }
    // 3. Complete Profile Card
  // 3. Complete Profile Card - Cập nhật giao diện theo thiết kế
  Widget _buildCompleteProfileCard() {
    // Nếu đã xong 100% thì không hiện card này nữa
    if (_isProfileComplete) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF25278), width: 1), // Viền hồng
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete your profile',
                style: TextStyle(
                  color: Color(0xFF313235),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                width: 250, // Giới hạn chiều rộng để không đè vào icon người
                child: Text(
                  'Providing more information will enable quicker and safer payments.',
                  style: TextStyle(
                    color: Color(0xFF7B7D87),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Dòng tiến độ và nút bấm
              Row(
                children: [
                  Text(
                    '${(_completionPercentage * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF313235),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _completionPercentage,
                        backgroundColor: const Color(0xFFEEEEEE),
                        color: const Color(0xFF247133), // Màu xanh lá cây
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      ).then((_) => _loadUserData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF25278),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Biểu tượng người ở góc phải
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E8), // Màu nền hồng nhạt
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFFF25278),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Member Card
  Widget _buildMemberCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF25278), Color(0xFFDE2057)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Member',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Pionails',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '1.722',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Points',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Grid Menu (2x2)
  Widget _buildGridMenu() {
    final items = [
      {'icon': Icons.cached, 'label': 'My Booking', 'color': const Color(0xFF4CAF50)},
      {
        'icon': Icons.bookmark_border,
        'label': 'Saved collection', // Đã đổi tên nhãn
        'color': const Color(0xFFFF9800),
      },
      {'icon': Icons.receipt_long, 'label': 'Receipts', 'color': const Color(0xFF2196F3)},
      {
        'icon': Icons.local_offer_outlined,
        'label': 'Coupons',
        'color': const Color(0xFFFF5722),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4, // GIẢM giá trị này để ô CAO hơn, hết lỗi overflow
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            if (item['label'] == 'My Booking') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyBookingScreen()),
              );
            }
            else if (item['label'] == 'Saved collection' || item['label'] == 'Wish List') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistScreen()),
              );
            }
            else if (item['label'] == 'Coupons') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CouponsScreen()),
              );
            }
            else if (item['label'] == 'Receipts') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReceiptsScreen()),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16), // Padding rộng hơn cho thoáng
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái giống hình
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy Icon lên trên, Text xuống dưới
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 26,
                ),
                Text(
                  item['label'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF313235),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 6. Settings List
  Widget _buildSettingsList() {
    final items = [
      {'icon': Icons.notifications_none, 'label': 'Notifications'},
      {'icon': Icons.shield_outlined, 'label': 'Account & Security'},
      {'icon': Icons.payment, 'label': 'Payment Methods'},
      {'icon': Icons.sync_alt, 'label': 'Linked Appearance'}, // Icon giả định
      {'icon': Icons.help_outline, 'label': 'Help & Support'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 56),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: const Color(0xFF313235),
            ),
            title: Text(
              item['label'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              final label = item['label'] as String;

              if (label == 'Notifications') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              } else if (label == 'Account & Security') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountSecurityScreen()),
                );
              } else if (label == 'Linked Appearance') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LinkedAppearanceScreen()),
                );
              }else if (label == 'Payment Methods') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
                );
              }
              else if (label == 'Help & Support') {
                // Thêm điều hướng cho màn hình hỗ trợ
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                );
              }
            },
          );
        },
      ),
    );
  }

  // 7. Logout Button - Updated Logic
  Widget _buildLogoutButton(BuildContext context) {
    void _showLogoutConfirmationDialog() {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            content: const Text('Are you sure you want to log out?'),
            actions: <Widget>[
              TextButton(
                child: const Text('No', style: TextStyle(color: Color(0xFF313235))),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                child: const Text('Yes', style: TextStyle(color: Color(0xFFF25278), fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  // Sign out from Firebase
                  await _auth.signOut();

                  // Clear SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);

                  if (!mounted) return;

                  // Navigate to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainLoginScreen()),
                    (Route<dynamic> route) => false,
                  );

                  // Show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have been logged out', style: TextStyle(color: Colors.white)),
                      backgroundColor: Color(0xFF247133),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Color(0xFFF25278)),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFF25278),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: _showLogoutConfirmationDialog,
      ),
    );
  }
}
