import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/nail_model.dart'; // Model chứa cấu trúc dữ liệu móng
import '../../models/store_model.dart'; // Model chứa thông tin tiệm
import '../../theme/app_colors.dart'; // Bảng màu chủ đạo của ứng dụng
import '../../theme/app_typography.dart'; // Hệ thống font chữ chuẩn
import '../../widgets/nail_card.dart'; // Widget thẻ móng đã xây dựng

/// ===========================================================================
/// CLASS STORENAILCOLLECTIONSCREEN: STORE'S FULL DESIGN GALLERY
/// ===========================================================================
/// Trang hiển thị toàn bộ album ảnh của một tiệm dưới dạng lưới (Grid).
class StoreNailCollectionScreen extends StatefulWidget {
  final Store store;
  const StoreNailCollectionScreen({super.key, required this.store});

  @override
  State<StoreNailCollectionScreen> createState() => _StoreNailCollectionScreenState();
}

class _StoreNailCollectionScreenState extends State<StoreNailCollectionScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        // Sử dụng Title động: Nếu đang tìm kiếm thì hiện TextField, ngược lại hiện tên tiệm
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: AppTypography.textSM,
          decoration: const InputDecoration(hintText: "Search designs...", border: InputBorder.none),
          onChanged: (val) => setState(() => _searchQuery = val),
        )
            : Text("${widget.store.name} Gallery", style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.cancel_rounded : Icons.search_rounded, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = "";
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('nails')
            .where('store_Ids', arrayContains: widget.store.id)  // FIX: arrayContains thay isEqualTo để match array
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {  // Thêm error handling
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Logic lọc dữ liệu client-side để tốc độ phản hồi nhanh
          final nails = snapshot.data!.docs
              .map((doc) => Nail.fromFirestore(doc))
              .where((n) => n.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          if (nails.isEmpty) {  // Thêm empty state
            return const Center(child: Text("No designs found."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: nails.length,
            itemBuilder: (context, index) => NailCard(nail: nails[index]),
          );
        },
      ),
    );
  }
}