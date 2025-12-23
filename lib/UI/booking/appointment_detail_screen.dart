// lib/UI/booking/appointment_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:applamdep/models/appointment_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/UI/booking/your_appointment_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final bool fromPayment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.fromPayment = false,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Appointment _appointment;
  Store? _store;
  bool _isLoading = true;
  bool _isCancelling = false;
  String _errorMessage = '';
  bool _showCancelConfirmation = false;
  String _cancellationReason = '';

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    try {
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      _appointment = Appointment.fromFirestore(appointmentDoc);

      if (_appointment.storeId.isNotEmpty) {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(_appointment.storeId)
            .get();

        if (storeDoc.exists) {
          _store = Store.fromFirestore(storeDoc);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(String timeSlot) {
    if (timeSlot.contains('-')) {
      final parts = timeSlot.split('-');
      if (parts.length == 2) {
        return '${parts[0]} - ${parts[1]}';
      }
    }
    return timeSlot;
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '--:--';
    return DateFormat('HH:mm dd/MM/yyyy').format(date);
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pending payment';
      case 'paid': return 'Paid';
      case 'refunded': return 'Refunded';
      default: return status;
    }
  }

  Future<void> _cancelAppointment() async {
    if (_cancellationReason.isEmpty) {
      setState(() => _errorMessage = 'Please enter a reason for cancellation');
      return;
    }

    setState(() => _isCancelling = true);

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'status': 'cancelled',
        'cancellationReason': _cancellationReason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadAppointmentData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCancelling = false;
        _showCancelConfirmation = false;
        _cancellationReason = '';
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF25278),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Appointment Details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(_appointment.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ID: ${_appointment.id.substring(0, 8).toUpperCase()}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFF25278), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    if (_store == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Color(0xFFF25278), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Store Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _store!.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _store!.address,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            if (_store!.hotline.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _store!.hotline,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    final allServices = [
      ..._appointment.nailDesigns.map((nail) => Map<String, dynamic>.from(nail)),
      ..._appointment.additionalServices.map((service) => service.toMap()),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa, color: Color(0xFFF25278), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Booked Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (allServices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No services',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ...allServices.asMap().entries.map((entry) {
              final service = entry.value;
              final serviceName = service['nailName'] ?? service['serviceName'] ?? 'Service';
              final price = (service['price'] as num?)?.toDouble() ?? 0.0;
              final quantity = (service['quantity'] as int?) ?? 1;

              return Container(
                margin: EdgeInsets.only(bottom: entry.key == allServices.length - 1 ? 0 : 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF25278).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.spa, color: Color(0xFFF25278)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (quantity > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Quantity: $quantity',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currencyFormat.format(price * quantity),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF25278),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Color(0xFFF25278), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total service fee:'),
                Text(
                  _currencyFormat.format(_appointment.totalPrice),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (_appointment.discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount${_appointment.couponCode != null ? ' (${_appointment.couponCode})' : ''}:'),
                  Text(
                    '-${_currencyFormat.format(_appointment.discountAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _currencyFormat.format(_appointment.finalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF25278),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment status:'),
                Chip(
                  backgroundColor: _appointment.paymentStatus == 'paid'
                      ? Colors.green[100]
                      : Colors.orange[100],
                  label: Text(
                    _getPaymentStatusText(_appointment.paymentStatus),
                    style: TextStyle(
                      color: _appointment.paymentStatus == 'paid'
                          ? Colors.green[800]
                          : Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (_appointment.paymentMethod != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Method:'),
                  Text(
                    _appointment.paymentMethod == 'cash' ? 'Cash' :
                    _appointment.paymentMethod == 'visa' ? 'Visa Card' :
                    _appointment.paymentMethod == 'momo' ? 'MoMo' :
                    _appointment.paymentMethod == 'zalopay' ? 'ZaloPay' :
                    _appointment.paymentMethod!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Color(0xFFF25278), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Update History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              'Booked',
              _formatDateTime(_appointment.createdAt),
              true,
            ),
            _buildTimelineItem(
              'Confirmed',
              _formatDateTime(_appointment.confirmedAt),
              _appointment.confirmedAt != null,
            ),
            if (_appointment.paymentStatus == 'paid')
              _buildTimelineItem(
                'Payment',
                _formatDateTime(_appointment.updatedAt),
                true,
              ),
            if (_appointment.cancelledAt != null)
              _buildTimelineItem(
                'Cancelled',
                _formatDateTime(_appointment.cancelledAt),
                true,
                isCancelled: true,
              ),
            _buildTimelineItem(
              'Completed',
              _formatDateTime(_appointment.completedAt),
              _appointment.completedAt != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isCompleted, {bool isCancelled = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? (isCancelled ? Colors.red : const Color(0xFFF25278))
                      : Colors.grey[300],
                ),
                child: isCompleted
                    ? Icon(
                  isCancelled ? Icons.close : Icons.check,
                  size: 12,
                  color: Colors.white,
                )
                    : null,
              ),
              if (title != 'Completed')
                Container(
                  width: 2,
                  height: 16,
                  color: isCompleted ? const Color(0xFFF25278) : Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (isCancelled && _appointment.cancellationReason != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Text(
                      'Reason: ${_appointment.cancellationReason!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[800],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canCancel = _appointment.status != 'cancelled' &&
        _appointment.status != 'completed' &&
        !_appointment.bookingDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canCancel) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _showCancelConfirmation = true);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.red[300]!),
                ),
                child: Text(
                  'CANCEL APPOINTMENT',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const YourAppointmentScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF25278),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'VIEW ALL APPOINTMENTS',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (widget.fromPayment) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'BACK TO HOME',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelConfirmationDialog() {
    return AlertDialog(
      title: const Text('Confirm Cancellation', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this appointment?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => _cancellationReason = value,
              decoration: InputDecoration(
                labelText: 'Reason for cancellation (required)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isCancelling ? null : () {
                  setState(() {
                    _showCancelConfirmation = false;
                    _errorMessage = '';
                  });
                },
                child: const Text('BACK'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isCancelling ? null : _cancelAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: _isCancelling
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('CONFIRM CANCEL'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFF25278)),
              const SizedBox(height: 16),
              Text(
                'Loading appointment details...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Appointment Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF25278),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Appointment Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status and ID
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: _getStatusColor(_appointment.status),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getStatusText(_appointment.status),
                                    style: TextStyle(
                                      color: _getStatusColor(_appointment.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Order ID: ${_appointment.id.substring(0, 8).toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Basic info
                        _buildInfoCard(
                          Icons.person,
                          'Customer',
                          '${_appointment.customerName}\n${_appointment.customerPhone}',
                        ),
                        _buildInfoCard(
                          Icons.access_time,
                          'Time',
                          '${_formatTime(_appointment.timeSlot)}\n${_formatDate(_appointment.bookingDate)}',
                        ),
                        _buildInfoCard(
                          Icons.timer,
                          'Duration',
                          '${_appointment.duration} minutes',
                        ),

                        const SizedBox(height: 16),

                        // Store info
                        _buildStoreInfo(),

                        const SizedBox(height: 16),

                        // Services
                        _buildServicesList(),

                        const SizedBox(height: 16),

                        // Payment info
                        _buildPaymentInfo(),

                        const SizedBox(height: 16),

                        // Timeline
                        _buildTimeline(),

                        if (_appointment.customerNotes != null && _appointment.customerNotes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Card(
                            margin: EdgeInsets.zero,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.note, color: Color(0xFFF25278), size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Notes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(_appointment.customerNotes!),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 80), // Space for action buttons
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons at bottom
          _buildActionButtons(),
        ],
      ),

      // FAB for calling store
      floatingActionButton: _appointment.status != 'cancelled' &&
          _appointment.status != 'completed' &&
          _store != null &&
          _store!.hotline.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling: ${_store!.hotline}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.phone, color: Colors.white),
        label: const Text('Call Store', style: TextStyle(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
