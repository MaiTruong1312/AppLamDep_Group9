import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReceiptDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = data['services'] as List<dynamic>? ?? [];
    final date = (data['bookingDate'] as Timestamp?)?.toDate();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chi tiết biên lai', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF247133), size: 64),
            const SizedBox(height: 16),
            const Text('Thanh toán thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : 'N/A'),
            const Divider(height: 48),
            _buildRow('Mẫu thiết kế:', data['nailDesignName'] ?? 'N/A'),
            _buildRow('Thời lượng:', '${data['duration']} phút'),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Chi tiết dịch vụ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            ...services.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s['name'] ?? 'Dịch vụ'),
                  Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(s['price'] ?? 0)),
                ],
              ),
            )).toList(),
            const Divider(height: 48),
            if (data['notes'] != null && data['notes'].toString().isNotEmpty)
              _buildRow('Ghi chú:', data['notes']),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}