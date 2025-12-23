import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện hỗ trợ định dạng thời gian và tiền tệ
import '../../models/store_model.dart'; // Model chứa dữ liệu của cửa hàng
import '../../theme/app_colors.dart'; // Quản lý bảng màu thống nhất của ứng dụng
import '../../theme/app_typography.dart'; // Quản lý các kiểu chữ (font, size, weight)

/// Class PortfolioTab: Hiển thị thông tin chi tiết về "hồ sơ năng lực" của tiệm
/// Sử dụng StatelessWidget vì dữ liệu được truyền từ ngoài vào và không thay đổi tại trang này
class PortfolioTab extends StatelessWidget {
  final Store store; // Biến chứa toàn bộ thông tin của tiệm lấy từ Firestore
  const PortfolioTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    // Sử dụng ListView để toàn bộ nội dung có thể cuộn được khi vượt quá màn hình
    return ListView(
      padding: const EdgeInsets.all(16), // Tạo khoảng cách đệm đồng đều 16px ở các cạnh
      children: [
        // 1. PHẦN NGÀY THÀNH LẬP: Chỉ hiển thị nếu dữ liệu establishedDate khác null (Null-safety)
        if (store.establishedDate != null) _buildEstablishedDate(store.establishedDate!),
        const SizedBox(height: 24), // Khoảng cách giữa các phần

        // 2. PHẦN GIỚI THIỆU (Studio Story): Hiển thị đoạn văn mô tả tiệm
        _buildAboutSection(),
        const SizedBox(height: 32),

        // 3. THANH THỐNG KÊ (Stats Bar): Hiển thị số lượng tác phẩm, người theo dõi, lượt xem
        _buildStatsBar(),
        const SizedBox(height: 32),

        // 4. GIỜ HOẠT ĐỘNG (Business Hours): Hiển thị lịch mở cửa từ Thứ 2 đến Chủ Nhật
        _buildOpeningHoursSection(),

        const SizedBox(height: 40), // Khoảng trống cuối trang để không bị che bởi các nút khác
      ],
    );
  }

  // --- CÁC HÀM XÂY DỰNG GIAO DIỆN CON (UI COMPONENTS) ---

  /// Hàm xây dựng tiêu đề cho từng mục lớn (Ví dụ: "Studio Story", "Business Hours")
  /// Giúp đồng bộ hóa kiểu chữ và độ đậm cho toàn bộ các tiêu đề trong trang
  Widget _buildSectionTitle(String title) => Text(
      title,
      style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.w800)
  );

  /// Hàm hiển thị ngày thành lập của tiệm
  /// Sử dụng màu Primary nhạt cho nền và biểu tượng "Verified" để tăng độ uy tín
  Widget _buildEstablishedDate(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05), // Nền hồng nhạt (5% độ đậm)
        borderRadius: BorderRadius.circular(12), // Bo góc nhẹ cho container
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            // Hiển thị ngày tháng năm theo định dạng thủ công: Day/Month/Year
            "Established Since ${date.day}/${date.month}/${date.year}",
            style: AppTypography.textSM.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary
            ),
          ),
        ],
      ),
    );
  }

  /// Hàm hiển thị nội dung giới thiệu Studio
  /// Có logic xử lý: Nếu mô tả trên Firebase trống sẽ hiển thị một câu chào mặc định
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái cho nội dung
      children: [
        _buildSectionTitle("Studio Story"), // Gọi hàm tiêu đề dùng chung
        const SizedBox(height: 12),
        Text(
          // Toán tử ba ngôi: Kiểm tra nếu dữ liệu rỗng thì dùng text dự phòng
          store.description.isNotEmpty
              ? store.description
              : "Welcome to our studio, where beauty meets artistry.",
          style: AppTypography.textSM.copyWith(color: Colors.black87, height: 1.6), // line-height 1.6 cho dễ đọc
        ),
      ],
    );
  }

  /// Hàm xây dựng thanh thống kê chỉ số của tiệm
  /// Được bọc trong một Container có đổ bóng (BoxShadow) để tạo chiều sâu (Elevation)
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), // Đổ bóng cực nhẹ để giao diện thanh thoát
              blurRadius: 20,
              offset: const Offset(0, 8) // Đổ bóng hướng xuống dưới
          )
        ],
        border: Border.all(color: Colors.grey.shade100), // Viền siêu mỏng để định hình khối
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Chia đều không gian cho 3 mục thống kê
        children: [
          // Hiển thị số lượng tác phẩm (Artworks)
          _buildStatItem(Icons.brush, "${store.totalNails}", "Artworks"),
          // Hiển thị số lượng người theo dõi (Followers)
          _buildStatItem(Icons.people_outline, "${store.followerCount}", "Followers"),
          // Hiển thị tổng lượt xem tiệm (Total Views)
          _buildStatItem(Icons.visibility_outlined, "${store.viewCount}", "Total Views"),
        ],
      ),
    );
  }

  /// Hàm xây dựng từng mục thống kê nhỏ (bao gồm: Icon, Số lượng, Nhãn chữ)
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 26),
        const SizedBox(height: 10),
        // Hiển thị con số (Ví dụ: 120)
        Text(value, style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.bold)),
        // Hiển thị nhãn (Ví dụ: "Artworks")
        Text(label, style: AppTypography.textXS.copyWith(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ],
    );
  }

  /// Hàm xây dựng bảng danh sách giờ mở cửa từ dữ liệu Map trong Model
  Widget _buildOpeningHoursSection() {
    // Nếu dữ liệu giờ mở cửa trống thì không hiển thị phần này
    if (store.openingHours.isEmpty) return const SizedBox.shrink();

    // Danh sách các khóa (keys) tương ứng với dữ liệu Map trên Firestore
    final days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];

    // Lấy chỉ số ngày hiện tại (Thứ 2 là 1, Chủ Nhật là 7 -> Trừ 1 để khớp với Index của mảng days)
    final int todayIndex = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Business Hours"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), // Màu nền xám nhạt (F9) để phân biệt với nền trắng
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            // Duyệt qua danh sách các ngày để tạo ra từng hàng dữ liệu
            children: days.map((day) {
              final time = store.openingHours[day]; // Lấy giá trị {open: ..., close: ...} cho từng ngày
              final bool isToday = days.indexOf(day) == todayIndex; // Kiểm tra xem hàng này có phải là ngày hôm nay không

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cột 1: Tên ngày (In hoa chữ cái đầu)
                    Text(
                      day[0].toUpperCase() + day.substring(1),
                      style: AppTypography.textSM.copyWith(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? AppColors.primary : AppColors.black,
                      ),
                    ),
                    // Cột 2: Giờ mở - Giờ đóng (Hoặc hiển thị "Closed" nếu dữ liệu null)
                    Text(
                      time != null ? "${time['open']} - ${time['close']}" : "Closed",
                      style: AppTypography.textSM.copyWith(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(), // Chuyển đổi Map thành danh sách Widget
          ),
        ),
      ],
    );
  }
}