import 'package:flutter/material.dart';
import 'package:applamdep/UI/Login/mainlogin.dart';
import 'package:applamdep/UI/profile/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      // If user is somehow not logged in, handle it gracefully
      if (mounted) {
        setState(() {
          _userName = "Not Logged In";
        });
      }
      return;
    }

    try {
      final DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();

      if (mounted && userData.exists) {
        final data = userData.data() as Map<String, dynamic>?;
        setState(() {
          _userName = data?['name'] ?? 'No Name';
          if (_userName.isNotEmpty) {
            _userAvatarInitial = _userName[0].toUpperCase();
          } else {
            _userAvatarInitial = '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Error';
        });
      }
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
          onPressed: () {},
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
  Widget _buildCompleteProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF25278),
          width: 1.5,
        ), // Viền hồng
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Complete your profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFFF25278),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Providing more information will enable quicker and safer payments.',
            style: TextStyle(color: Color(0xFF54565B), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('20%', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.2,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF247133), // Màu xanh lá
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF25278),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
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
      {'icon': Icons.cached, 'label': 'My Booking', 'color': Colors.green},
      {
        'icon': Icons.bookmark_border,
        'label': 'Saved collection',
        'color': Colors.orange,
      },
      {'icon': Icons.receipt_long, 'label': 'Receipts', 'color': Colors.blue},
      {
        'icon': Icons.local_offer_outlined,
        'label': 'Coupons',
        'color': Colors.redAccent,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5, // Tỷ lệ chiều rộng/cao để khớp thiết kế
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'] as IconData, color: item['color'] as Color),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
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
      {
        'icon': Icons.visibility_outlined,
        'label': 'App Appearance',
      }, // Icon giả định cho App Language/Appearance
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
            onTap: () {},
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
