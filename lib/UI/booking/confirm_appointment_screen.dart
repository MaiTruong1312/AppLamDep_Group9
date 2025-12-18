// lib/UI/confirm_appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:applamdep/UI/booking/credit_payment_screen.dart';

class ConfirmAppointmentScreen extends StatefulWidget {
  const ConfirmAppointmentScreen({super.key});

  @override
  State<ConfirmAppointmentScreen> createState() => _ConfirmAppointmentScreenState();
}

class _ConfirmAppointmentScreenState extends State<ConfirmAppointmentScreen> {
  String selectedPayment = 'visa';

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
          'Confirm Appointment',
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
            Row(
              children: [
                const Icon(Icons.person_outline, color: Color(0xFFF25278), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tam Nguyen (+123-456-122134)',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFFF25278), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '6101 San Felipe St, Houston, TX,\nUnited States, Texas',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.store_outlined, color: Color(0xFFF25278), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Honey Saloon\n6101 San Felipe St, Houston, TX, United States, Texas',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blue),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Time', style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 4),
                            Text('16:00\n2025 July 26', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_seat_outlined, color: Colors.blue),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Number of seats', style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 4),
                            Text('01 - 1h30mins', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/nail1.png', width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Hot Style A.01 x1', style: TextStyle(fontWeight: FontWeight.w600))),
                  const Text('\$6.4', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/nail2.png', width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Nail Polish x1', style: TextStyle(fontWeight: FontWeight.w600))),
                  const Text('\$6.4', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/nail3.png', width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Nail Daily x1', style: TextStyle(fontWeight: FontWeight.w600))),
                  const Text('\$6.4', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Points Amount', style: TextStyle(fontSize: 16)),
                      Text('\$19.200', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Payment', style: TextStyle(fontSize: 16)),
                      Text('\$19.200', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Consultation', style: TextStyle(fontSize: 16)),
                      Text('Free', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('You will get', style: TextStyle(fontSize: 16)),
                      Text('\$19.200', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF25278))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Add processing time')),
                  Switch(value: false, onChanged: (val) {}, activeColor: const Color(0xFFF25278)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Block extra time')),
                  Switch(value: false, onChanged: (val) {}, activeColor: const Color(0xFFF25278)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cashing to',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text('See all', style: TextStyle(color: Color(0xFFF25278))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaymentMethod(
              title: 'VISA .... .... 5567',
              logoPath: 'assets/images/visa.png',
              value: 'visa',
            ),
            _buildPaymentMethod(
              title: 'Pay with cash at salon',
              logoPath: 'assets/images/cash_logo.png',
              value: 'cash',
            ),
            _buildPaymentMethod(
              title: 'Pay with VNPay',
              logoPath: 'assets/images/vnpay_logo.png',
              value: 'vnpay',
            ),
            _buildPaymentMethod(
              title: 'Pay with ZaloPay',
              logoPath: 'assets/images/zalopay_logo.png',
              value: 'zalopay',
            ),
            _buildPaymentMethod(
              title: 'Pay with MoMo',
              logoPath: 'assets/images/momo_logo.png',
              value: 'momo',
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Contact and invoice information', style: TextStyle(fontSize: 16)),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreditPaymentScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25278),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text(
              'Book Appointment',
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({
    required String title,
    required String logoPath,
    required String value,
  }) {
    bool isSelected = selectedPayment == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFFF25278), width: 2) : null,
        ),
        child: Row(
          children: [
            Image.asset(
              logoPath,
              width: 50,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.payment, size: 40, color: Colors.grey);
              },
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            Radio<String>(
              value: value,
              groupValue: selectedPayment,
              onChanged: (val) {
                setState(() {
                  selectedPayment = val!;
                });
              },
              activeColor: const Color(0xFFF25278),
            ),
          ],
        ),
      ),
    );
  }
}