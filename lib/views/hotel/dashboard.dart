import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // Added
import 'package:google_fonts/google_fonts.dart';
import 'package:pie_chart/pie_chart.dart' as pie;

import '../../main.dart';
import '../auth/login_page.dart';
import 'edit_profile_page.dart';
import 'items_list_page.dart';
import 'order_list_page.dart';
import 'shop_list_page.dart';

// Define your HOTEL_Id constant here
const String HOTEL_Id = "5pj08bkQqhRZBv9oPzAuam2qidh2";

class HotelDashboard extends StatefulWidget {
  const HotelDashboard({super.key});

  @override
  State<HotelDashboard> createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> with RouteAware {
  bool isLoading = true;
  String hotelName = '';
  String? hotelId;
  String location = '';
  int itemCount = 0;
  int shopCount = 0;
  int pendingOrderCount = 0;

  List<Map<String, dynamic>> allStockItems = [];
  List<Map<String, dynamic>> lowStockItems = [];

  @override
  void initState() {
    super.initState();
    loadCounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    loadCounts();
  }

  Future<void> loadCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    hotelId = user.uid;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(hotelId)
          .get();
      hotelName = userDoc.data()?['username'] ?? '';
      location = userDoc.data()?['location'] ?? '';

      final itemsSnap = await FirebaseFirestore.instance
          .collection('items')
          .where('hotelId', isEqualTo: hotelId)
          .get();

      final shopsSnap = await FirebaseFirestore.instance
          .collection('shops')
          .where('location', isEqualTo: location)
          .get();

      allStockItems = itemsSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['itemName'] ?? 'Unnamed',
          'stock': data['stock'] ?? 0,
          'maxStock': data['maxStock'] ?? 0,
        };
      }).toList();

      lowStockItems = allStockItems.where((item) {
        final int stock = item['stock'] ?? 0;
        final int maxStock = item['maxStock'] ?? 1;
        return maxStock > 0 && stock < maxStock * 0.25;
      }).toList();

      await _fetchPendingOrders();

      setState(() {
        itemCount = itemsSnap.size;
        shopCount = shopsSnap.size;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading counts: $e');
    }
  }

  Future<void> _fetchPendingOrders() async {
    if (hotelId == null) return;

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .where('hotelId', isEqualTo: hotelId)
        .get();

    setState(() => pendingOrderCount = ordersSnapshot.docs.length);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF151640)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '',
          style: GoogleFonts.poppins(
            color: const Color(0xFF151640),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${hotelName.isNotEmpty ? hotelName : 'Guest'}!',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF151640),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const IotWeightsWidget(), // <-- Added here
                    const SizedBox(height: 24),
                    _buildStockLevelWidget(),
                    const SizedBox(height: 24),
                    _buildSummaryCards(),
                    const SizedBox(height: 32),
                    _buildLowStockWidget(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStockLevelWidget() {
    Map<String, double> dataMap = {};

    List<MapEntry<String, double>> percentageList = [];

    for (var item in allStockItems) {
      final String name = item['name'] ?? 'Unnamed';
      final int stock = item['stock'] ?? 0;
      final int maxStock = item['maxStock'] ?? 1;
      if (maxStock <= 0) continue;

      final double percentage = (stock / maxStock) * 100;
      percentageList.add(MapEntry(name, percentage));
    }

    // Sort and take lowest 5 stock percentages
    percentageList.sort((a, b) => a.value.compareTo(b.value));
    final limitedList = percentageList.take(5);

    for (var entry in limitedList) {
      dataMap[entry.key] = entry.value;
    }

    if (dataMap.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No item stock data available.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color.fromARGB(255, 37, 37, 37),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Level Overview (Lowest 5 Items)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151640),
            ),
          ),
          const SizedBox(height: 16),
          pie.PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 900),
            chartType: pie.ChartType.ring,
            chartRadius: MediaQuery.of(context).size.width / 2.5,
            ringStrokeWidth: 26,
            chartValuesOptions: const pie.ChartValuesOptions(
              showChartValuesInPercentage: true,
              showChartValues: true,
              decimalPlaces: 1,
              chartValueBackgroundColor: Colors.transparent,
              chartValueStyle: TextStyle(
                color: Color(0xFF151640),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            legendOptions: const pie.LegendOptions(
              showLegends: true,
              legendTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF151640),
              ),
              legendPosition: pie.LegendPosition.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Low Stock Items',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF151640),
          ),
        ),
        const SizedBox(height: 16),
        if (lowStockItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'No low stock items 🎉',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Column(
            children: lowStockItems.map((item) {
              final int stock = item['stock'] ?? 0;
              final int maxStock = item['maxStock'] ?? 1;
              final String percent = (maxStock > 0)
                  ? ((stock / maxStock) * 100).toStringAsFixed(1)
                  : '0.0';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'] ?? 'Unnamed',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF151640),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$percent%  ($stock/$maxStock)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red[800],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSummaryCards() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildStatCard(Icons.inventory_2, 'Items', itemCount, Colors.blue),
      _buildStatCard(
        Icons.pending_actions,
        'Pending Orders',
        pendingOrderCount,
        Colors.redAccent,
      ),
      _buildStatCard(Icons.store, 'Shops', shopCount, Colors.orangeAccent),
    ],
  );

  Widget _buildStatCard(IconData icon, String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center, // Center text alignment
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.white.withOpacity(0.85)),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                accountName: Text(
                  hotelName.isEmpty ? 'Loading...' : hotelName,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF151640),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                accountEmail: Text(
                  location.isEmpty ? '' : location,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF151640).withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                currentAccountPicture: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.person,
                      color: Colors.blueAccent,
                      size: 44,
                    ),
                  ),
                ),
              ),
              _drawerItem(Icons.list_alt, 'Order List', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderListPage()),
                );
              }),
              _drawerItem(Icons.inventory_2, 'Items', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemsListPage(hotelId: hotelId ?? ''),
                  ),
                );
              }),
              _drawerItem(Icons.store, 'Shops', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopListPage(hotelId: hotelId ?? ''),
                  ),
                );
              }),
              const Divider(thickness: 1, indent: 20, endIndent: 20),
              _drawerItem(Icons.edit, 'Edit Profile', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              }),
              _drawerItem(Icons.logout, 'Logout', _logout),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF151640)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFF151640),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      hoverColor: Colors.blue.shade50,
      onTap: onTap,
    );
  }
}

