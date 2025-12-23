// lib/UI/booking/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:applamdep/UI/booking/appointment_detail_screen.dart';
class PaymentScreen extends StatefulWidget {
  final String appointmentId;
  final double amount;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.appointmentId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  String _errorMessage = '';

  // Dữ liệu cho các phương thức thanh toán
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _momoPhoneController = TextEditingController();
  final TextEditingController _zalopayPhoneController = TextEditingController();

  // Focus nodes để quản lý focus
  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _cardHolderFocus = FocusNode();
  final FocusNode _expiryDateFocus = FocusNode();
  final FocusNode _cvvFocus = FocusNode();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_formatCardNumber);
    _expiryDateController.addListener(_formatExpiryDate);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _momoPhoneController.dispose();
    _zalopayPhoneController.dispose();

    _cardNumberFocus.dispose();
    _cardHolderFocus.dispose();
    _expiryDateFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  void _formatCardNumber() {
    final text = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final formatted = <String>[];
    for (int i = 0; i < text.length; i += 4) {
      final end = i + 4;
      if (end <= text.length) {
        formatted.add(text.substring(i, end));
      } else {
        formatted.add(text.substring(i));
      }
    }
    _cardNumberController.value = _cardNumberController.value.copyWith(
      text: formatted.join(' '),
      selection: TextSelection.collapsed(offset: formatted.join(' ').length),
    );
  }

  void _formatExpiryDate() {
    final text = _expiryDateController.text.replaceAll(RegExp(r'\D'), '');
    if (text.length >= 2) {
      final month = text.substring(0, 2);
      final year = text.length > 2 ? text.substring(2, 4) : '';
      _expiryDateController.value = _expiryDateController.value.copyWith(
        text: '$month${year.isNotEmpty ? '/$year' : ''}',
        selection: TextSelection.collapsed(offset: '$month${year.isNotEmpty ? '/$year' : ''}'.length),
      );
    }
  }

  Future<void> _processPayment() async {
    if (!_validatePayment()) {
      // Hiển thị lỗi validation
      setState(() {});
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Update appointment in Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'paymentStatus': 'paid',
        'paymentMethod': widget.paymentMethod,
        'paymentDate': FieldValue.serverTimestamp(),
        'paymentAmount': widget.amount,
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add payment transaction record
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('payment_transactions')
            .add({
          'userId': user.uid,
          'appointmentId': widget.appointmentId,
          'amount': widget.amount,
          'paymentMethod': widget.paymentMethod,
          'status': 'completed',
          'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _paymentSuccess = true;
        _isProcessing = false;
      });

      // Show success message
      _showSuccessDialog();

    } catch (e) {
      setState(() {
        _errorMessage = 'Thanh toán thất bại: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  bool _validatePayment() {
    _errorMessage = ''; // Reset error message

    switch (widget.paymentMethod) {
      case 'visa':
        final cardNumber = _cardNumberController.text.replaceAll(' ', '');
        if (cardNumber.isEmpty || cardNumber.length != 16) {
          _errorMessage = 'Số thẻ phải có 16 chữ số';
          return false;
        }
        if (_cardHolderController.text.trim().isEmpty) {
          _errorMessage = 'Vui lòng nhập tên chủ thẻ';
          return false;
        }
        if (_expiryDateController.text.length != 5) {
          _errorMessage = 'Vui lòng nhập ngày hết hạn (MM/YY)';
          return false;
        }

        // Validate expiry date format and validity
        final expiryParts = _expiryDateController.text.split('/');
        if (expiryParts.length != 2) {
          _errorMessage = 'Định dạng ngày hết hạn không hợp lệ';
          return false;
        }

        final month = int.tryParse(expiryParts[0]);
        final year = int.tryParse('20${expiryParts[1]}'); // Assuming 20YY format

        if (month == null || year == null || month < 1 || month > 12) {
          _errorMessage = 'Tháng không hợp lệ (1-12)';
          return false;
        }

        // Check if card is expired
        final now = DateTime.now();
        final expiryDate = DateTime(year, month + 1, 0); // Last day of expiry month

        if (expiryDate.isBefore(now)) {
          _errorMessage = 'Thẻ đã hết hạn';
          return false;
        }

        if (_cvvController.text.length != 3 && _cvvController.text.length != 4) {
          _errorMessage = 'Mã CVV phải có 3-4 chữ số';
          return false;
        }
        break;

      case 'momo':
        final phone = _momoPhoneController.text.trim();
        if (phone.isEmpty || phone.length != 10 || !phone.startsWith('0')) {
          _errorMessage = 'Vui lòng nhập số điện thoại MoMo hợp lệ (10 số, bắt đầu bằng 0)';
          return false;
        }
        break;

      case 'zalopay':
        final phone = _zalopayPhoneController.text.trim();
        if (phone.isEmpty || phone.length != 10 || !phone.startsWith('0')) {
          _errorMessage = 'Vui lòng nhập số điện thoại ZaloPay hợp lệ (10 số, bắt đầu bằng 0)';
          return false;
        }
        break;
    }
    return true;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thanh Toán Thành Công!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
            const SizedBox(height: 16),
            Text(
              'Mã đơn: ${widget.appointmentId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Số tiền: ${_currencyFormat.format(widget.amount)}',
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'Phương thức: ${_getPaymentMethodName(widget.paymentMethod)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cảm ơn bạn đã thanh toán! Đơn hàng của bạn đã được xác nhận.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Về trang chủ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
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
            child: const Text('Xem lịch hẹn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'visa': return 'Thẻ Visa/Mastercard';
      case 'momo': return 'Ví MoMo';
      case 'zalopay': return 'Ví ZaloPay';
      case 'cash': return 'Tiền mặt';
      default: return method;
    }
  }

  Widget _buildCreditCardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          focusNode: _cardNumberFocus,
          decoration: InputDecoration(
            labelText: 'Số thẻ',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: _errorMessage.contains('Số thẻ') ? _errorMessage : null,
          ),
          keyboardType: TextInputType.number,
          maxLength: 19,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            _cardNumberFocus.unfocus();
            FocusScope.of(context).requestFocus(_cardHolderFocus);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardHolderController,
          focusNode: _cardHolderFocus,
          decoration: InputDecoration(
            labelText: 'Tên chủ thẻ',
            hintText: 'NGUYEN VAN A',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: _errorMessage.contains('tên chủ thẻ') ? _errorMessage : null,
          ),
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            _cardHolderFocus.unfocus();
            FocusScope.of(context).requestFocus(_expiryDateFocus);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                focusNode: _expiryDateFocus,
                decoration: InputDecoration(
                  labelText: 'Ngày hết hạn',
                  hintText: 'MM/YY',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMessage.contains('ngày hết hạn') ||
                      _errorMessage.contains('Tháng') ||
                      _errorMessage.contains('hết hạn')
                      ? _errorMessage : null,
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  _expiryDateFocus.unfocus();
                  FocusScope.of(context).requestFocus(_cvvFocus);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                focusNode: _cvvFocus,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMessage.contains('CVV') ? _errorMessage : null,
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  _cvvFocus.unfocus();
                  _processPayment();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Card preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thẻ của bạn:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Số thẻ: •••• ${_cardNumberController.text.isNotEmpty ? _cardNumberController.text.substring(_cardNumberController.text.length - 4) : ''}'),
              Text('Tên: ${_cardHolderController.text.isNotEmpty ? _cardHolderController.text : '...'}'),
              Text('Hết hạn: ${_expiryDateController.text.isNotEmpty ? _expiryDateController.text : '...'}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMomoForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFA50064),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('MoMo',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quét mã QR MoMo để thanh toán hoặc nhập số điện thoại',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: _momoPhoneController,
          decoration: InputDecoration(
            labelText: 'Số điện thoại MoMo',
            hintText: '0987654321',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: _errorMessage.contains('MoMo') ? _errorMessage : null,
          ),
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('QR Code MoMo', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Placeholder for QR code
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code, size: 60, color: Color(0xFFA50064)),
                      SizedBox(height: 8),
                      Text('Quét để thanh toán', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('${_currencyFormat.format(widget.amount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA50064)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZaloPayForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('ZP',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quét mã QR ZaloPay để thanh toán',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: _zalopayPhoneController,
          decoration: InputDecoration(
            labelText: 'Số điện thoại ZaloPay',
            hintText: '0987654321',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: _errorMessage.contains('ZaloPay') ? _errorMessage : null,
          ),
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('QR Code ZaloPay', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Placeholder for QR code
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code, size: 60, color: Color(0xFF0066FF)),
                      SizedBox(height: 10),
                      Text('Quét để thanh toán', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('${_currencyFormat.format(widget.amount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0066FF)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    switch (widget.paymentMethod) {
      case 'visa':
        return _buildCreditCardForm();
      case 'momo':
        return _buildMomoForm();
      case 'zalopay':
        return _buildZaloPayForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPaymentIcon() {
    switch (widget.paymentMethod) {
      case 'visa':
        return const Icon(Icons.credit_card, size: 40, color: Colors.blue);
      case 'momo':
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFA50064),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('MoMo',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      case 'zalopay':
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0066FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('ZP',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      default:
        return const Icon(Icons.payment, size: 40);
    }
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
        title: Text(
          'Thanh Toán - ${_getPaymentMethodName(widget.paymentMethod)}',
          style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with payment method
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildPaymentIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPaymentMethodName(widget.paymentMethod),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã đơn: ${widget.appointmentId.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(widget.amount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF25278)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Form
            const Text(
              'Thông Tin Thanh Toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            _buildPaymentForm(),

            // Error message
            if (_errorMessage.isNotEmpty && !_errorMessage.contains('Số thẻ') &&
                !_errorMessage.contains('tên chủ thẻ') &&
                !_errorMessage.contains('ngày hết hạn') &&
                !_errorMessage.contains('CVV') &&
                !_errorMessage.contains('MoMo') &&
                !_errorMessage.contains('ZaloPay'))
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Security note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thông tin thanh toán được bảo mật và mã hóa',
                      style: TextStyle(color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: _paymentSuccess
              ? ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'QUAY VỀ TRANG CHỦ',
              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
              : ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25278),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : Text(
              'THANH TOÁN ${_currencyFormat.format(widget.amount)}',
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}