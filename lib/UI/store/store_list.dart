import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:applamdep/providers/store_provider.dart';
import 'package:applamdep/theme/app_colors.dart';
import 'package:applamdep/theme/app_typography.dart';
import 'store_details.dart';
import '../../models/store_model.dart';

class StoreList extends StatefulWidget {
  const StoreList({super.key});

  @override
  _StoreListState createState() => _StoreListState();
}

class _StoreListState extends State<StoreList> {
  @override
  void initState() {
    super.initState();
    // Khởi tạo lấy vị trí và danh sách tiệm ngay khi vào trang
    Future.microtask(() {
      final provider = Provider.of<StoreProvider>(context, listen: false);
      provider.fetchUserLocation().then((_) => provider.fetchAllStores());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền xám nhạt để nổi bật các Card
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
      body: Consumer<StoreProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: AppColors.error500)));
          }
          if (provider.stores.isEmpty) {
            return const Center(child: Text('No salons found near you.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.stores.length,
            itemBuilder: (context, index) {
              final store = provider.stores[index];
              return _buildStoreCard(context, store);
            },
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildStoreCard(BuildContext context, Store store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StoreDetails(storeId: store.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ảnh đại diện tiệm với bo góc và badge trạng thái
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
                  // Hiển thị trạng thái Đóng/Mở cửa
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
              // Thông tin chi tiết tiệm
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
                        // Hiển thị khoảng cách nếu có
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

  // Giải quyết lỗi "No host specified" bằng cách kiểm tra path ảnh
  Widget _buildSmartImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
    }
    // Nếu là ảnh từ Internet
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }
    // Nếu là ảnh từ Assets cục bộ
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
    );
  }
}