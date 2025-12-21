// lib/UI/booking/confirm_appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/models/appointment_model.dart'; // Ensure this contains AppointmentService
import 'package:applamdep/UI/booking/payment_screen.dart';

class ConfirmAppointmentScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;
  final Store selectedStore;

  const ConfirmAppointmentScreen({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
    required this.selectedStore,
  });

  @override
  State<ConfirmAppointmentScreen> createState() => _ConfirmAppointmentScreenState();
}

class _ConfirmAppointmentScreenState extends State<ConfirmAppointmentScreen> {
  String selectedPayment = 'cash';
  bool _isLoading = false;

  // Format currency
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 0,
  );

  // Parse appointment data
  late Appointment _appointment;

  @override
  void initState() {
    super.initState();
    _appointment = _parseAppointmentData();
  }

  Appointment _parseAppointmentData() {
    try {
      return Appointment(
        id: widget.appointmentId,
        userId: widget.appointmentData['userId']?.toString() ?? '',
        storeId: widget.appointmentData['storeId']?.toString() ?? '',
        technicianId: widget.appointmentData['technicianId']?.toString(),
        bookingDate: (widget.appointmentData['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        timeSlot: widget.appointmentData['timeSlot']?.toString() ?? '',
        duration: (widget.appointmentData['duration'] as int?) ?? 60,
        status: widget.appointmentData['status']?.toString() ?? 'pending',

        // Parse nail designs
        nailDesigns: List<Map<String, dynamic>>.from(widget.appointmentData['nailDesigns'] ?? []),

        // Parse additional services
        // NOTE: Ensure AppointmentService.fromMap is defined in your appointment_model.dart
        additionalServices: List<Map<String, dynamic>>.from(widget.appointmentData['additionalServices'] ?? [])
            .map((service) => AppointmentService.fromMap(service))
            .toList(),

        totalPrice: (widget.appointmentData['totalPrice'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (widget.appointmentData['discountAmount'] as num?)?.toDouble() ?? 0.0,
        finalPrice: (widget.appointmentData['finalPrice'] as num?)?.toDouble() ?? 0.0,
        couponCode: widget.appointmentData['couponCode']?.toString(),

        customerName: widget.appointmentData['customerName']?.toString() ?? '',
        customerPhone: widget.appointmentData['customerPhone']?.toString() ?? '',
        customerNotes: widget.appointmentData['customerNotes']?.toString(),

        paymentStatus: widget.appointmentData['paymentStatus']?.toString() ?? 'pending',
        paymentMethod: widget.appointmentData['paymentMethod']?.toString(),
        paymentId: widget.appointmentData['paymentId']?.toString(),

        createdAt: (widget.appointmentData['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (widget.appointmentData['updatedAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      print('Error parsing appointment data: $e');
      return Appointment(
        id: widget.appointmentId,
        userId: '',
        storeId: '',
        bookingDate: DateTime.now(),
        timeSlot: '',
        duration: 60,
        status: 'pending',
        nailDesigns: [],
        additionalServices: [],
        totalPrice: 0,
        finalPrice: 0,
        customerName: '',
        customerPhone: '',
        paymentStatus: 'pending',
      );
    }
  }

  // Calculate total duration in hours and minutes
  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours giờ $minutes phút';
    } else if (hours > 0) {
      return '$hours giờ';
    } else {
      return '$minutes phút';
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format time slot
  String _formatTimeSlot(String timeSlot) {
    if (timeSlot.contains('-')) {
      final times = timeSlot.split('-');
      if (times.length == 2) {
        return '${times[0]} - ${times[1]}';
      }
    }
    return timeSlot;
  }

  Future<void> _confirmBooking() async {
    if (selectedPayment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phương thức thanh toán'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update appointment with payment method
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'paymentMethod': selectedPayment,
        'paymentStatus': selectedPayment == 'cash' ? 'pending' : 'paid',
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Navigate to payment screen or success screen
      if (selectedPayment == 'cash') {
        // For cash payment, go to success screen
        _showSuccessDialog();
      } else {
        // For other payments, go to payment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              appointmentId: widget.appointmentId,
              amount: _appointment.finalPrice,
              paymentMethod: selectedPayment,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error confirming booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xác nhận thất bại: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Đặt Lịch Thành Công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Mã đặt lịch: ${widget.appointmentId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đến cửa hàng đúng giờ và thanh toán bằng tiền mặt',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst); // Go to home
            },
            child: const Text('Về trang chủ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // You can navigate to appointment details or booking history
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25278),
            ),
            child: const Text('Xem chi tiết', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Xác Nhận Đặt Lịch',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Information
            _buildInfoSection(
              icon: Icons.person_outline,
              title: 'Thông Tin Khách Hàng',
              content: '${_appointment.customerName}\n${_appointment.customerPhone}',
              showArrow: false,
            ),
            const SizedBox(height: 16),

            // Store Information
            _buildInfoSection(
              icon: Icons.store_outlined,
              title: 'Cửa Hàng',
              content: '${widget.selectedStore.name}\n${widget.selectedStore.address}',
              showArrow: false,
            ),
            const SizedBox(height: 24),

            // Appointment Time & Duration
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    icon: Icons.access_time,
                    title: 'Thời Gian',
                    value: '${_formatTimeSlot(_appointment.timeSlot)}\n${_formatDate(_appointment.bookingDate)}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeCard(
                    icon: Icons.timer_outlined,
                    title: 'Thời Lượng',
                    value: _formatDuration(_appointment.duration),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Services Section
            _buildServicesSection(),
            const SizedBox(height: 32),

            // Price Summary
            _buildPriceSummary(),
            const SizedBox(height: 32),

            // Payment Methods
            _buildPaymentMethods(),
            const SizedBox(height: 32),

            // Additional Options
            _buildAdditionalOptions(),
            const SizedBox(height: 32),

            // Notes
            if (_appointment.customerNotes != null && _appointment.customerNotes!.isNotEmpty)
              _buildNotesSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25278),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : Text(
              selectedPayment == 'cash'
                  ? 'XÁC NHẬN ĐẶT LỊCH'
                  : 'THANH TOÁN ${_currencyFormat.format(_appointment.finalPrice)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    bool showArrow = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF25278), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF25278)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final allServices = [
      ..._appointment.nailDesigns.map((nail) => Map<String, dynamic>.from(nail)),
      ..._appointment.additionalServices.map((service) => service.toMap()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dịch Vụ Đã Chọn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...allServices.asMap().entries.map((entry) {
          final index = entry.key;
          final service = entry.value;
          final serviceName = service['nailName'] ?? service['serviceName'] ?? 'Dịch vụ';
          final price = (service['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = (service['quantity'] as int?) ?? 1;

          return Container(
            margin: EdgeInsets.only(bottom: index == allServices.length - 1 ? 0 : 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.spa, color: Color(0xFFF25278), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (quantity > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Số lượng: $quantity',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  _currencyFormat.format(price * quantity),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF25278),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền dịch vụ', style: TextStyle(fontSize: 15)),
              Text(
                _currencyFormat.format(_appointment.totalPrice),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_appointment.discountAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giảm giá${_appointment.couponCode != null ? ' (${_appointment.couponCode})' : ''}',
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  '-${_currencyFormat.format(_appointment.discountAmount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 32, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                _currencyFormat.format(_appointment.finalPrice),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25278),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final paymentMethods = [
      {
        'id': 'cash',
        'title': 'Thanh toán tiền mặt tại cửa hàng',
        'icon': Icons.money,
        'color': Colors.green,
      },
      {
        'id': 'visa',
        'title': 'Thẻ Visa/Mastercard',
        'icon': Icons.credit_card,
        'color': Colors.blue,
      },
      {
        'id': 'momo',
        'title': 'Ví MoMo',
        'icon': Icons.wallet,
        'color': Colors.purple,
      },
      {
        'id': 'zalopay',
        'title': 'Ví ZaloPay',
        'icon': Icons.payment,
        'color': Colors.blue[800],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương Thức Thanh Toán',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...paymentMethods.map((method) {
          final isSelected = selectedPayment == method['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedPayment = method['id'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: const Color(0xFFF25278), width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    method['icon'] as IconData,
                    color: method['color'] as Color?,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      method['title'] as String,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Radio<String>(
                    value: method['id'] as String,
                    groupValue: selectedPayment,
                    onChanged: (value) {
                      setState(() {
                        selectedPayment = value!;
                      });
                    },
                    activeColor: const Color(0xFFF25278),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy Chọn Thêm',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nhận thông báo nhắc lịch trước 1 giờ',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Switch(
                value: true,
                onChanged: (value) {},
                activeColor: const Color(0xFFF25278),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nhận ưu đãi & khuyến mãi',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Switch(
                value: true,
                onChanged: (value) {},
                activeColor: const Color(0xFFF25278),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_outlined, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'Ghi Chú',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _appointment.customerNotes!,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
