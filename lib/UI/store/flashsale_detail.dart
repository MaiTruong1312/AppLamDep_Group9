import 'package:flutter/material.dart';
import 'dart:async'; // Thư viện cần thiết để sử dụng Timer (Bộ đếm thời gian)
import '../../models/store_model.dart'; // Model chứa dữ liệu Flashsale (title, discount, description...)
import '../../theme/app_colors.dart'; // Bảng màu chủ đạo của ứng dụng
import '../../theme/app_typography.dart'; // Hệ thống kiểu chữ chuẩn UI/UX

/// ===========================================================================
/// CLASS FLASHSALEDETAILSCREEN: MÀN HÌNH CHI TIẾT CHƯƠNG TRÌNH GIẢM GIÁ GẤP
/// ===========================================================================
/// Vai trò: Hiển thị thông tin chi tiết về một mã giảm giá hoặc chương trình
/// khuyến mãi Flashsale kèm theo bộ đếm ngược thời gian thực.
class FlashSaleDetailScreen extends StatefulWidget {
  final Flashsale flashsale; // Đối tượng chứa thông tin khuyến mãi
  final Duration initialRemainingTime; // Nhận thời gian còn lại từ trang Store để đảm bảo đồng bộ

  const FlashSaleDetailScreen({
    super.key,
    required this.flashsale,
    required this.initialRemainingTime
  });

  @override
  State<FlashSaleDetailScreen> createState() => _FlashSaleDetailScreenState();
}

class _FlashSaleDetailScreenState extends State<FlashSaleDetailScreen> {
  late Duration _remainingTime; // Biến lưu trữ thời gian còn lại cục bộ
  Timer? _timer; // Đối tượng điều khiển vòng lặp đếm ngược

