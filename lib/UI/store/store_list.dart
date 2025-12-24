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
      margin: const EdgeInsets.only(bottom: 20, left: 2, right: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Bo góc sâu tạo cảm giác hiện đại
        boxShadow: [
          // HIỆU ỨNG ĐỔ BÓNG HỒNG NHẸ PRIMARY400
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12), // Hồng nhạt thanh lịch
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StoreDetails(storeId: store.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // PHẦN 1: HÌNH ẢNH VÀ TRẠNG THÁI (GỌN GÀNG HƠN)
              Stack(
                children: [
                  Hero(
                    tag: 'store_${store.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: _buildSmartImage(store.imgUrl),
                      ),
                    ),
                  ),
                  // NHÃN TRẠNG THÁI (Thiết kế lại nhỏ gọn)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (store.isOpen)
                            ? AppColors.success500.withOpacity(0.9)
                            : AppColors.error500.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (store.isOpen) ? 'OPEN' : 'CLOSED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),

              // PHẦN 2: NỘI DUNG (CĂN CHỈNH CHIỀU SÂU)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên tiệm và khoảng cách trên cùng một dòng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: AppTypography.textMD.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2D2E32),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Địa chỉ với Icon định vị mờ
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.address,
                            style: AppTypography.textXS.copyWith(
                              color: Colors.grey[500],
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // HÀNG CUỐI: ĐÁNH GIÁ VÀ KHOẢNG CÁCH (CÂN XỨNG)
                    Row(
                      children: [
                        // Rating Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning500.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning500, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                store.rating.toString(),
                                style: AppTypography.textXS.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${store.reviewsCount} reviews",
                          style: AppTypography.textXS.copyWith(color: Colors.grey[400]),
                        ),
                        const Spacer(),
                        // Khoảng cách nổi bật bằng màu Primary
                        Text(
                          "${store.distance.toStringAsFixed(1)} km",
                          style: AppTypography.textSM.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
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