import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/widgets/nail_card.dart';
import 'package:applamdep/widgets/store_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: _buildSimpleAppBar(context),
        body: const Center(child: Text("Vui lòng đăng nhập để xem danh sách yêu thích.")),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Wish List',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFFDE2057),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFDE2057),
            tabs: [
              Tab(text: 'Nails'),
              Tab(text: 'Stores'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildWishlistNails(currentUser.uid),
            _buildWishlistStores(currentUser.uid),
          ],
        ),
      ),
    );
  }

  AppBar _buildSimpleAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Wish List', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  // Lấy danh sách Nails yêu thích
  Widget _buildWishlistNails(String userId) {
    return StreamBuilder<QuerySnapshot>(
      // Khớp chính xác collection name trên hình Firebase của bạn
      stream: FirebaseFirestore.instance
          .collection('wishlist_nail')
          .where('user_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Bạn chưa có mẫu nail yêu thích nào.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.65,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            // Lấy nail_id từ document trong wishlist_nail
            final String nailId = doc['nail_id'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('nails').doc(nailId).get(),
              builder: (context, nailSnapshot) {
                if (!nailSnapshot.hasData || !nailSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                final nail = Nail.fromFirestore(nailSnapshot.data!);
                return NailCard(nail: nail);
              },
            );
          },
        );
      },
    );
  }

  // Lấy danh sách Stores yêu thích
  Widget _buildWishlistStores(String userId) {
    return StreamBuilder<QuerySnapshot>(
      // Khớp chính xác collection name wishlist_store
      stream: FirebaseFirestore.instance
          .collection('wishlist_store')
          .where('user_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Bạn chưa lưu cửa hàng nào.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            // Lấy store_id từ document trong wishlist_store
            final String storeId = doc['store_id'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('stores').doc(storeId).get(),
              builder: (context, storeSnapshot) {
                if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                final storeData = storeSnapshot.data!.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: StoreCard(storeId: storeId, storeData: storeData),
                );
              },
            );
          },
        );
      },
    );
  }
}