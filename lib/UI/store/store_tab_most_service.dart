import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../models/service_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'service_details.dart';

class MostServiceTab extends StatefulWidget {
  final Store store;
  const MostServiceTab({super.key, required this.store});

  @override
  State<MostServiceTab> createState() => _MostServiceTabState();
}

class _MostServiceTabState extends State<MostServiceTab> {
  // --- STATE MANAGEMENT ---
  bool _isSearching = false; // Trạng thái co giãn của thanh tìm kiếm
  String _searchQuery = ""; // Nội dung tìm kiếm hiện tại
  final TextEditingController _searchController = TextEditingController();

  /// Hàm điều hướng và thông báo (Giữ nguyên logic của bạn)
  void _navigateToDetail(BuildContext context, Service service, {bool showMessage = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(service: service, store: widget.store),
      ),
    );

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a design to book an appointment"),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // LOGIC TÌM KIẾM: Lọc danh sách dịch vụ theo tên
    final filteredServices = widget.store.services
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        // --- PHẦN 1: THANH TÌM KIẾM CO GIÃN (EXPANDABLE SEARCH) ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipRect(  // Clip để cắt overflow nếu còn
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isSearching ? constraints.maxWidth : 48,  // Tăng width khi collapse để icon vừa
                    height: 48,  // Tăng height từ 44 → 48 để chừa space padding/border
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(_isSearching ? 12 : 24),  // Làm tròn hơn khi collapse
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: SingleChildScrollView(  // Thêm scroll horizontal nếu text dài overflow
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          IconButton(
                            padding: const EdgeInsets.all(12),  // Padding đều để icon giữa
                            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded,
                                color: AppColors.primary, size: 20),
                            onPressed: () {
                              setState(() {
                                _isSearching = !_isSearching;
                                if (!_isSearching) {
                                  _searchController.clear();
                                  _searchQuery = "";
                                }
                              });
                            },
                          ),
                          if (_isSearching)
                            SizedBox(
                              width: constraints.maxWidth - 60,  // Giới hạn width TextField để tránh overflow
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: AppTypography.textSM,
                                decoration: const InputDecoration(
                                  hintText: "Search services...",
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 4),  // Giảm padding horizontal
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),

        // --- DANH SÁCH DỊCH VỤ ---
        Expanded(
          child: filteredServices.isEmpty
              ? const Center(child: Text("No services found."))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredServices.length,
            itemBuilder: (context, index) => _buildCompactServiceCard(context, filteredServices[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactServiceCard(BuildContext context, Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // FIX CẢNH BÁO DEPRECATED: Dùng .withValues
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(context, service),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 85,
                  height: 85,
                  child: _buildSmartImage(service.imageUrl ?? ''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(service.name, style: AppTypography.textSM.copyWith(fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text("\$${service.price}", style: AppTypography.textSM.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("${service.duration} mins", style: AppTypography.textXS.copyWith(color: Colors.grey[600])),
                        const Spacer(),
                        _buildBookButton(context, service),
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

  Widget _buildBookButton(BuildContext context, Service service) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: () => _navigateToDetail(context, service, showMessage: true),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text("Book", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildSmartImage(String path) {
    if (path.isEmpty) return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image));
    if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover);
    return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)));
  }
}