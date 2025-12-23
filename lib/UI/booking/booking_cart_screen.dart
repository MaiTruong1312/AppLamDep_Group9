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

  // Temporary storage for UI
  Map<String, List<BookingCartItem>>? _groupedByStore;
  int _storeCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Booking List'),
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
                tooltip: 'Clear All',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with details
          _buildHeader(),

          // Multi-store warning (if any)
          StreamBuilder<List<BookingCartItem>>(
            stream: _bookingCartService.getBookingCartItems(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final items = snapshot.data!;
                final grouped = _groupItemsByStore(items);
                final storeCount = grouped.length;

                if (storeCount > 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _storeCount = storeCount;
                    _groupedByStore = grouped;
                  });

                  return _buildMultiStoreWarning(storeCount);
                }
              }
              return const SizedBox();
            },
          ),

          // Nail design list
          Expanded(
            child: _buildNailList(),
          ),

          // Continue button
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: StreamBuilder<List<BookingCartItem>>(
        stream: _bookingCartService.getBookingCartItems(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final items = snapshot.data!;
            final count = items.length;

            if (count > 0) {
              final grouped = _groupItemsByStore(items);
              final storeCount = grouped.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                              'Selected Nail Designs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              '$count designs from $storeCount stores',
                              style: TextStyle(
                                fontSize: 14,
                                color: storeCount > 1 ? Colors.orange : Colors.grey,
                                fontWeight: storeCount > 1 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: storeCount > 1 ? Colors.orange : const Color(0xFFF25278),
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
                  ),
                  if (storeCount > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Each store only does their own designs. Please book each store separately.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }
          }

          // Default header when there is no data or it's loading
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
                      'Selected Nail Designs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '0 designs',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMultiStoreWarning(int storeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecting from $storeCount stores',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  'Each store needs to be booked separately',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showStoreGroupingDialog,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
            ),
            child: Text(
              'View Details',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange[800],
              ),
            ),
          ),
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
              'An error occurred: ${snapshot.error}',
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

        // Group items by store to display
        final groupedItems = _groupItemsByStore(items);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groupedItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final storeId = groupedItems.keys.elementAt(index);
            final storeItems = groupedItems[storeId]!;
            final storeName = storeItems.first.storeName;

            return _buildStoreSection(storeId, storeName, storeItems);
          },
        );
      },
    );
  }

  Widget _buildStoreSection(String storeId, String storeName, List<BookingCartItem> items) {
    final totalPrice = items.fold(0.0, (sum, item) => sum + item.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.store, color: Color(0xFFF25278), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${items.length} designs',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFF25278),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Store items
        Column(
          children: items.map((item) => _buildNailCard(item)).toList(),
        ),

        // Store summary
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => _proceedWithStore(storeId, items),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF25278),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 16),
                    SizedBox(width: 6),
                    Text('Book this store'),
                  ],
                ),
              ),
              Text(
                _currencyFormat.format(totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25278),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNailCard(BookingCartItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
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
              // Display local asset image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: _buildNailImage(item.nailImage),
                ),
              ),
              const SizedBox(width: 12),

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
                    Row(
                      children: [
                        const Icon(Icons.store, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.storeName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

// Only use Image.asset for local assets
  Widget _buildNailImage(String imagePath) {
    // Check if the path is valid
    if (imagePath.isEmpty || !imagePath.startsWith('assets/')) {
      return _buildErrorImage();
    }

    try {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading asset: $imagePath - $error');
          return _buildErrorImage();
        },
      );
    } catch (e) {
      print('❌ Exception loading asset $imagePath: $e');
      return _buildErrorImage();
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Icon(
          Icons.photo,
          color: Colors.grey,
          size: 40,
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
      child: StreamBuilder<List<BookingCartItem>>(
        stream: _bookingCartService.getBookingCartItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox();
          }

          final items = snapshot.data!;
          final grouped = _groupItemsByStore(items);
          final storeCount = grouped.length;
          final totalCount = items.length;

          return Column(
            children: [
              if (storeCount > 1) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showStoreGroupingDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store_mall_directory, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'VIEW $storeCount STORES ($totalCount DESIGNS)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Primary action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleProceedToBooking(items, grouped),
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
                        storeCount == 1
                            ? 'BOOK NOW ($totalCount DESIGNS)'
                            : 'MANAGE BOOKINGS',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
            'No nail designs yet',
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
              'Choose your favorite nail designs and add them to the booking list',
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
                Text('BACK TO SELECT DESIGNS'),
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
          title: const Text('Delete nail design'),
          content: Text('Are you sure you want to remove "${item.nailName}" from the booking list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                _bookingCartService.removeFromBookingCart(item.nailId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${item.nailName}"'),
                    backgroundColor: const Color(0xFFF25278),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog() async {
    final items = await _bookingCartService.getBookingCartItems().first;
    if (items.isEmpty) return;

    final count = items.length;
    final grouped = _groupItemsByStore(items);
    final storeCount = grouped.length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete all $count nail designs?'),
              if (storeCount > 1) ...[
                const SizedBox(height: 8),
                Text(
                  '($storeCount stores will be removed)',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearAllItems();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('DELETE ALL'),
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
            content: Text('All nail designs have been deleted'),
            backgroundColor: Color(0xFFF25278),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleProceedToBooking(
      List<BookingCartItem> items,
      Map<String, List<BookingCartItem>> groupedItems
      ) {
    final storeCount = groupedItems.length;

    if (storeCount == 1) {
      // If there is only 1 store, book immediately
      _proceedWithStore(groupedItems.keys.first, items);
    } else {
      // If there are multiple stores, show a selection dialog
      _showStoreGroupingDialog();
    }
  }

  void _showStoreGroupingDialog() async {
    final items = await _bookingCartService.getBookingCartItems().first;
    if (items.isEmpty) return;

    final groupedItems = _groupItemsByStore(items);
    final storeCount = groupedItems.length;

    if (storeCount == 1) {
      _proceedWithStore(groupedItems.keys.first, items);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Booking for multiple stores'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You are selecting designs from multiple stores. Each store needs a separate booking:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                ...groupedItems.entries.map((entry) {
                  final storeId = entry.key;
                  final storeItems = entry.value;
                  final storeName = storeItems.first.storeName;
                  final itemCount = storeItems.length;
                  final totalPrice = storeItems.fold(0.0, (sum, item) => sum + item.price);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store, color: Color(0xFFF25278), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      storeName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '$itemCount designs • ${_currencyFormat.format(totalPrice)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _keepOnlyThisStore(storeId);
                                  _proceedWithStore(storeId, storeItems);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                ),
                                child: const Text('Keep this store only'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _proceedWithStore(storeId, storeItems);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF25278),
                                ),
                                child: const Text('Book'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Note: You can book for each store one by one',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _proceedWithStore(String storeId, List<BookingCartItem> storeItems) async {
    try {
      final firstItem = storeItems.first;

      // Load full store information from Firestore
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      Store store;
      if (storeDoc.exists) {
        store = Store.fromFirestore(storeDoc);
      } else {
        // Fallback if store is not found
        store = Store(
          id: storeId,
          name: firstItem.storeName,
          address: '',
          hotline: '',
          isOpen: true,
          imgUrl: '',
          location: const GeoPoint(0, 0),
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(
            selectedNail: _convertToNail(firstItem),
            selectedStore: store,
            bookingCartItems: storeItems,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {});
        }
      });

    } catch (e) {
      print('Error proceeding with store: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _keepOnlyThisStore(String storeIdToKeep) async {
    try {
      final allItems = await _bookingCartService.getBookingCartItems().first;
      final itemsToRemove = allItems.where((item) => item.storeId != storeIdToKeep);

      for (var item in itemsToRemove) {
        await _bookingCartService.removeFromBookingCart(item.nailId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kept the designs from this store'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error keeping only one store: $e');
    }
  }

  Map<String, List<BookingCartItem>> _groupItemsByStore(List<BookingCartItem> items) {
    final Map<String, List<BookingCartItem>> grouped = {};

    for (var item in items) {
      if (!grouped.containsKey(item.storeId)) {
        grouped[item.storeId] = [];
      }
      grouped[item.storeId]!.add(item);
    }

    return grouped;
  }

  // Helper method to convert BookingCartItem to Nail
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