// lib/UI/your_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/UI/booking/booking_screen.dart';
import 'package:applamdep/models/appointment_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/UI/booking/appointment_detail_screen.dart'; // Thêm import này

class YourAppointmentScreen extends StatefulWidget {
  const YourAppointmentScreen({super.key});

  @override
  State<YourAppointmentScreen> createState() => _YourAppointmentScreenState();
}

class _YourAppointmentScreenState extends State<YourAppointmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Appointment> _appointments = [];
  bool _isLoading = true;
  Map<String, Store> _stores = {};
  Map<String, Nail> _nails = {};

  // Tạo Nail mặc định để truyền vào BookingScreen
  late final Nail _defaultNail = Nail(
    id: 'default_empty',
    name: 'Chọn mẫu nail',
    imgUrl: 'assets/images/nail1.png',
    likes: 0,
    price: 0,
    description: 'Vui lòng chọn mẫu nail trong quá trình đặt lịch',
    storeId: '',
    tags: ['default'],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _appointments = [];
        });
        return;
      }

      // TẠM THỜI: Load tất cả appointments rồi filter ở client
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .get();

      // Filter theo userId và sort ở client
      var appointments = appointmentsSnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((appointment) => appointment.userId == userId)
          .toList()
        ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      // Load stores
      final storesSnapshot = await _firestore.collection('stores').get();
      final stores = <String, Store>{};
      for (var doc in storesSnapshot.docs) {
        stores[doc.id] = Store.fromFirestore(doc);
      }

      // Load nails (giới hạn số lượng để tăng tốc)
      final nailsSnapshot = await _firestore.collection('nails').limit(50).get();
      final nails = <String, Nail>{};
      for (var doc in nailsSnapshot.docs) {
        nails[doc.id] = Nail.fromFirestore(doc);
      }

      setState(() {
        _stores = stores;
        _nails = nails;
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đang tải dữ liệu... Vui lòng thử lại sau'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  // Các helper methods
  String _getStatusText(String status) {
    const statusMap = {
      'pending': 'Chờ xác nhận',
      'confirmed': 'Đã xác nhận',
      'completed': 'Đã hoàn thành',
      'cancelled': 'Đã hủy',
    };
    return statusMap[status] ?? status;
  }

  Color _getStatusColor(String status) {
    const colorMap = {
      'pending': Colors.orange,
      'confirmed': Colors.green,
      'completed': Colors.blue,
      'cancelled': Colors.red,
    };
    return colorMap[status] ?? Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    const iconMap = {
      'pending': Icons.pending_actions,
      'confirmed': Icons.check_circle,
      'completed': Icons.done_all,
      'cancelled': Icons.cancel,
    };
    return iconMap[status] ?? Icons.calendar_today;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} DOLLAR';
    }
    return '${amount.toStringAsFixed(0)} DOLLAR';
  }

  String _formatTimeSlot(String timeSlot) {
    if (timeSlot.isEmpty || timeSlot == ':00-:00') return 'Chưa chọn giờ';

    try {
      final parts = timeSlot.split('-');
      if (parts.length == 2) {
        final start = parts[0];
        final end = parts[1];
        return '$start - $end';
      }
    } catch (e) {
      debugPrint('Error parsing timeSlot: $e');
    }

    return timeSlot;
  }

  Widget _buildNailDesignItem(Map<String, dynamic> design, int index) {
    final nailId = design['nailId']?.toString() ?? '';
    final nail = _nails[nailId];
    final nailName = nail?.name ?? design['nailName']?.toString() ?? 'Thiết kế không xác định';
    final price = (design['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = design['quantity'] as int? ?? 1;
    final totalPrice = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Hình ảnh nail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey.shade100,
            ),
            child: nail?.imgUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                nail!.imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image, size: 20, color: Colors.grey);
                },
              ),
            )
                : const Icon(Icons.photo, size: 20, color: Colors.grey),
          ),

          const SizedBox(width: 12),

          // Thông tin chi tiết
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nailName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(
                      'SL: $quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      '${_formatCurrency(price)}/sp',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tổng tiền cho sản phẩm này
          Text(
            _formatCurrency(totalPrice),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF25278),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final store = _stores[appointment.storeId];
    final storeName = store?.name ?? 'Cửa hàng không xác định';
    final storeAddress = store?.address ?? '';

    return GestureDetector(
      onTap: () {
        // Điều hướng đến trang chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailScreen(
              appointmentId: appointment.id,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với trạng thái và ngày
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge trạng thái
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(appointment.status),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(appointment.status),
                          size: 14,
                          color: _getStatusColor(appointment.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(appointment.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(appointment.status),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ngày đặt lịch
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        appointment.formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _formatTimeSlot(appointment.timeSlot),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Thông tin cửa hàng
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.store_outlined, size: 20, color: Color(0xFFF25278)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          if (storeAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              storeAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Xem trước thiết kế nail
              if (appointment.nailDesigns.isNotEmpty) ...[
                const Text(
                  'Thiết kế nail:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Hiển thị tối đa 2 mẫu nail
                ...appointment.nailDesigns
                    .take(2)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) => _buildNailDesignItem(entry.value, entry.key))
                    .toList(),

                // Nếu có nhiều hơn 2 mẫu, hiển thị thông báo
                if (appointment.nailDesigns.length > 2) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${appointment.nailDesigns.length - 2} thiết kế khác',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              // Xem trước dịch vụ bổ sung
              if (appointment.additionalServices.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.spa,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${appointment.additionalServices.length} dịch vụ bổ sung',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Tổng thanh toán
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng thanh toán',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        if (appointment.discountAmount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Đã giảm ${_formatCurrency(appointment.discountAmount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (appointment.discountAmount > 0) ...[
                          Text(
                            _formatCurrency(appointment.totalPrice),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],

                        Text(
                          _formatCurrency(appointment.finalPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF25278),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Ghi chú ngắn
              if (appointment.customerNotes != null &&
                  appointment.customerNotes!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.customerNotes!.length > 50
                            ? '${appointment.customerNotes!.substring(0, 50)}...'
                            : appointment.customerNotes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Nút xem chi tiết
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF25278).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: Colors.pink.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFF25278),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tải lịch hẹn...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 70,
              color: Color(0xFFF25278),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Chưa có lịch hẹn nào',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Hãy khám phá các mẫu nail đẹp và đặt lịch với thợ chuyên nghiệp để có bộ nail hoàn hảo!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(selectedNail: _defaultNail),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25278),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
              shadowColor: const Color(0xFFF25278).withOpacity(0.3),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Đặt lịch ngay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lịch sử đặt lịch',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: const Color(0xFFF25278),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _appointments.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: const Color(0xFFF25278),
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Thống kê
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.pending_actions,
                      value: _appointments
                          .where((a) => a.isPending)
                          .length
                          .toString(),
                      label: 'Chờ xác nhận',
                      color: Colors.orange,
                    ),
                    _buildStatItem(
                      icon: Icons.check_circle,
                      value: _appointments
                          .where((a) => a.isConfirmed)
                          .length
                          .toString(),
                      label: 'Đã xác nhận',
                      color: Colors.green,
                    ),
                    _buildStatItem(
                      icon: Icons.done_all,
                      value: _appointments
                          .where((a) => a.isCompleted)
                          .length
                          .toString(),
                      label: 'Đã hoàn thành',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),

            // Tiêu đề danh sách
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tất cả lịch hẹn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF25278).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_appointments.length} lịch hẹn',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF25278),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Danh sách lịch hẹn
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _buildAppointmentCard(_appointments[index]);
                  },
                  childCount: _appointments.length,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(selectedNail: _defaultNail),
            ),
          );
        },
        backgroundColor: const Color(0xFFF25278),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Đặt lịch mới',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}