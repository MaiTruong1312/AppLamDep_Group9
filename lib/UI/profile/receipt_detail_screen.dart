import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReceiptDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // SỬA 4: Lấy dữ liệu theo cấu trúc Appointment
    final List<dynamic> nailDesigns = data['nailDesigns'] as List<dynamic>? ?? [];
    final List<dynamic> additionalServices = data['additionalServices'] as List<dynamic>? ?? [];
    final date = (data['paymentDate'] as Timestamp?)?.toDate() ?? (data['bookingDate'] as Timestamp?)?.toDate();
    final double totalPaid = (data['paymentAmount'] ?? data['finalPrice'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Receipt Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF247133), size: 64),
            const SizedBox(height: 16),
            const Text('Payment Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : 'N/A'),
            const Divider(height: 48),
            _buildRow('Status:', 'PAID', valueColor: Colors.green),
            _buildRow('Method:', (data['paymentMethod'] ?? 'N/A').toString().toUpperCase()),
            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            // Hiển thị các mẫu nail đã chọn
            ...nailDesigns.map((nail) => _buildItemRow(
                nail['nailName'] ?? 'Nail Design',
                (nail['price'] ?? 0).toDouble()
            )).toList(),
            // Hiển thị các dịch vụ bổ sung
            ...additionalServices.map((service) => _buildItemRow(
                service['serviceName'] ?? 'Service',
                (service['price'] ?? 0).toDouble()
            )).toList(),
            const Divider(height: 32),
            _buildRow('TOTAL:', '${totalPaid.toStringAsFixed(2)} \$', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isTotal ? const Color(0xFFF25278) : (valueColor ?? Colors.black), fontSize: isTotal ? 20 : 14)),
        ],
      ),
    );
  }

  Widget _buildItemRow(String name, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          Text('\$${price.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}