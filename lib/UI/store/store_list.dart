import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:applamdep/providers/store_provider.dart'; // Quản lý trạng thái toàn cục cho Store
import 'package:applamdep/theme/app_colors.dart'; // Bảng màu tông hồng chủ đạo
import 'package:applamdep/theme/app_typography.dart'; // Hệ thống kiểu chữ chuẩn
import 'store_details.dart'; // Màn hình chi tiết cửa hàng
import '../../models/store_model.dart'; // Model dữ liệu Store

/// ===========================================================================
/// CLASS STORELIST: MÀN HÌNH HIỂN THỊ DANH SÁCH TẤT CẢ CÁC TIỆM NAIL
/// ===========================================================================
/// Vai trò: Hiển thị toàn bộ danh sách tiệm nail hiện có trong hệ thống,
/// được sắp xếp dựa trên vị trí địa lý của người dùng.
class StoreList extends StatefulWidget {
  const StoreList({super.key});

  @override
  _StoreListState createState() => _StoreListState();
}

class _StoreListState extends State<StoreList> {

  /// -------------------------------------------------------------------------
  /// HÀM INITSTATE: KHỞI TẠO DỮ LIỆU BAN ĐẦU
  /// -------------------------------------------------------------------------
  /// Sử dụng Future.microtask để lấy dữ liệu ngay khi màn hình khởi tạo mà
  /// không gây gián đoạn luồng dựng giao diện (UI Rendering).
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<StoreProvider>(context, listen: false);
      // 1. Xác định tọa độ người dùng (Giả lập tại Học viện Ngân hàng)
      // 2. Fetch toàn bộ dữ liệu từ Firestore và tính toán khoảng cách
      provider.fetchUserLocation().then((_) => provider.fetchAllStores());
    });
  }

  /// -------------------------------------------------------------------------
  /// HÀM BUILD: XÂY DỰNG GIAO DIỆN CHÍNH
  /// -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền xám nhạt trung tính
      appBar: AppBar(
        title: Text('All Salons', style: AppTypography.labelLG.copyWith(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // LẮNG NGHE SỰ THAY ĐỔI DỮ LIỆU TỪ TẦNG PROVIDER
      body: Consumer<StoreProvider>(
        builder: (context, provider, child) {
          // HIỂN THỊ HIỆU ỨNG CHỜ (LOADING) KHI ĐANG TẢI DỮ LIỆU
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          // HIỂN THỊ THÔNG BÁO LỖI NẾU TRUY VẤN THẤT BẠI
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: AppColors.error500)));
          }

          /// =================================================================
          /// SỬA ĐỔI QUAN TRỌNG: SỬ DỤNG TOÀN BỘ DANH SÁCH CỬA HÀNG
          /// =================================================================
          /// Thay vì lọc .where như trước, chúng ta lấy trực tiếp provider.stores
          /// để hiển thị mọi cửa hàng có trong cơ sở dữ liệu.
          final allStores = provider.stores;

          // XỬ LÝ TRƯỜNG HỢP DANH SÁCH TRỐNG
          if (allStores.isEmpty) {
            return const Center(child: Text('No salons found near you.'));
          }

          // HIỂN THỊ DANH SÁCH DƯỚI DẠNG DANH SÁCH CUỘN (LISTVIEW)
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allStores.length,
            itemBuilder: (context, index) {
              final store = allStores[index];
              return _buildStoreCard(context, store);
            },
          );
        },
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// WIDGET: _BUILDSTORECARD - THIẾT KẾ THẺ CỬA HÀNG (UI COMPONENT)
  /// -------------------------------------------------------------------------
  /// Sử dụng cấu trúc Row để hiển thị ảnh bên trái và thông tin bên phải.
  Widget _buildStoreCard(BuildContext context, Store store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // ĐIỀU HƯỚNG SANG TRANG CHI TIẾT KHI NHẤN VÀO THẺ
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StoreDetails(storeId: store.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // PHẦN 1: HÌNH ẢNH VÀ TRẠNG THÁI HOẠT ĐỘNG
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: _buildSmartImage(store.imgUrl),
                    ),
                  ),
                  // BADGE OPEN/CLOSED: TỰ ĐỘNG CẬP NHẬT THEO GIỜ HÀNH CHÍNH
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (store.isOpen) ? AppColors.success500 : AppColors.error500,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        (store.isOpen) ? 'OPEN' : 'CLOSED',
                        style: const TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // PHẦN 2: THÔNG TIN Tên, Địa chỉ, Đánh giá, Khoảng cách
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: AppTypography.textMD.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.address,
                      style: AppTypography.textXS.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning500, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          store.rating.toString(),
                          style: AppTypography.textXS.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "(${store.reviewsCount} reviews)",
                          style: AppTypography.textXS.copyWith(color: Colors.grey),
                        ),
                        const Spacer(),
                        // HIỂN THỊ KHOẢNG CÁCH KM DỰA TRÊN TỌA ĐỘ THỰC
                        Text(
                          "${store.distance.toStringAsFixed(1)} km",
                          style: AppTypography.textXS.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
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

  /// -------------------------------------------------------------------------
  /// HÀM PHỤ TRỢ: XỬ LÝ ẢNH THÔNG MINH (SMART IMAGE)
  /// -------------------------------------------------------------------------
  /// Đảm bảo ứng dụng không bị lỗi giao diện khi đường dẫn ảnh trống hoặc hỏng.
  Widget _buildSmartImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
    );
  }
}