  /// -------------------------------------------------------------------------
  /// HÀM INITSTATE: KHỞI TẠO TRẠNG THÁI BAN ĐẦU
  /// -------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    // Gán giá trị thời gian bắt đầu từ tham số truyền vào của Widget cha
    _remainingTime = widget.initialRemainingTime;
    // Bắt đầu kích hoạt vòng lặp đếm ngược ngay khi màn hình được tạo
    _startCountdown();
  }

  /// -------------------------------------------------------------------------
  /// LOGIC QUAN TRỌNG: BỘ ĐẾM NGƯỢC (COUNTDOWN TIMER)
  /// -------------------------------------------------------------------------
  /// Cứ mỗi 1000ms (1 giây), hàm periodic sẽ thực hiện trừ đi 1 giây trong
  /// biến _remainingTime và gọi setState để cập nhật lại giao diện người dùng.
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        if (mounted) { // Kiểm tra nếu Widget vẫn còn tồn tại trên cây giao diện
          setState(() => _remainingTime -= const Duration(seconds: 1));
        }
      } else {
        // Nếu thời gian về 0, dừng bộ đếm để tiết kiệm tài nguyên
        _timer?.cancel();
      }
    });
  }

  /// -------------------------------------------------------------------------
  /// HÀM DISPOSE: GIẢI PHÓNG BỘ NHỚ
  /// -------------------------------------------------------------------------
  /// Cực kỳ quan trọng để tránh rò rỉ bộ nhớ (memory leak). Timer phải được
  /// hủy khi người dùng thoát khỏi màn hình này.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Hàm hỗ trợ định dạng số thành chuỗi có 2 chữ số (VD: 9 -> "09")
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// -------------------------------------------------------------------------
  /// HÀM BUILD: XÂY DỰNG GIAO DIỆN CHÍNH
  /// -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Tính toán Giờ, Phút, Giây hiện tại từ tổng số giây còn lại
    String hours = _twoDigits(_remainingTime.inHours);
    String minutes = _twoDigits(_remainingTime.inMinutes.remainder(60));
    String seconds = _twoDigits(_remainingTime.inSeconds.remainder(60));

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. THANH APP BAR MỞ RỘNG (HÌNH ẢNH BANNER)
          _buildSliverAppBar(),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. TIÊU ĐỀ VÀ NHÃN GIẢM GIÁ (DISCOUNT BADGE)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.flashsale.title,
                          style: AppTypography.headlineSM.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _buildDiscountBadge(), // Hiển thị nhãn % giảm giá
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. KHỐI ĐỒNG HỒ ĐẾM NGƯỢC (COUNTDOWN SECTION)
                  // Được đặt trong một container riêng biệt để làm nổi bật sự khẩn cấp
                  _buildCountdownSection(hours, minutes, seconds),
                  const SizedBox(height: 32),

                  // 4. MÔ TẢ CHI TIẾT CHƯƠNG TRÌNH
                  _buildSectionTitle("Promotion Detail"),
                  const SizedBox(height: 8),
                  Text(
                    widget.flashsale.description,
                    style: AppTypography.textSM.copyWith(color: Colors.black54, height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  // 5. ĐIỀU KHOẢN VÀ ĐIỀU KIỆN (TERMS & CONDITIONS)
                  _buildSectionTitle("Terms & Conditions"),
                  const SizedBox(height: 8),
                  _buildConditionList(widget.flashsale.conditions),

                  const SizedBox(height: 100), // Khoảng trống cuối trang để không bị che nút
                ],
              ),
            ),
          ),
        ],
      ),
      // 6. NÚT HÀNH ĐỘNG CỐ ĐỊNH Ở DƯỚI CÙNG (BOTTOM ACTION)
      // bottomSheet: _buildBottomAction(),
    );
  }

  /// -------------------------------------------------------------------------
  /// WIDGET: _BUILDSLIVERAPPBAR - ẢNH NỀN KHUYẾN MÃI
  /// -------------------------------------------------------------------------
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true, // Giữ thanh bar luôn hiện khi cuộn
      backgroundColor: Colors.white,
      leading: _buildCircleAction(Icons.arrow_back, () => Navigator.pop(context)),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildSmartImage(widget.flashsale.imageUrl),
      ),
    );
  }

  /// Widget hiển thị nhãn phần trăm giảm giá (VD: -20% OFF)
  Widget _buildDiscountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary, // Màu hồng đặc trưng của thương hiệu
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "-${(widget.flashsale.discount * 100).toInt()}% OFF",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// WIDGET: _BUILDCOUNTDOWNSECTION - KHỐI HIỂN THỊ THỜI GIAN
  /// -------------------------------------------------------------------------
  Widget _buildCountdownSection(String h, String m, String s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Nền xám nhạt trung tính
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text("Offer expires in:", style: AppTypography.textXS.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(h), _buildTimeDivider(),
              _buildTimeBox(m), _buildTimeDivider(),
              _buildTimeBox(s),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget xây dựng từng ô số thời gian (Màu đen bóng bẩy)
  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
      child: Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
      ),
    );
  }

  /// Dấu hai chấm phân cách giữa Giờ : Phút : Giây
  Widget _buildTimeDivider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text(":", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
  );

  /// Widget hiển thị danh sách điều kiện áp dụng
  Widget _buildConditionList(String conditions) {
    return Text(
      conditions,
      style: AppTypography.textSM.copyWith(color: Colors.black54, height: 1.6),
    );
  }

  /// -------------------------------------------------------------------------
  /// WIDGET: _BUILDBOTTOMACTION - NÚT BẤM DÙNG ƯU ĐÃI
  /// -------------------------------------------------------------------------
  // Widget _buildBottomAction() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [
  //         BoxShadow(
  //             color: Colors.black.withOpacity(0.05),
  //             blurRadius: 20,
  //             offset: const Offset(0, -5)
  //         )
  //       ],
  //     ),
  //     child: ElevatedButton(
  //       onPressed: () => Navigator.pop(context),
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: AppColors.primary,
  //         minimumSize: const Size(double.infinity, 56), // Nút lớn, dễ bấm trên mobile
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       ),
  //       child: const Text(
  //           "USE THIS OFFER NOW",
  //           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
  //       ),
  //     ),
  //   );
  // }

  /// -------------------------------------------------------------------------
  /// HÀM XỬ LÝ ẢNH THÔNG MINH (SMART IMAGE)
  /// -------------------------------------------------------------------------
  Widget _buildSmartImage(String path) {
    // Tự động phân biệt ảnh assets local hoặc ảnh từ internet (URL)
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image)
    );
  }

  /// Widget tiêu đề cho từng mục (VD: "Terms & Conditions")
  Widget _buildSectionTitle(String title) => Text(
      title,
      style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w900)
  );

  /// Nút tròn (Back button) trên hình ảnh header
  Widget _buildCircleAction(IconData icon, VoidCallback onTap) => Center(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    ),
  );
}