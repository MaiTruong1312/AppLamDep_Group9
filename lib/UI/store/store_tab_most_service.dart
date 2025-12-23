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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), // Màu xám nhạt giúp UI dịu mắt [cite: 40]
              borderRadius: BorderRadius.circular(12), // Bo góc cho thanh tìm kiếm
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search services, salons...",
                hintStyle: AppTypography.textSM.copyWith(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary), // Icon kính lúp màu hồng
                border: InputBorder.none, // Loại bỏ viền mặc định của TextField
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // PHẦN 2: DANH SÁCH DỊCH VỤ (ListView)
        // Expanded giúp danh sách chiếm toàn bộ không gian còn lại và có thể cuộn được
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: store.services.length, // Số lượng phần tử dựa trên dữ liệu từ Firestore [cite: 74]
            itemBuilder: (context, index) {
              final service = store.services[index];
              // Gọi hàm xây dựng từng thẻ dịch vụ riêng biệt để code sạch sẽ hơn
              return _buildServiceCard(context, service);
            },
          ),
        ),
      ],
    );
  }

  /// Hàm xây dựng giao diện cho từng thẻ dịch vụ (Service Card)
  Widget _buildServiceCard(BuildContext context, Service service) {
    return InkWell(
      // InkWell tạo hiệu ứng phản hồi khi chạm (Ripple effect)
      onTap: () => _navigateToDetail(context, service),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20), // Khoảng cách giữa các thẻ
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              // Đổ bóng nhẹ (Elevation) giúp thẻ nổi bật trên nền ứng dụng
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8) // Bóng đổ xuống dưới
              )
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. HÌNH ẢNH DỊCH VỤ
            // ClipRRect giúp bo góc ảnh chỉ ở phía trên để khớp với Container cha
            ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _buildSmartImage(service.imageUrl ?? ''),
                )
            ),

            // B. NỘI DUNG VĂN BẢN (Tên, Mô tả, Thời gian)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên dịch vụ (In đậm)
                  Text(
                      service.name,
                      style: AppTypography.textMD.copyWith(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  // Mô tả dịch vụ: Xử lý logic nếu Firebase trống thì hiện text mặc định
                  Text(
                    service.description.isNotEmpty ? service.description : "Premium beauty service with quality care.",
                    style: AppTypography.textSM.copyWith(color: Colors.grey),
                    maxLines: 2, // Giới hạn tối đa 2 dòng để đảm bảo bố cục không bị lệch
                    overflow: TextOverflow.ellipsis, // Hiện dấu "..." nếu text quá dài
                  ),
                  const SizedBox(height: 16),

                  // C. DÒNG THÔNG TIN PHỤ VÀ NÚT BẤM
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hiển thị thời gian thực hiện (Duration) [cite: 75]
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                              "Time: ${service.duration} mins",
                              style: AppTypography.textSM.copyWith(color: Colors.grey, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),

                      // NÚT BOOK (Xác nhận đặt lịch)
                      ElevatedButton(
                        // Khi nhấn nút Book, ngoài việc chuyển trang còn hiện SnackBar nhắc nhở
                        onPressed: () => _navigateToDetail(context, service, showMessage: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // Màu hồng đặc trưng của Pionails [cite: 40]
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                            "Book",
                            style: AppTypography.textSM.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            )
                        ),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}