// lib/UI/credit_payment_screen.dart
// Trang Credit Payment để nhập số points muốn đổi ra tiền mặt

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreditPaymentScreen extends StatefulWidget {
  const CreditPaymentScreen({super.key});

  @override
  State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
  String enteredPoints = '100000'; // Giá trị mặc định như hình
  final int availablePoints = 249560;

  // Format số với dấu chấm phân cách hàng nghìn
  String get formattedPoints {
    if (enteredPoints.isEmpty) return '0';
    final number = int.tryParse(enteredPoints.replaceAll('.', '')) ?? 0;
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  double get cashValue {
    final points = int.tryParse(enteredPoints.replaceAll('.', '')) ?? 0;
    return points / 1000; // 1000 points = $1.00 → 100.000 points = $100.00
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'delete') {
        if (enteredPoints.isNotEmpty) {
          enteredPoints = enteredPoints.substring(0, enteredPoints.length - 1);
        }
      } else {
        enteredPoints += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF25278),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF25278),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Credit Payment',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Phần trên - hồng
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Enter amount of points you want to cashing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedPoints,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12, left: 8),
                        child: Text(
                          '|',
                          style: TextStyle(color: Colors.white, fontSize: 48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Available points: ${availablePoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formattedPoints} points equals \$${cashValue.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Nút Continue
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enteredPoints.isEmpty
                    ? null
                    : () {
                  // TODO: Xử lý cashing points
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cashing request sent!')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF25278),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Phần dưới - bàn phím số
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.8,
                children: [
                  _buildKey('1'),
                  _buildKey('2'),
                  _buildKey('3'),
                  _buildKey('4'),
                  _buildKey('5'),
                  _buildKey('6'),
                  _buildKey('7'),
                  _buildKey('8'),
                  _buildKey('9'),
                  _buildKey('*'), // Không dùng
                  _buildKey('0'),
                  _buildKey('delete', isDelete: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label, {bool isDelete = false}) {
    if (isDelete) {
      return GestureDetector(
        onTap: () => _onKeyPressed('delete'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.backspace_outlined, color: Colors.black54, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onKeyPressed(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}