class IotWeightsWidget extends StatefulWidget {
  const IotWeightsWidget({Key? key}) : super(key: key);

  @override
  State<IotWeightsWidget> createState() => _IotWeightsWidgetState();
}

class _IotWeightsWidgetState extends State<IotWeightsWidget> {
  final DatabaseReference _weightsRef = FirebaseDatabase.instance
      .ref()
      .child('hotels')
      .child(HOTEL_Id)
      .child('weights');

  Map<String, dynamic> _weightsData = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listenToWeights();
  }

  void _listenToWeights() {
    _weightsRef.onValue.listen(
      (event) {
        final dataSnapshot = event.snapshot;
        print('RTDB onValue event fired');
        if (dataSnapshot.exists) {
          print('Data snapshot exists: ${dataSnapshot.value}');
          final data = Map<String, dynamic>.from(
            dataSnapshot.value as Map<dynamic, dynamic>,
          );
          setState(() {
            _weightsData = data;
            _loading = false;
            _error = null;
          });
        } else {
          print('Data snapshot does NOT exist');
          setState(() {
            _weightsData = {};
            _loading = false;
            _error = 'No data found';
          });
        }
      },
      onError: (error) {
        print('RTDB listener error: $error');
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      );
    }
    if (_weightsData.isEmpty) {
      return Center(
        child: Text('No weight data available', style: GoogleFonts.poppins()),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IoT Weight Data',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._weightsData.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatKey(key),
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    Text(
                      value.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}
