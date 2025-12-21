import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thêm thư viện này để dùng Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({Key? key}) : super(key: key);

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  // Lưu trữ trạng thái các mã đã được copy (Key: ID của document, Value: bool)
  final Map<String, bool> _copiedStatus = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Ưu đãi Pionails',
            style: TextStyle(color: Color(0xFF313235), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF313235)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Lỗi tải dữ liệu'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF25278)));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Hiện không có mã giảm giá nào.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              final bool isCopied = _copiedStatus[docId] ?? false;

              String displayValue = data['discountType'] == "PERCENTAGE"
                  ? "Giảm ${data['discountValue']}%"
                  : "Giảm ${NumberFormat.compact().format(data['discountValue'])}đ";

              DateTime expiry = (data['expiryDate'] as Timestamp).toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        decoration: BoxDecoration(
                          // Nếu đã copy thì dải màu cũng nhạt đi
                          color: isCopied ? const Color(0xFFFFE4E8) : const Color(0xFFF25278),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayValue,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isCopied ? Colors.grey : const Color(0xFF313235)
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text("Đơn tối thiểu ${data['minimumOrderAmount']} dịch vụ",
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14,
                                      color: isCopied ? Colors.grey : const Color(0xFFF25278)),
                                  const SizedBox(width: 4),
                                  Text("HSD: ${DateFormat('dd/MM/yyyy').format(expiry)}",
                                    style: TextStyle(
                                        color: isCopied ? Colors.grey : const Color(0xFFF25278),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Phần nút Sao chép
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(data['code'] ?? "",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCopied ? Colors.grey : const Color(0xFFF25278)
                              ),
                            ),
                            TextButton(
                              onPressed: isCopied ? null : () {
                                // 1. Sao chép vào bộ nhớ tạm
                                Clipboard.setData(ClipboardData(text: data['code'] ?? ""));

                                // 2. Cập nhật trạng thái UI
                                setState(() {
                                  _copiedStatus[docId] = true;
                                });

                                // 3. Thông báo cho người dùng
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã sao chép mã ${data['code']}'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: const Color(0xFFF25278),
                                  ),
                                );
                              },
                              child: Text(
                                isCopied ? 'Đã chép' : 'Sao chép',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isCopied ? Colors.grey : const Color(0xFFF25278),
                                    fontWeight: isCopied ? FontWeight.normal : FontWeight.bold
                                ),
                              ),
                            ),
                          ],
                        ),
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