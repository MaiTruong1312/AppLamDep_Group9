// lib/UI/booking/confirm_appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/models/appointment_model.dart';
import 'package:applamdep/UI/booking/payment_screen.dart';
import 'package:applamdep/UI/booking/appointment_detail_screen.dart';

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
  bool _isFetchingData = true;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  late Appointment _appointment;

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    try {
      _appointment = _parseFromLocalMap(widget.appointmentData);
      if (_appointment.userId.isNotEmpty) {
        setState(() => _isFetchingData = false);
        return;
      }
    } catch (e) {
      print('⚠️ Error parsing local data: $e. Trying to load from Firebase...');
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (doc.exists) {
        _appointment = Appointment.fromFirestore(doc);
      } else {
        throw Exception("Appointment not found");
      }
    } catch (e) {
      print('❌ Error loading from Firebase: $e');
      _appointment = _createEmptyAppointment();
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  Appointment _parseFromLocalMap(Map<String, dynamic> data) {
    List<AppointmentService> parseServices(List<dynamic>? list) {
      if (list == null) return [];
      return list.map((item) {
        if (item is Map<String, dynamic>) {
          return AppointmentService.fromMap(item);
        }
        return AppointmentService(serviceId: '', serviceName: 'Unknown', price: 0);
      }).toList();
    }

    return Appointment(
      id: widget.appointmentId,
      userId: data['userId']?.toString() ?? '',
      storeId: data['storeId']?.toString() ?? '',
      technicianId: data['technicianId']?.toString(),
      bookingDate: (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot']?.toString() ?? '',
      duration: (data['duration'] as int?) ?? 60,
      status: data['status']?.toString() ?? 'pending',
      nailDesigns: List<Map<String, dynamic>>.from(data['nailDesigns'] ?? []),
      additionalServices: parseServices(data['additionalServices']),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? 0.0,
      couponCode: data['couponCode']?.toString(),
      customerName: data['customerName']?.toString() ?? '',
      customerPhone: data['customerPhone']?.toString() ?? '',
      customerNotes: data['customerNotes']?.toString(),
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      paymentMethod: data['paymentMethod']?.toString(),
      paymentId: data['paymentId']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Appointment _createEmptyAppointment() {
    return Appointment(
        id: widget.appointmentId,
        userId: '', storeId: '', bookingDate: DateTime.now(),
        timeSlot: '', duration: 0, status: 'error',
        nailDesigns: [], additionalServices: [],
        totalPrice: 0, finalPrice: 0,
        customerName: 'Error loading data', customerPhone: '',
        paymentStatus: 'pending'
    );
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '$hours h $minutes min';
    if (hours > 0) return '$hours h';
    return '$minutes min';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTimeSlot(String timeSlot) {
    if (timeSlot.contains('-')) {
      final times = timeSlot.split('-');
      if (times.length == 2) return '${times[0]} - ${times[1]}';
    }
    return timeSlot;
  }

  Future<void> _confirmBooking() async {
    if (selectedPayment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
        'paymentMethod': selectedPayment,
        'paymentStatus': selectedPayment == 'cash' ? 'pending' : 'paid',
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (selectedPayment == 'cash') {
        _showSuccessDialog();
      } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Booking Successful!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
            const SizedBox(height: 16),
            Text(
              'Code: ${widget.appointmentId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for booking. Please be on time!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Back to Home'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentDetailScreen(
                    appointmentId: widget.appointmentId,
                    fromPayment: true,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25278),
            ),
            child: const Text('View Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          'Confirm Booking',
          style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(Icons.person_outline, 'Customer', '${_appointment.customerName}\\n${_appointment.customerPhone}'),
            const SizedBox(height: 16),
            _buildInfoSection(Icons.store_outlined, 'Store', '${widget.selectedStore.name}\\n${widget.selectedStore.address}'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    icon: Icons.access_time,
                    title: 'Time',
                    value: '${_formatTimeSlot(_appointment.timeSlot)}\\n${_formatDate(_appointment.bookingDate)}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeCard(
                    icon: Icons.timer_outlined,
                    title: 'Duration',
                    value: _formatDuration(_appointment.duration),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildServicesSection(),
            const SizedBox(height: 32),
            _buildPriceSummary(),
            const SizedBox(height: 32),
            _buildPaymentMethods(),
            const SizedBox(height: 32),
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
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : Text(
              selectedPayment == 'cash'
                  ? 'CONFIRM BOOKING'
                  : 'PAY ${_currencyFormat.format(_appointment.finalPrice)}',
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF25278), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
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
      decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF25278)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
        const Text('Selected Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (allServices.isEmpty) const Text("No services selected", style: TextStyle(color: Colors.grey)),
        ...allServices.asMap().entries.map((entry) {
          final service = entry.value;
          final serviceName = service['nailName'] ?? service['serviceName'] ?? 'Service';
          final price = (service['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = (service['quantity'] as int?) ?? 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.spa, color: Color(0xFFF25278), size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(serviceName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      if (quantity > 1) Text('Quantity: $quantity', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(_currencyFormat.format(price * quantity), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
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
      decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 15)),
              Text(_currencyFormat.format(_appointment.totalPrice), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          if (_appointment.discountAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount${_appointment.couponCode != null ? ' (${_appointment.couponCode})' : ''}', style: const TextStyle(fontSize: 15)),
                Text('-\${_currencyFormat.format(_appointment.discountAmount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green)),
              ],
            ),
          ],
          const Divider(height: 32, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text(_currencyFormat.format(_appointment.finalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final paymentMethods = [
      {'id': 'cash', 'title': 'Cash Payment', 'icon': Icons.money, 'color': Colors.green},
      {'id': 'visa', 'title': 'Visa/Mastercard', 'icon': Icons.credit_card, 'color': Colors.blue},
      {'id': 'momo', 'title': 'MoMo Wallet', 'icon': Icons.account_balance_wallet, 'color': Colors.purple},
      {'id': 'zalopay', 'title': 'ZaloPay Wallet', 'icon': Icons.payment, 'color': Colors.blue[800]},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...paymentMethods.map((method) {
          final isSelected = selectedPayment == method['id'];
          return GestureDetector(
            onTap: () => setState(() => selectedPayment = method['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: const Color(0xFFF25278), width: 2) : null,
              ),
              child: Row(
                children: [
                  Icon(method['icon'] as IconData, color: method['color'] as Color?, size: 30),
                  const SizedBox(width: 16),
                  Expanded(child: Text(method['title'] as String, style: const TextStyle(fontSize: 15))),
                  Radio<String>(
                    value: method['id'] as String,
                    groupValue: selectedPayment,
                    onChanged: (value) => setState(() => selectedPayment = value!),
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

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.note_outlined, color: Colors.grey, size: 20), SizedBox(width: 8), Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 8),
          Text(_appointment.customerNotes!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}
