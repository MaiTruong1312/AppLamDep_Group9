// lib/UI/booking/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/store_model.dart' hide Service;
import 'package:applamdep/models/user_model.dart';
import 'package:applamdep/models/service_model.dart';
import 'package:applamdep/models/booking_slot_model.dart';
import 'package:applamdep/models/technician_model.dart';
import 'package:applamdep/models/appointment_model.dart';
import 'package:applamdep/models/booking_cart_model.dart';
import 'package:applamdep/services/booking_cart_service.dart';
import 'package:applamdep/services/booking_service.dart';
import 'package:applamdep/services/coupon_service.dart';
import 'package:applamdep/UI/booking/your_appointment_screen.dart' hide Coupon;
import 'package:applamdep/UI/booking/confirm_appointment_screen.dart';
import 'package:applamdep/models/coupon_model.dart';

class BookingScreen extends StatefulWidget {
  final Nail selectedNail;
  final Store? selectedStore;
  final List<BookingCartItem>? bookingCartItems;
  const BookingScreen({
    super.key,
    required this.selectedNail,
    this.selectedStore,
    this.bookingCartItems,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Services
  final BookingService _bookingService = BookingService();
  final BookingCartService _bookingCartService = BookingCartService();
  final CouponService _couponService = CouponService();

  // Data lists
  List<Store> stores = [];
  List<Service> additionalServices = [];
  List<BookingSlot> availableSlots = [];
  List<Technician> technicians = [];
  List<Coupon> availableCoupons = [];

  // Selected items
  late Store selectedStore;
  BookingSlot? selectedSlot;
  Technician? selectedTechnician;
  Coupon? selectedCoupon;

  // Main nail services (from booking cart or selected nail)
  final List<AppointmentService> _mainNailServices = [];

  // User info
  UserModel? currentUser;
  String note = '';
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  final Map<String, String> _categoryDisplayNames = {
    'care': 'Chăm sóc & Tháo',
    'nail_service': 'Sơn & Tạo kiểu',
    'additional_service': 'Dịch vụ nâng cao',
    'spa': 'Spa & Thư giãn',
    'other': 'Dịch vụ khác',
  };

  // Selected time for UI (manual selection)
  String _selectedTime = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeMainServices();
    // Khởi tạo dummy store để tránh lỗi null check operator used on a null value ban đầu
    selectedStore = widget.selectedStore ?? Store(
        id: '', name: '', address: '', imgUrl: '',
        openingHours: {}, services: [], flashsales: [], portfolio: [], reviews: [],
        hotline: '', email: '', website: '', description: '', distance: 0, isOpen: true
    );

    _loadAllData();
  }

  void _initializeMainServices() {
    _mainNailServices.clear();

    if (widget.bookingCartItems != null && widget.bookingCartItems!.isNotEmpty) {
      // From booking cart (multiple nails)
      for (var cartItem in widget.bookingCartItems!) {
        _mainNailServices.add(
          AppointmentService(
            serviceId: cartItem.nailId,
            serviceName: cartItem.nailName,
            price: cartItem.price,
            quantity: 1,
          ),
        );
      }
    } else {
      // Single selected nail
      _mainNailServices.add(
        AppointmentService(
          serviceId: widget.selectedNail.id,
          serviceName: widget.selectedNail.name,
          price: widget.selectedNail.price.toDouble(),
          quantity: 1,
        ),
      );
    }
  }

  Future<void> _loadAllData() async {
    try {
      await Future.wait([
        _loadUserInfo(),
        _loadStores(),
      ]);

      // Sau khi load store xong, nếu có store hợp lệ thì load các data con
      if (selectedStore.id.isNotEmpty) {
        await Future.wait([
          _loadAdditionalServices(),
          _loadTechnicians(),
          _loadAvailableSlots(),
          _loadCoupons(),
        ]);
      }

      setState(() => _isLoadingData = false);
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadStores() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('is_open', isEqualTo: true)
          .limit(10)
          .get();

      setState(() {
        stores = snapshot.docs
            .map((doc) => Store.fromFirestore(doc))
            .toList();

        if (stores.isNotEmpty) {
          // Logic chọn store mặc định
          if (widget.selectedStore != null && widget.selectedStore!.id.isNotEmpty) {
            selectedStore = widget.selectedStore!;
          } else if (widget.selectedNail.storeId.isNotEmpty) {
            final nailStore = stores.firstWhere(
                  (store) => store.id == widget.selectedNail.storeId,
              orElse: () => stores.first,
            );
            selectedStore = nailStore;
          } else {
            selectedStore = stores.first;
          }
        }
      });
    } catch (e) {
      print('Error loading stores: $e');
    }
  }

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
            if (currentUser!.phone != null && currentUser!.phone!.isNotEmpty) {
              _phoneController.text = currentUser!.phone!;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadAdditionalServices() async {
    if (selectedStore.id.isEmpty) return;
    try {
      final services = await _bookingService.getStoreServices(selectedStore.id);
      setState(() {
        // Lọc bỏ các service chính nếu cần, giữ lại các service thêm
        additionalServices = services.where((s) => s.category != 'nail_design' && s.isActive).toList();
      });
    } catch (e) {
      print('Error loading additional services: $e');
    }
  }

  Future<void> _loadTechnicians() async {
    if (selectedStore.id.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('store_technicians')
          .where('storeId', isEqualTo: selectedStore.id)
          .where('isAvailable', isEqualTo: true)
          .get();

      setState(() {
        technicians = snapshot.docs
            .map((doc) => Technician.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error loading technicians: $e');
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (selectedStore.id.isEmpty || _selectedDay == null) return;
    try {
      final slots = await _bookingService.getAvailableSlots(
        storeId: selectedStore.id,
        date: _selectedDay!,
      );
      setState(() => availableSlots = slots);
    } catch (e) {
      print('Error loading slots: $e');
    }
  }

  Future<void> _loadCoupons() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .where('expiryDate', isGreaterThan: Timestamp.now())
          .get();

      setState(() {
        availableCoupons = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Fix logic đọc dữ liệu an toàn
          return Coupon(
            id: doc.id,
            code: data['code']?.toString() ?? '',
            discountType: data['discountType']?.toString() ?? 'PERCENTAGE',
            discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
            minimumOrderAmount: (data['minimumOrderAmount'] as num?)?.toDouble(),
            maxDiscountAmount: (data['maxDiscountAmount'] as num?)?.toDouble(),
            expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            usageLimit: (data['usageLimit'] as int?) ?? 0,
            usedCount: (data['usedCount'] as int?) ?? 0,
            isActive: data['isActive'] ?? false,
            // Sửa tên field cho khớp với database
            applicableCategories: List<String>.from(
                data['applicableServiceCategories'] ?? data['applicableCategories'] ?? []
            ),
            isFirstBookingOnly: data['isFirstBookingOnly'] ?? false,
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading coupons: $e');
    }
  }

  // --- LOGIC TÍNH TIỀN ---
  double get subtotalPrice {
    double total = 0;

    // 1. Tiền Nail chính
    for (var service in _mainNailServices) {
      total += service.price * service.quantity;
    }

    // 2. Tiền Dịch vụ thêm
    for (var service in additionalServices) {
      total += service.price * (service.quantity ?? 0);
    }

    return total;
  }

  double get discountAmount {
    if (selectedCoupon != null && selectedCoupon!.isValid) {
      final discount = selectedCoupon!.applyDiscount(subtotalPrice);
      return subtotalPrice - discount;
    }
    return 0;
  }

  double get totalPrice {
    return subtotalPrice - discountAmount;
  }

  // --- HANDLE BOOKING ---
  Future<void> _handleBooking() async {
    if (!_validateBooking()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để đặt lịch');
      }

      // Calculate duration
      int totalDuration = 0;
      for (var service in _mainNailServices) {
        totalDuration += 60; // Mặc định 60p cho nail chính
      }
      for (var service in additionalServices) {
        if ((service.quantity ?? 0) > 0) {
          totalDuration += service.duration * (service.quantity ?? 1);
        }
      }

      // Xử lý Time Slot string
      String finalTimeSlot = '';
      if (selectedSlot != null) {
        finalTimeSlot = selectedSlot!.timeSlot;
      } else if (_selectedTime.isNotEmpty) {
        // Tạo format HH:00 - (HH+1):00
        int startHour = int.tryParse(_selectedTime.split(':')[0]) ?? 9;
        int endHour = startHour + 1;
        finalTimeSlot = '$_selectedTime-${endHour.toString().padLeft(2, '0')}:00';
      }

      // Prepare appointment data
      final appointmentData = {
        'userId': user.uid,
        'storeId': selectedStore.id,
        'technicianId': selectedTechnician?.id,
        'bookingDate': Timestamp.fromDate(_selectedDay!),
        'timeSlot': finalTimeSlot,
        'duration': totalDuration,
        'status': 'pending',

        // Nail designs
        'nailDesigns': _mainNailServices.map((service) => {
          'nailId': service.serviceId,
          'nailName': service.serviceName,
          'price': service.price,
          'quantity': service.quantity,
        }).toList(),

        // Additional services (CHỈ LẤY NHỮNG SERVICE ĐÃ CHỌN SỐ LƯỢNG > 0)
        'additionalServices': additionalServices
            .where((service) => (service.quantity ?? 0) > 0)
            .map((service) => AppointmentService(
          serviceId: service.id,
          serviceName: service.name,
          price: service.price,
          quantity: service.quantity ?? 1,
        ).toMap())
            .toList(),

        'totalPrice': subtotalPrice,
        'discountAmount': discountAmount,
        'finalPrice': totalPrice,
        'couponCode': selectedCoupon?.code,

        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim(),
        'customerNotes': note,

        'paymentStatus': 'pending',
        'paymentMethod': null,
        'paymentId': null,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create appointment
      final appointmentId = await _bookingService.createAppointment(appointmentData);

      // Update slot if selected (giảm slot trống)
      if (selectedSlot != null) {
        await FirebaseFirestore.instance
            .collection('booking_slots')
            .doc(selectedSlot!.id)
            .update({
          'currentBookings': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update coupon usage
      if (selectedCoupon != null) {
        await _couponService.applyCoupon(selectedCoupon!.id);
      }

      // Clear booking cart
      if (widget.bookingCartItems != null && widget.bookingCartItems!.isNotEmpty) {
        await _bookingCartService.clearBookingCart();
      }

      // Navigate to confirmation
      if (mounted) {
        _navigateToConfirmation(appointmentId, appointmentData);
      }

    } catch (e) {
      print('Booking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt lịch thất bại: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateBooking() {
    if (_selectedDay == null) {
      _showError('Vui lòng chọn ngày');
      return false;
    }

    // Kiểm tra đã chọn giờ chưa (Slot hoặc Manual Time)
    if (selectedSlot == null && _selectedTime.isEmpty) {
      _showError('Vui lòng chọn giờ làm dịch vụ');
      return false;
    }

    if (_mainNailServices.isEmpty) {
      _showError('Vui lòng chọn ít nhất một mẫu nail');
      return false;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError('Vui lòng nhập tên');
      return false;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showError('Vui lòng nhập số điện thoại');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  void _navigateToConfirmation(String appointmentId, Map<String, dynamic> appointmentData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmAppointmentScreen(
          appointmentId: appointmentId,
          appointmentData: appointmentData,
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
        title: Text(
          _mainNailServices.length > 1
              ? 'Đặt Lịch (${_mainNailServices.length} mẫu)'
              : 'Đặt Lịch',
          style: const TextStyle(
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
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStoreInfo(),
                const SizedBox(height: 20),
                _buildNailsInfo(),
                const SizedBox(height: 20),
                _buildStoreSelection(),
                const SizedBox(height: 20),
                _buildDateSection(),
                const SizedBox(height: 24),
                // Logic hiển thị Slot hoặc Manual Time
                if (availableSlots.isNotEmpty)
                  _buildTimeSlotsSection()
                else
                  _buildTimeSelection(),
                const SizedBox(height: 24),
                if (technicians.isNotEmpty) ...[
                  _buildTechnicianSection(),
                  const SizedBox(height: 24),
                ],
                if (additionalServices.isNotEmpty) ...[
                  _buildAdditionalServicesSection(),
                  const SizedBox(height: 24),
                ],
                _buildCouponSection(),
                const SizedBox(height: 24),
                _buildPersonalInfo(),
                const SizedBox(height: 24),
                _buildNotesSection(),
                const SizedBox(height: 24),
                _buildTotalSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
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

  // --- WIDGET BUILDERS ---

  Widget _buildStoreSelection() {
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
              builder: (context) => _buildStoreBottomSheet(),
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
                        selectedStore.name.isNotEmpty ? selectedStore.name : 'Đang chọn cửa hàng...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selectedStore.address.isNotEmpty) ...[
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
                      ]
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
        const Text(
          'Chọn Ngày',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                selectedSlot = null;
                // Nếu đổi ngày thì có thể cần reset manual time hoặc giữ nguyên tùy logic
              });
              await _loadAvailableSlots();
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

  Widget _buildTimeSelection() {
    final List<String> timeSlots = [
      '09:00', '10:00', '11:00', '12:00',
      '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn Giờ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Không có slot trống online. Vui lòng chọn giờ mong muốn, tiệm sẽ liên hệ xác nhận.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((time) => _buildTimeChip(time)).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeChip(String time) {
    bool isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF25278) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF25278) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFF25278).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn Giờ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableSlots.map((slot) => _buildTimeSlotChip(slot)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTechnicianSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn Thợ (Tùy chọn)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTechnicianChip(null),
            ...technicians.map((tech) => _buildTechnicianChip(tech)).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalServicesSection() {
    Map<String, List<Service>> groupedServices = {};
    List<String> orderedCategories = ['care', 'nail_service', 'additional_service', 'spa', 'other'];

    for (var service in additionalServices) {
      String cat = (service.category.isEmpty) ? 'other' : service.category;
      if (!groupedServices.containsKey(cat)) {
        groupedServices[cat] = [];
      }
      groupedServices[cat]!.add(service);
    }

    if (groupedServices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dịch Vụ Thêm',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn thêm các dịch vụ chăm sóc để có bộ móng hoàn hảo nhất',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ...orderedCategories.map((categoryKey) {
          if (!groupedServices.containsKey(categoryKey) || groupedServices[categoryKey]!.isEmpty) {
            return const SizedBox.shrink();
          }
          List<Service> servicesInGroup = groupedServices[categoryKey]!;
          String displayTitle = _categoryDisplayNames[categoryKey] ?? 'Dịch vụ khác';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF25278),
                  ),
                ),
              ),
              ...servicesInGroup.map((service) => _buildServiceItem(service)).toList(),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mã Giảm Giá',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                decoration: InputDecoration(
                  hintText: 'Nhập mã giảm giá',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                if (_couponController.text.isEmpty) return;

                final coupon = await _couponService.validateCoupon(
                  _couponController.text,
                  subtotalPrice,
                );

                if (coupon != null) {
                  setState(() => selectedCoupon = coupon);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Áp dụng mã ${coupon.code} thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mã giảm giá không hợp lệ'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF25278),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        if (selectedCoupon != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.discount, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã: ${selectedCoupon!.code}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        'Giảm ${selectedCoupon!.discountType == 'PERCENTAGE'
                            ? '${selectedCoupon!.discountValue}%'
                            : NumberFormat.currency(locale: 'en_US', symbol: '\$').format(selectedCoupon!.discountValue)}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      selectedCoupon = null;
                      _couponController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
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
            hintText: 'Nhập họ và tên của bạn',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Số Điện Thoại',
            hintText: 'Nhập số điện thoại của bạn',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ghi Chú Thêm',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Thông tin thêm cho tiệm nail (nếu có)',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) => note = value,
          decoration: InputDecoration(
            hintText: 'Ví dụ: Móng tay cần sửa trước, dị ứng với loại sơn nào đó...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mẫu nail:',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '${_mainNailServices.length} mẫu',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dịch vụ thêm:',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '${additionalServices.where((s) => (s.quantity ?? 0) > 0).length} dịch vụ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (selectedCoupon != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giảm giá:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '-${currencyFormat.format(discountAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormat.format(totalPrice),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25278),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotChip(BookingSlot slot) {
    final isSelected = selectedSlot?.id == slot.id;
    final isAvailable = slot.isAvailable;

    return GestureDetector(
      onTap: isAvailable ? () {
        setState(() => selectedSlot = slot);
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF25278) :
          isAvailable ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF25278) :
            isAvailable ? Colors.grey[300]! : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFF25278).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.startTime,
              style: TextStyle(
                color: isSelected ? Colors.white :
                isAvailable ? Colors.black87 : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (!isAvailable)
              Text(
                'Đã đầy',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianChip(Technician? tech) {
    final isSelected = selectedTechnician?.id == tech?.id;
    final name = tech?.name ?? 'Tự động phân công';

    return GestureDetector(
      onTap: () {
        setState(() => selectedTechnician = tech);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF25278) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF25278) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tech != null)
              CircleAvatar(
                radius: 12,
                backgroundImage: tech.avatarUrl != null
                    ? NetworkImage(tech.avatarUrl!)
                    : null,
                child: tech.avatarUrl == null
                    ? const Icon(Icons.person, size: 14)
                    : null,
              ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (tech != null && tech.rating > 0) ...[
              const SizedBox(width: 4),
              Icon(Icons.star, size: 14,
                  color: isSelected ? Colors.yellow[100] : Colors.yellow[700]),
              const SizedBox(width: 2),
              Text(
                tech.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.yellow[100] : Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF25278),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
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
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            const Text(
              'XÁC NHẬN ĐẶT LỊCH',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNailImage(String imagePath, {double width = 60, double height = 60}) {
    if (imagePath.startsWith('assets/') || !imagePath.contains('http')) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorImage(width: width, height: height);
            },
          ),
        ),
      );
    } else {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorImage(width: width, height: height);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFF25278)),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Widget _buildErrorImage({double width = 60, double height = 60}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.photo,
          color: Colors.grey,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStoreImage(selectedStore.imgUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStore.name.isNotEmpty ? selectedStore.name : 'Đang tải...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (selectedStore.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    selectedStore.address,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (selectedStore.hotline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        selectedStore.hotline,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF25278),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.store, color: Colors.white, size: 30),
      );
    }
    return _buildNailImage(imagePath, width: 60, height: 60);
  }

  Widget _buildNailsInfo() {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library, size: 20, color: Color(0xFFF25278)),
              const SizedBox(width: 8),
              Text(
                'Mẫu nail đã chọn (${_mainNailServices.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._mainNailServices.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;

            String imagePath = '';
            if (widget.selectedNail.id == service.serviceId) {
              imagePath = widget.selectedNail.imgUrl;
            } else if (widget.bookingCartItems != null) {
              // Logic tìm ảnh từ cart
              try {
                final cartItem = widget.bookingCartItems!.firstWhere(
                        (item) => item.nailId == service.serviceId
                );
                imagePath = cartItem.nailImage;
              } catch (e) {
                imagePath = 'assets/images/nail1.png';
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: index == _mainNailServices.length - 1 ? 0 : 12),
              child: Row(
                children: [
                  _buildNailImage(imagePath.isEmpty ? 'assets/images/nail1.png' : imagePath),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.serviceName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(service.price),
                          style: const TextStyle(
                            color: Color(0xFFF25278),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_mainNailServices.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          _mainNailServices.removeAt(index);
                        });
                      },
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Service service) {
    final quantity = service.quantity ?? 0;
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildServiceImage(service.imageUrl!),
            )
                : const Icon(Icons.spa, color: Color(0xFFF25278), size: 24),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currencyFormat.format(service.price)} • ${service.duration} phút',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          Row(
            children: [
              IconButton(
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
                onPressed: () {
                  setState(() {
                    if (quantity > 0) {
                      service.quantity = quantity - 1;
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF25278),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
                onPressed: () {
                  setState(() {
                    service.quantity = quantity + 1;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: const Icon(Icons.spa, color: Color(0xFFF25278), size: 24),
      );
    }
    return _buildNailImage(imagePath, width: 50, height: 50);
  }

  Widget _buildStoreBottomSheet() {
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
                        leading: _buildStoreListImage(store.imgUrl),
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
                            _loadAdditionalServices();
                            _loadTechnicians();
                            _loadAvailableSlots();
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

  // FIX: Hàm build ảnh store trong list (hỗ trợ cả URL và Asset)
  Widget _buildStoreListImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF25278),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.store, color: Colors.white, size: 24),
      );
    }
    // Tái sử dụng hàm build image chuẩn
    return _buildNailImage(imagePath, width: 50, height: 50);
  }

  bool _canShowContinueButton() {
    return _mainNailServices.isNotEmpty &&
        _selectedDay != null &&
        (selectedSlot != null || _selectedTime.isNotEmpty) &&
        _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _couponController.dispose();
    super.dispose();
  }
}