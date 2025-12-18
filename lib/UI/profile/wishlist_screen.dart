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
      // Handle the case where the user is not logged in
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Wish List',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
        ),
        body: const Center(
          child: Text("Please log in to see your wishlist."),
        ),
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
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20),
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

  Widget _buildWishlistNails(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wishlist_nail')
          .where('user_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You have no favorite nails yet.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 168 / 250, // Calculated aspect ratio for NailCard
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final nailId = doc['nail_id'] as String;

            // Use a FutureBuilder to get the nail data
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('nails')
                  .doc(nailId)
                  .get(),
              builder: (context, nailSnapshot) {
                if (!nailSnapshot.hasData || !nailSnapshot.data!.exists) {
                  // You can return an empty container or a placeholder
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

  Widget _buildWishlistStores(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wishlist_store')
          .where('user_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You have no saved stores yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final storeId = doc['store_id'] as String;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('stores')
                  .doc(storeId)
                  .get(),
              builder: (context, storeSnapshot) {
                if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                final storeData =
                    storeSnapshot.data!.data() as Map<String, dynamic>;
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
