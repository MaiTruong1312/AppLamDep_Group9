// lib/UI/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/models/user_model.dart';
import 'package:applamdep/UI/booking/your_appointment_screen.dart';
import 'package:applamdep/UI/booking/confirm_appointment_screen.dart';
import 'package:applamdep/UI/booking/main_booking_screen.dart';
class BookingScreen extends StatefulWidget {
  final Nail selectedNail;
  final Store? selectedStore;

  const BookingScreen({
    super.key,
    required this.selectedNail,
    this.selectedStore,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedTime = '';

  // Thời gian có sẵn
  final List<String> morningTimes = ['09:00', '10:00', '11:00', '12:00'];
  final List<String> afternoonTimes = [
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00'
  ];

  // Danh sách dịch vụ
  List<ServiceItem> services = [];

  // Chi nhánh (stores)
  List<Store> stores = [];
  late Store selectedStore;

  // Thông tin user
  UserModel? currentUser;
  String note = '';
  bool _isLoading = false;
  bool _isLoadingStores = true;

  // Controller cho thông tin user
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadUserInfo();
    _loadStores();
    _initializeServices();
  }

  // Khởi tạo dịch vụ từ nail được chọn
  void _initializeServices() {
    services = [
      // Nail chính được chọn
      ServiceItem(
        id: widget.selectedNail.id,
        name: widget.selectedNail.name,
        price: widget.selectedNail.price.toDouble(),
        duration: '90 mins', // Có thể lấy từ estimated_time của nail
        imagePath: widget.selectedNail.imgUrl,
        quantity: 1,
        isMainService: true,
      ),
      // Các dịch vụ thêm (có thể load từ store services)
      ServiceItem(
        id: 'service_1',
        name: 'Sơn gel bột',
        price: 10.0,
        duration: '30 mins',
        imagePath: 'assets/images/service_1.png',
        quantity: 0,
        isMainService: false,
      ),
      ServiceItem(
        id: 'service_2',
        name: 'Đính đá viền',
        price: 15.0,
        duration: '45 mins',
        imagePath: 'assets/images/service_2.png',
        quantity: 0,
        isMainService: false,
      ),
    ];
  }

  // Load danh sách stores từ Firestore
  Future<void> _loadStores() async {
    try {
      final storesSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('is_open', isEqualTo: true)
          .limit(10)
          .get();

      setState(() {
        stores = storesSnapshot.docs
            .map((doc) => Store.fromFirestore(doc))
            .toList();

        // Chọn store mặc định
        if (stores.isNotEmpty) {
          // Ưu tiên store của nail nếu có
          if (widget.selectedStore != null) {
            selectedStore = widget.selectedStore!;
          } else if (widget.selectedNail.storeId.isNotEmpty) {
            // Tìm store của nail
            final nailStore = stores.firstWhere(
                  (store) => store.id == widget.selectedNail.storeId,
              orElse: () => stores.first,
            );
            selectedStore = nailStore;
          } else {
            selectedStore = stores.first;
          }
        }
        _isLoadingStores = false;
      });
    } catch (e) {
      print('Error loading stores: $e');
      setState(() => _isLoadingStores = false);
    }
  }

  // Load thông tin user từ Firestore
  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            currentUser = UserModel.fromFirestore(userDoc);
            _nameController.text = currentUser!.name;
          });
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  // Tính tổng tiền
  double get totalPrice {
    return services.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get totalServices {
    return services.fold(0, (sum, item) => sum + item.quantity);
  }

  // Xử lý đặt lịch
  Future<void> _handleBooking() async {
    if (!_validateBooking()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để đặt lịch'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Tạo booking document
      final bookingData = {
        'user_id': user.uid,
        'user_name': _nameController.text.trim(),
        'user_phone': _phoneController.text.trim(),
        'store_id': selectedStore.id,
        'store_name': selectedStore.name,
        'store_address': selectedStore.address,
        'store_phone': selectedStore.phone,
        'nail_id': widget.selectedNail.id,
        'nail_name': widget.selectedNail.name,
        'nail_image': widget.selectedNail.imgUrl,
        'nail_price': widget.selectedNail.price,
        'booking_date': Timestamp.fromDate(_selectedDay!),
        'booking_time': _selectedTime,
        'services': services
            .where((item) => item.quantity > 0)
            .map((item) => {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
        })
            .toList(),
        'total_price': totalPrice,
        'status': 'pending', // pending, confirmed, completed, cancelled
        'note': note,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      };

      // Lưu vào Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      // Chuyển sang màn hình xác nhận
      _navigateToConfirmation(bookingData);

    } catch (e) {
      print('Booking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt lịch thất bại: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateBooking() {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn giờ'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (totalServices == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một dịch vụ'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }

  void _navigateToConfirmation(Map<String, dynamic> bookingData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmAppointmentScreen(
          bookingData: bookingData,
          selectedNail: widget.selectedNail,
          selectedStore: selectedStore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đặt Lịch',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const YourAppointmentScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoadingStores
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin nail đang đặt
                _buildNailInfo(),
                const SizedBox(height: 20),

                // Chọn chi nhánh
                _buildBranchSection(),
                const SizedBox(height: 24),

                // Chọn ngày
                _buildDateSection(),
                const SizedBox(height: 24),

                // Chọn giờ
                _buildTimeSection(),
                const SizedBox(height: 24),

                // Dịch vụ
                _buildServicesSection(),
                const SizedBox(height: 24),

                // Thông tin cá nhân
                _buildPersonalInfo(),
                const SizedBox(height: 24),

                // Ghi chú
                _buildNotesSection(),
                const SizedBox(height: 24),

                // Tổng tiền
                _buildTotalSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Nút tiếp tục
          if (_canShowContinueButton())
            Positioned(
              left: 16,
              right: 16,
              bottom: 30,
              child: _buildContinueButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildNailInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.selectedNail.imgUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.photo, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedNail.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(widget.selectedNail.price)}',
                  style: const TextStyle(
                    color: Color(0xFFF25278),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.selectedNail.isBestChoice)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Best Choice',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFF25278),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn Chi Nhánh',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _buildBranchBottomSheet(),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFFF25278)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStore.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedStore.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_focusedDay.month}/${_focusedDay.year}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            headerVisible: false,
            daysOfWeekHeight: 40,
            rowHeight: 52,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFFFE4E8),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFFF25278),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Color(0xFFF25278),
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: TextStyle(color: Colors.white),
              disabledTextStyle: TextStyle(color: Colors.grey),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(color: Color(0xFFF25278)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buổi Sáng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: morningTimes.map((time) => _buildTimeChip(time)).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Buổi Chiều',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: afternoonTimes.map((time) => _buildTimeChip(time)).toList(),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Bạn có thể đặt tối đa 3 dịch vụ',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dịch Vụ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            if (service.quantity == 0 && service.isMainService) {
              return _buildServiceItem(service, index);
            } else if (service.quantity > 0) {
              return _buildServiceItem(service, index);
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => _buildAddServiceBottomSheet(),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '+ Thêm dịch vụ',
                style: TextStyle(
                  color: Color(0xFFF25278),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông Tin Cá Nhân',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Họ và Tên',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tên';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Số Điện Thoại',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập số điện thoại';
            }
            if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
              return 'Số điện thoại không hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ghi Chú',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) => note = value,
          decoration: InputDecoration(
            hintText: 'Lưu ý cho tiệm nail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tổng Cộng ($totalServices dịch vụ${totalServices > 1 ? 's' : ''})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'en_US', symbol: '\$').format(totalPrice),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF25278),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    bool isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF25278) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFFF25278) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(ServiceItem service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: service.imagePath.startsWith('http')
                ? Image.network(
              service.imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Icon(Icons.photo, color: Colors.grey),
              ),
            )
                : Image.asset(
              service.imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(service.price)} • ${service.duration}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          if (!service.isMainService)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      if (service.quantity > 0) service.quantity--;
                    });
                  },
                ),
                Text(
                  '${service.quantity}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFFF25278),
                  ),
                  onPressed: () {
                    setState(() {
                      if (totalServices < 3) service.quantity++;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBranchBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn Chi Nhánh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    final isSelected = selectedStore.id == store.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: isSelected ? 6 : 2,
                      color: isSelected ? const Color(0xFFFFF5F7) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: isSelected ? const Color(0xFFF25278) : Colors.pink,
                          size: 32,
                        ),
                        title: Text(
                          store.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          store.address,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFFF25278),
                          size: 28,
                        )
                            : null,
                        onTap: () {
                          setState(() {
                            selectedStore = store;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddServiceBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thêm Dịch Vụ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                if (service.isMainService) return const SizedBox.shrink();

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: service.imagePath.startsWith('http')
                        ? Image.network(
                      service.imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      service.imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(service.name),
                  subtitle: Text(
                    '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(service.price)} • ${service.duration}',
                  ),
                  trailing: service.quantity > 0
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() => service.quantity--);
                        },
                      ),
                      Text('${service.quantity}'),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Color(0xFFF25278),
                        ),
                        onPressed: () {
                          if (totalServices < 3) {
                            setState(() => service.quantity++);
                          }
                        },
                      ),
                    ],
                  )
                      : ElevatedButton(
                    onPressed: () {
                      if (totalServices < 3) {
                        setState(() => service.quantity = 1);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Thêm'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF25278),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Text(
          'TIẾP TỤC',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _canShowContinueButton() {
    return totalServices > 0 &&
        _selectedDay != null &&
        _selectedTime.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

// Class ServiceItem
class ServiceItem {
  String id;
  String name;
  double price;
  String duration;
  String imagePath;
  int quantity;
  bool isMainService;

  ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.imagePath,
    required this.quantity,
    this.isMainService = false,
  });
}

// Class Branch (Store)
class Branch {
  final String id;
  final String name;
  final String address;

  Branch({required this.id, required this.name, required this.address});
}
