import 'package:flutter/material.dart';
import '../../models/store_model.dart'; // Model chứa dữ liệu cửa hàng
import '../../models/service_model.dart'; // Model chứa dữ liệu chi tiết dịch vụ
import '../../theme/app_colors.dart'; // Quản lý bảng màu (Theme) của ứng dụng
import '../../theme/app_typography.dart'; // Quản lý các kiểu chữ (Font, Size, Weight)
import 'service_details.dart'; // Màn hình chi tiết dịch vụ để điều hướng

/// Hàm phụ trợ xử lý hiển thị hình ảnh thông minh
/// Giúp ứng dụng tự động nhận diện ảnh từ bộ nhớ local (assets) hoặc từ internet (network)
Widget _buildSmartImage(String path) {
  // 1. Trường hợp đường dẫn rỗng: Hiển thị một Container xám kèm icon lỗi để tránh app bị trống
  if (path.isEmpty) {
    return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported)
    );
  }

  // 2. Trường hợp ảnh local: Nhận diện qua tiền tố 'assets/'
  if (path.startsWith('assets/')) {
    return Image.asset(path, fit: BoxFit.cover); // fit: BoxFit.cover giúp ảnh lấp đầy khung mà không bị méo
  }

  // 3. Trường hợp ảnh từ URL (Firebase/Cloudinary): Sử dụng Image.network
  return Image.network(
    path,
    fit: BoxFit.cover,
    // errorBuilder: Xử lý khi đường dẫn URL bị hỏng hoặc mất kết nối mạng
    errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image)
    ),
  );
}

/// Class MostServiceTab: Hiển thị danh sách các dịch vụ nổi bật của tiệm
/// Đây là một Stateless Widget vì dữ liệu dịch vụ được cung cấp từ Store và không thay đổi trạng thái tại đây
class MostServiceTab extends StatelessWidget {
  final Store store; // Nhận đối tượng Store để truy xuất danh sách dịch vụ (store.services)
  const MostServiceTab({super.key, required this.store});

  /// Hàm điều hướng sang màn hình chi tiết dịch vụ
  /// [showMessage]: Nếu là true sẽ hiển thị SnackBar nhắc nhở người dùng
  void _navigateToDetail(BuildContext context, Service service, {bool showMessage = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Truyền cả đối tượng service và store để trang chi tiết có đầy đủ ngữ cảnh dữ liệu
        builder: (context) => ServiceDetailsScreen(service: service, store: store),
      ),
    );

    // Logic hiển thị thông báo hướng dẫn (SnackBar) khi người dùng nhấn nút "Book"
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a design to book an appointment"),
          backgroundColor: AppColors.primary, // Sử dụng màu hồng chủ đạo của thương hiệu [cite: 40]
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating, // Hiển thị dạng nổi trên màn hình cho hiện đại
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PHẦN 1: THANH TÌM KIẾM (Search Bar)
        // Được bọc trong Padding để tạo khoảng cách với các cạnh màn hình
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search services...",
                hintStyle: AppTypography.textSM.copyWith(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        // PHẦN 2: DANH SÁCH DỊCH VỤ (ListView)
        // Expanded giúp danh sách chiếm toàn bộ không gian còn lại và có thể cuộn được
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: store.services.length,
            itemBuilder: (context, index) {
              final service = store.services[index];
              return _buildCompactServiceCard(context, service);
            },
          ),
        ),
      ],
    );
  }

  /// Hàm xây dựng giao diện cho từng thẻ dịch vụ (Service Card)
  Widget _buildCompactServiceCard(BuildContext context, Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // VIỀN HỒNG SIÊU MẢNH GIÚP THẺ NỔI BẬT KHÔNG CẦN ĐỔ BÓNG DÀY
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(context, service),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. ẢNH DỊCH VỤ (Kích thước nhỏ gọn 85x85)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 85,
                  height: 85,
                  child: _buildSmartImage(service.imageUrl ?? ''),
                ),
              ),
              const SizedBox(width: 16),

              // 2. THÔNG TIN (Sử dụng Expanded để tự động co giãn)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: AppTypography.textSM.copyWith(fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // GIÁ TIỀN (Nằm cùng dòng với tên giúp gọn hơn)
                        Text(
                          "\$${service.price}",
                          style: AppTypography.textSM.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: AppTypography.textXS.copyWith(color: Colors.grey[500], height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${service.duration} mins",
                          style: AppTypography.textXS.copyWith(color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        // NÚT BOOK (Thiết kế lại tối giản)
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _navigateToDetail(context, service, showMessage: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text(
                              "Book",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}