import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/services/booking_cart_service.dart';
import 'package:applamdep/models/booking_cart_model.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/UI/detail/nail_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:applamdep/UI/booking/booking_screen.dart';

class BookingCartScreen extends StatefulWidget {
  const BookingCartScreen({super.key});

  @override
  State<BookingCartScreen> createState() => _BookingCartScreenState();
}

class _BookingCartScreenState extends State<BookingCartScreen> {
  final BookingCartService _bookingCartService = BookingCartService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Danh sách đặt lịch'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF25278),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<int>(
            stream: _bookingCartService.getBookingCartItemCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox();

              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _showClearAllDialog,
                tooltip: 'Xóa tất cả',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header với số lượng
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: StreamBuilder<int>(
              stream: _bookingCartService.getBookingCartItemCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFFF25278),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mẫu nail đã chọn',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            '$count mẫu',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF25278),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Danh sách mẫu nail
          Expanded(
            child: _buildNailList(),
          ),

          // Nút tiếp tục
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildNailList() {
    return StreamBuilder<List<BookingCartItem>>(
      stream: _bookingCartService.getBookingCartItems(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Có lỗi xảy ra: ${snapshot.error}',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildNailCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildNailCard(BookingCartItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final nail = Nail(
            id: item.nailId,
            name: item.nailName,
            imgUrl: item.nailImage,
            price: item.price.toInt(),
            storeId: item.storeId,
            likes: 0,
            isBestChoice: false,
            description: '',
            tags: [],
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NailDetailScreen(nail: nail),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Hình ảnh (Đã sửa)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.nailImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Widget hiển thị khi có lỗi
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    // Widget hiển thị trong lúc tải ảnh
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF25278)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nailName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.storeName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currencyFormat.format(item.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF25278),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _showDeleteDialog(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          StreamBuilder<int>(
            stream: _bookingCartService.getBookingCartItemCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: count > 0 ? () => _proceedToBookingDetails(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF25278),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TIẾP TỤC ĐẶT LỊCH${count > 0 ? ' ($count)' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 60,
              color: Color(0xFFF25278),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có mẫu nail nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Hãy chọn mẫu nail bạn yêu thích và thêm vào danh sách đặt lịch',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25278),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 18),
                SizedBox(width: 8),
                Text('QUAY LẠI CHỌN MẪU'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 18,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BookingCartItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa mẫu nail'),
          content: Text('Bạn có chắc muốn xóa "${item.nailName}" khỏi danh sách đặt lịch?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('HỦY'),
            ),
            TextButton(
              onPressed: () {
                _bookingCartService.removeFromBookingCart(item.nailId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa "${item.nailName}"'),
                    backgroundColor: const Color(0xFFF25278),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('XÓA'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog() async {
    final count = await _bookingCartService.getBookingCartItemCount().first;
    if (count == 0) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa tất cả'),
          content: Text('Bạn có chắc muốn xóa tất cả $count mẫu nail khỏi danh sách đặt lịch?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('HỦY'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearAllItems();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('XÓA TẤT CẢ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllItems() async {
    try {
      await _bookingCartService.clearBookingCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa tất cả mẫu nail'),
            backgroundColor: Color(0xFFF25278),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToBookingDetails(BuildContext context) async {
    // Lấy danh sách items hiện tại
    final items = await _bookingCartService.getBookingCartItems().first;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một mẫu nail'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra xem tất cả items có cùng store không
    final firstStoreId = items.first.storeId;
    final allSameStore = items.every((item) => item.storeId == firstStoreId);

    if (!allSameStore) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Các mẫu nail được chọn từ nhiều cửa hàng khác nhau. Vui lòng đặt lịch từng cửa hàng riêng biệt.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }
    final store = Store(
      id: firstStoreId,
      name: items.first.storeName,
      address: '',
      phone: '',
      isOpen: true,
      imgUrl: '',
      location: const GeoPoint(0, 0),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          selectedNail: _convertToNail(items.first),
          selectedStore: store,
          bookingCartItems: items,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Helper method để convert BookingCartItem sang Nail
  Nail _convertToNail(BookingCartItem item) {
    return Nail(
      id: item.nailId,
      name: item.nailName,
      imgUrl: item.nailImage,
      price: item.price.toInt(),
      storeId: item.storeId,
      likes: 0,
      isBestChoice: false,
      description: '',
      tags: [],
    );
  }
}
