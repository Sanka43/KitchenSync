import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class HotelDashboard extends StatefulWidget {
  final String hotelId;

  const HotelDashboard({super.key, required this.hotelId});

  @override
  State<HotelDashboard> createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> {
  int totalShops = 0;
  int totalItems = 0;
  int totalSuppliers = 0;

  List<DocumentSnapshot> pendingOrders = [];
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;
  final int perPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _fetchPendingOrders();
  }

  Future<void> _fetchCounts() async {
    try {
      final shopsSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('hotelId', isEqualTo: widget.hotelId)
          .get();

      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .get();

      final uniqueSuppliers = <String>{};
      for (var doc in shopsSnapshot.docs) {
        final supplierId = doc['supplierId'];
        if (supplierId != null) uniqueSuppliers.add(supplierId);
      }

      setState(() {
        totalShops = shopsSnapshot.size;
        totalItems = itemsSnapshot.size;
        totalSuppliers = uniqueSuppliers.length;
      });
    } catch (e) {
      // handle errors if necessary
      debugPrint('Error fetching counts: $e');
    }
  }

  Future<void> _fetchPendingOrders() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('orders')
          .where('hotelId', isEqualTo: widget.hotelId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(perPage);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }

      setState(() {
        pendingOrders.addAll(snapshot.docs);
        hasMore = snapshot.docs.length == perPage;
      });
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      pendingOrders.clear();
      lastDocument = null;
      hasMore = true;
    });
    await _fetchCounts();
    await _fetchPendingOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text(
          'Hotel Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Overview'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('Total Shops', totalShops, Colors.blue),
                  _buildStatCard('Total Items', totalItems, Colors.green),
                  _buildStatCard(
                    'Total Suppliers',
                    totalSuppliers,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel('Pending Orders'),
              const SizedBox(height: 12),
              _buildPendingOrdersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOrdersList() {
    if (pendingOrders.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (pendingOrders.isEmpty) {
      return Center(
        child: Text(
          'No pending orders',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !isLoading) {
            _fetchPendingOrders();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: pendingOrders.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < pendingOrders.length) {
              final order = pendingOrders[index];
              return _buildOrderListItem(
                order.id,
                order['shopId'] ?? 'Unknown Shop',
                _formatTimestamp(order['createdAt']),
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildOrderListItem(String id, String shopId, String date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        title: Text(
          'Order ID: $id',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Shop ID: $shopId\nDate: $date',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Invalid date';
    }
  }
}
