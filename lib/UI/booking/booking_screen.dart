// lib/UI/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:applamdep/UI/booking/your_appointment_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedTime = '';

  final List<String> morningTimes = ['09:00', '10:00', '11:00', '12:00'];
  final List<String> afternoonTimes = [
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00'
  ];

  List<ServiceItem> services = [
    ServiceItem(
      name: 'Milky White Pearl',
      price: 18,
      duration: '90 mins',
      imagePath: 'assets/images/nail1.png',
      quantity: 1,
    ),
    ServiceItem(
      name: 'Pastel Dream Garden',
      price: 23,
      duration: '60 mins',
      imagePath: 'assets/images/nail2.png',
      quantity: 0,
    ),
    ServiceItem(
      name: 'Galaxy Shimmer Night',
      price: 36,
      duration: '45 mins',
      imagePath: 'assets/images/nail3.png',
      quantity: 0,
    ),
  ];

  String note = '';
  final List<Branch> branches = [
    Branch(name: 'Nail Haven Studio', address: '25 Đặng Văn Ngữ, Phường Trung Tự, Quận Đống Đa, Hà Nội'),
    Branch(name: 'LumiNail Boutique', address: '72 Nguyễn Trãi, Phường Thượng Đình, Quận Thanh Xuân, Hà Nội'),
    Branch(name: 'Glow & Gloss Nails', address: '12 Trần Đại Nghĩa, Phường Bách Khoa, Quận Hai Bà Trưng, Hà Nội'),
    Branch(name: 'PinkAura Nail House', address: '145 Cầu Giấy, Phường Quan Hoa, Quận Cầu Giấy, Hà Nội'),
    Branch(name: 'CrystalLeaf Nail Art', address: '8 Lý Quốc Sư, Phường Hàng Trống, Quận Hoàn Kiếm, Hà Nội'),
  ];
  late Branch selectedBranch;


  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    selectedBranch = branches[0]; // Chi nhánh mặc định
  }

  double get totalPrice {
    return services.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get totalServices {
    return services.fold(0, (sum, item) => sum + item.quantity);
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
          'Booking an Appointment',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Select Branch',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                        const Icon(Icons.location_on_outlined, color: Colors.pink),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedBranch.name,
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${_focusedDay.month}/${_focusedDay.year}',
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                          color: Color(0xFFFFE4E8), shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(
                          color: Color(0xFFF25278), shape: BoxShape.circle),
                      todayTextStyle: TextStyle(
                          color: Color(0xFFF25278), fontWeight: FontWeight.bold),
                      selectedTextStyle: TextStyle(color: Colors.white),
                      disabledTextStyle: TextStyle(color: Colors.grey),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                      weekendStyle: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Morning',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                  morningTimes.map((time) => _buildTimeChip(time)).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Afternoon',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: afternoonTimes
                      .map((time) => _buildTimeChip(time))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('You can book up to 3 seats',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Select service',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    if (service.quantity == 0) return const SizedBox.shrink();
                    return _buildServiceItem(service, index);
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
                        '+ Add service',
                        style: TextStyle(
                            color: Color(0xFFF25278),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionRow('Voucher', Icons.local_offer_outlined),
                const SizedBox(height: 16),
                _buildSectionRow('Payment', Icons.payment, subtitle: 'Visa'),
                const SizedBox(height: 24),
                const Text('Note',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => note = value,
                  decoration: InputDecoration(
                    hintText: 'Message to the store...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total ($totalServices service${totalServices > 1 ? 's' : ''})',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF25278)),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          if (totalServices > 0 &&
              _selectedDay != null &&
              _selectedTime.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 30,
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Booking confirmed! (Demo)')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF25278),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
                'Chọn chi nhánh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    final isSelected = selectedBranch.name == branch.name;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: isSelected ? 6 : 2,
                      color: isSelected ? const Color(0xFFFFF5F7) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: isSelected ? const Color(0xFFF25278) : Colors.pink,
                          size: 32,
                        ),
                        title: Text(
                          branch.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          branch.address,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFFF25278), size: 28)
                            : null,
                        onTap: () {
                          setState(() {
                            selectedBranch = branch;
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
            child: Image.asset(
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
                Text(service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('\$${service.price} • ${service.duration}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
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
              Text('${service.quantity}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFFF25278)),
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

  Widget _buildSectionRow(String title, IconData icon, {String? subtitle}) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16)),
          if (subtitle != null)
            Text(' > $subtitle',
                style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.grey),
        ],
      ),
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
          const Text('Add more service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(service.imagePath,
                        width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  title: Text(service.name),
                  subtitle:
                  Text('\$${service.price} • ${service.duration}'),
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
                        icon: const Icon(Icons.add,
                            color: Color(0xFFF25278)),
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
                    child: const Text('Add'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceItem {
  String name;
  double price;
  String duration;
  String imagePath;
  int quantity;

  ServiceItem({
    required this.name,
    required this.price,
    required this.duration,
    required this.imagePath,
    required this.quantity,
  });
}
class Branch {
  final String name;
  final String address;
  Branch({required this.name, required this.address});
}