// lib/UI/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedTime = '16:00';

  final List<String> morningTimes = ['09:00', '10:00', '11:00', '12:00'];
  final List<String> afternoonTimes = [
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
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
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // SELECT BRANCH
            const Text('Select Branch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.pink),
                  SizedBox(width: 12),
                  Text('Honey Salon 1', style: TextStyle(fontSize: 16)),
                  Spacer(),
                  Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CALENDAR
            const Text('July 2025', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
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
                  todayDecoration: BoxDecoration(color: Color(0xFFFFE4E8), shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Color(0xFFF25278), shape: BoxShape.circle),
                  todayTextStyle: TextStyle(color: Color(0xFFF25278), fontWeight: FontWeight.bold),
                  selectedTextStyle: TextStyle(color: Colors.white),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                  weekendStyle: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // TIME SLOTS - MORNING
            const Text('Morning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: morningTimes.map((time) => _buildTimeChip(time)).toList(),
            ),

            const SizedBox(height: 20),
            const Text('Afternoon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                Text('You can book up to 3 seats', style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 24),

            // SELECT SERVICE
            const Text('Select service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://i.imgur.com/vP9kR2m.jpeg',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hot Style A.01', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('₫350.000 • 90 mins', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_circle_outline, color: Color(0xFFF25278), size: 28),
                ],
              ),
            ),

            const SizedBox(height: 120), // Đảm bảo không bị bottom nav che
          ],
        ),
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
}