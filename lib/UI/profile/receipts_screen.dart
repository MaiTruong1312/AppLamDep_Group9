import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:applamdep/UI/profile/receipt_detail_screen.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'My Receipts',
          style: TextStyle(color: Color(0xFF313235), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF313235)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentUserId.isEmpty
          ? const Center(child: Text('Vui lòng đăng nhập để xem biên lai.'))
          : StreamBuilder<QuerySnapshot>(
        // SỬA 1: Đổi collection sang 'appointments' và tên trường là 'userId'
        // SỬA 2: Thêm lọc paymentStatus == 'paid' để chỉ hiện biên lai đã thanh toán
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: currentUserId)
            .where('paymentStatus', isEqualTo: 'paid')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Đã có lỗi xảy ra.'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF25278)));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Bạn chưa có biên lai đã thanh toán nào.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              // SỬA 3: Lấy giá trị thanh toán trực tiếp từ paymentAmount hoặc finalPrice
              final double totalAmount = (data['paymentAmount'] ?? data['finalPrice'] ?? 0).toDouble();

              final Timestamp? timestamp = data['paymentDate'] ?? data['bookingDate'];
              final String dateStr = timestamp != null
                  ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
                  : 'N/A';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptDetailScreen(data: data),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF2196F3)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${docs[index].id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      Text(
                        '${totalAmount.toStringAsFixed(2)} \$',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF25278), fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}