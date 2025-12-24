import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/models/appointment_model.dart';
import 'package:applamdep/UI/booking/main_booking_screen.dart';
import 'package:applamdep/UI/booking/appointment_detail_screen.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Appointment> _appointments = [];
  bool _isLoading = true;

  // Định nghĩa bảng màu chủ đạo theo thiết kế của bạn
  static const Color primaryPink = Color(0xFFF25278);
  static const Color textPrimary = Color(0xFF313235);
  static const Color textSecondary = Color(0xFF8E9094);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _fetchBookings(); // Tải dữ liệu ngay khi vào màn hình
  }

  // Hàm tải dữ liệu lịch hẹn từ Firestore
  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Lấy các appointment của User hiện tại và sắp xếp theo ngày mới nhất
      final snapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: user.uid)
          .get();

      final appointments = snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
      setState(() => _isLoading = false);
    }
  }

  // 1. Giao diện Loading
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: primaryPink),
    );
  }

  // 2. Giao diện khi chưa có lịch hẹn
  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
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
                children: [
                  const Text(
                    'No Appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Book your appointment now and let us create the perfect look for you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF54565B), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MainBookingScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Book now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Giao diện Danh sách khi có lịch hẹn
  Widget _buildBookingList() {
    return RefreshIndicator(
      onRefresh: _fetchBookings,
      color: primaryPink,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return _buildBookingCard(appointment);
        },
      ),
    );
  }

  // Widget từng thẻ lịch hẹn
  Widget _buildBookingCard(Appointment appointment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AppointmentDetailScreen(appointmentId: appointment.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(appointment.status),
                Text(
                  appointment.formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: primaryPink, size: 18),
                const SizedBox(width: 8),
                Text(
                  appointment.timeSlot,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF54565B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${appointment.finalPrice.toStringAsFixed(0)} DOLLAR',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryPink),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget huy hiệu trạng thái
  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String text = "Pending";

    if (status == 'confirmed') { color = Colors.green; text = "Confirmed"; }
    else if (status == 'completed') { color = Colors.blue; text = "Completed"; }
    else if (status == 'cancelled') { color = Colors.red; text = "Cancelled"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _appointments.isEmpty
          ? _buildEmptyState(context)
          : _buildBookingList(),
    );
  }
}