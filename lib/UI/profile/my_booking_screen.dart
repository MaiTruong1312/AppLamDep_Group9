import 'package:flutter/material.dart';
import 'package:applamdep/UI/booking/booking_screen.dart';
import 'package:applamdep/UI/booking/main_booking_screen.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  bool hasData = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám nhạt
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
              color: Color(0xFF313235), // Màu đen đậm giống ảnh mẫu
              fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      // Truyền context vào hàm _buildEmptyState để xử lý Navigator
      body: hasData ? _buildBookingList() : _buildEmptyState(context),
    );
  }

  // 1. Giao diện khi chưa có lịch hẹn (Đã đẩy khung lên trên cùng)
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Đẩy nội dung lên trên cùng
        children: [
          const SizedBox(height: 24), // Khoảng cách từ AppBar xuống khung trắng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No Appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E9094), // Màu xám tiêu đề
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Book your appointment now and let us create the perfect look for you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF54565B), // Màu chữ nội dung
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Chuyển hướng sang màn hình đặt lịch
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainBookingScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF25278), // Màu hồng chủ đạo
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Book now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Giao diện danh sách lịch hẹn (Ảnh mẫu 2)
  Widget _buildBookingList() {
    return const Center(
      child: Text("Danh sách lịch hẹn sẽ hiển thị ở đây"),
    );
  }
}