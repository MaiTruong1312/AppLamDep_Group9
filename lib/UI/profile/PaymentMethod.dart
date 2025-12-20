import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF313235)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment Methods",
          style: TextStyle(
            color: Color(0xFF313235),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Column(
          children: [
            // Thanh toán tiền mặt sử dụng file ảnh của bạn
            _buildPaymentItem(
              imagePath: 'assets/images/cash_logo.png',
              name: 'Cash',
              isApplied: true, // Thường mặc định là đã sẵn sàng (Màu xám)
            ),
            const SizedBox(height: 16),
            // Ví MoMo
            _buildPaymentItem(
              imagePath: 'assets/images/momo_logo.png',
              name: 'MoMo',
              isApplied: false, // Màu hồng cho chưa liên kết
            ),
            const SizedBox(height: 16),
            // ZaloPay
            _buildPaymentItem(
              imagePath: 'assets/images/zalopay_logo.png',
              name: 'ZaloPay',
              isApplied: false,
            ),
            const SizedBox(height: 16),
            // VNPay
            _buildPaymentItem(
              imagePath: 'assets/images/vnpay_logo.png',
              name: 'VNPay',
              isApplied: false,
            ),
            const Spacer(),
            // Nút Thêm mới phương thức thanh toán
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Logic thêm phương thức mới
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF25278), // Màu hồng chủ đạo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Add New Payment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem({
    required String imagePath,
    required String name,
    required bool isApplied,
  }) {
    return Container(
      // Kích thước ô to và thoáng như yêu cầu
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          // Hiển thị logo từ thư mục assets/images/
          Image.asset(
            imagePath,
            width: 35, // Kích cỡ logo to rõ
            height: 35,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.payments, size: 35, color: Colors.grey),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 18, // Chữ to rõ
                fontWeight: FontWeight.bold,
                color: Color(0xFF313235),
              ),
            ),
          ),
          Text(
            isApplied ? 'Connected' : 'Connect',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              // Logic màu sắc chuẩn: Đã áp dụng = Xám, Chưa áp dụng = Hồng
              color: isApplied ? const Color(0xFFB0B2B5) : const Color(0xFFF25278),
            ),
          ),
        ],
      ),
    );
  }
}