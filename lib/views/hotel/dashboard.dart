import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HotelDashboard extends StatefulWidget {
  const HotelDashboard({super.key});

  @override
  State<HotelDashboard> createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> {
  String hotelName = '';
  String location = '';
  String contactNumber = '';
  bool isLoading = true;

  int itemCount = 0;
  int shopCount = 0;
  int pendingOrderCount = 0;
  List<Map<String, dynamic>> lowStockItems = [];
  List<Map<String, dynamic>> realtimeStockItems = [];
  bool isRealtimeLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHotelData();
    _fetchCounts();
    _fetchPendingOrders();
    _fetchLowStockItems();
    _fetchRealtimeStockData();
  }

  Future<void> _fetchHotelData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('hotels')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      hotelName = data['hotelName'] ?? '';
      location = data['location'] ?? '';
      contactNumber = data['contactNumber'] ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> _fetchCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final itemSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('hotelId', isEqualTo: uid)
        .get();
    final shopSnapshot = await FirebaseFirestore.instance
        .collection('shops')
        .where('hotelId', isEqualTo: uid)
        .get();

    setState(() {
      itemCount = itemSnapshot.docs.length;
      shopCount = shopSnapshot.docs.length;
    });
  }

  Future<void> _fetchPendingOrders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .where('hotelId', isEqualTo: uid)
        .get();

    setState(() => pendingOrderCount = ordersSnapshot.docs.length);
  }

  Future<void> _fetchLowStockItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('hotelId', isEqualTo: uid)
        .get();
    final lowItems = itemsSnapshot.docs
        .where((doc) {
          final data = doc.data();
          final stock = data['stock'] ?? 0;
          final maxStock = data['maxStock'] ?? 1;
          return (stock / maxStock) < 0.25;
        })
        .map((doc) => doc.data())
        .toList();

    setState(() => lowStockItems = List<Map<String, dynamic>>.from(lowItems));
  }

  Future<void> _fetchRealtimeStockData() async {
    setState(() => isRealtimeLoading = true);
    try {
      final dbRef = FirebaseDatabase.instance.ref('stockItems');
      final snapshot = await dbRef.limitToFirst(5).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final items = data.entries.map((e) {
          final value = Map<String, dynamic>.from(e.value);
          return {
            'itemName': e.key.toString(),
            'stock': value['stock'] ?? 0,
            'maxStock': value['maxStock'] ?? 1,
          };
        }).toList();

        setState(() => realtimeStockItems = items);
      }
    } catch (e) {
      debugPrint('Error fetching Realtime DB stock: $e');
    } finally {
      setState(() => isRealtimeLoading = false);
    }
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
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Hotel Info'),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildLabel('Summary'),
                  const SizedBox(height: 12),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildLabel('Low Stock Alerts'),
                  const SizedBox(height: 12),
                  _buildLowStockCard(),
                  const SizedBox(height: 24),
                  _buildLabel('Live Stock (RTDB)'),
                  const SizedBox(height: 12),
                  _buildRealtimeStockCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );

  Widget _buildInfoCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 0, 0, 0),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(31, 255, 255, 255),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Name', hotelName),
        _buildInfoRow('Location', location),
        _buildInfoRow('Contact', contactNumber),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(value, style: GoogleFonts.poppins(fontSize: 14)),
      ],
    ),
  );

  Widget _buildSummaryCards() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildStatCard('Items', itemCount, Colors.blue),
      _buildStatCard('Shops', shopCount, Colors.orange),
      _buildStatCard('Pending Orders', pendingOrderCount, Colors.red),
    ],
  );

  Widget _buildStatCard(String label, int count, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLowStockCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 255, 255, 255),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items below 25% stock:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ...lowStockItems.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['itemName'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${item['stock']} / ${item['maxStock']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildRealtimeStockCard() {
    if (isRealtimeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (realtimeStockItems.isEmpty) {
      return Text(
        'No real-time stock data found.',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Real-time Stock Items:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: realtimeStockItems.length,
            itemBuilder: (context, index) {
              final item = realtimeStockItems[index];
              final name = item['itemName'];
              final stock = item['stock'];
              final max = item['maxStock'];
              final percentage = ((stock / max) * 100).toStringAsFixed(0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontSize: 14)),
                    Text(
                      '$stock / $max ($percentage%)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
