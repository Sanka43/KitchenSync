import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/realtime_service.dart';
import '../../services/usage_service.dart' as services_usage;
import '../auth/login_page.dart';
import 'edit_profile_page.dart';
import 'order_list_page.dart';
import 'items_list_page.dart';
import 'shop_list_page.dart';

class HotelDashboard extends StatefulWidget {
  const HotelDashboard({super.key});

  @override
  State<HotelDashboard> createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final RealtimeService _realtimeService = RealtimeService();
  final services_usage.UsageService _usageService =
      services_usage.UsageService();

  List<Map<String, dynamic>> _items = [];
  int _totalShops = 0;
  double _todayUsage = 0;
  String _hotelName = "Loading...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final shopQuery = await FirebaseFirestore.instance
          .collection('shops')
          .where('supplierId', isEqualTo: currentUserId)
          .get();

      if (shopQuery.docs.isEmpty) {
        setState(() {
          _hotelName = "No shop found";
          _totalShops = 0;
          _items = [];
          _isLoading = false;
        });
        return;
      }

      final shop = shopQuery.docs.first.data();
      final itemNames = List<String>.from(shop['items'] ?? []);

      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .get();
      final relevantItems = itemsSnapshot.docs
          .where((doc) => itemNames.contains(doc['itemName']))
          .map((doc) => doc.data())
          .toList();

      final usage = await _usageService.getTodayUsage(currentUserId);

      setState(() {
        _items = relevantItems;
        _totalShops = shopQuery.docs.length;
        _todayUsage = usage;
        _hotelName = shop['name'] ?? 'Unnamed Hotel';
        _isLoading = false;
      });

      await _usageService.saveTodayUsage(currentUserId, _todayUsage);
    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() {
        _hotelName = "Error loading data";
        _isLoading = false;
      });
    }
  }

  int get _lowStockCount => _items.where((item) {
    final stock = item['stock'];
    if (stock is int) return stock <= 10;
    if (stock is String) {
      final parsed = int.tryParse(stock);
      return parsed != null && parsed <= 10;
    }
    return false;
  }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('', style: GoogleFonts.poppins(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                  final itemWidth =
                      (constraints.maxWidth - (16.0 * (crossAxisCount - 1))) /
                      crossAxisCount;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(width: itemWidth, child: _buildSummaryCard()),
                      SizedBox(
                        width: itemWidth,
                        height: 300,
                        child: _buildStockChart(),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: 300,
                        child: _buildLowStockList(),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          Container(color: Colors.white.withOpacity(1)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: const Color.fromARGB(255, 245, 245, 245)),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.white.withOpacity(1)),
                accountName: Text(
                  _hotelName,
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 21, 22, 64),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  "Main Kitchen",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(230, 21, 22, 64),
                    fontSize: 14,
                  ),
                ),
                currentAccountPicture: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black12,
                    child: Icon(
                      Icons.person,
                      color: const Color.fromARGB(255, 21, 22, 64),
                      size: 40,
                    ),
                  ),
                ),
              ),
              _buildDrawerItem(Icons.list_alt, 'Order List', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderListPage()),
                );
              }),
              _buildDrawerItem(Icons.inventory, 'Items', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ItemsListPage()),
                );
              }),
              _buildDrawerItem(Icons.shopping_cart, 'Shops', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopListPage(hotelId: currentUserId),
                  ),
                );
              }),
              const Divider(thickness: 0.5),
              _buildDrawerItem(Icons.edit, 'Edit Profile', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              }),
              _buildDrawerItem(Icons.logout, 'Logout', () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 21, 22, 64)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color.fromARGB(255, 21, 22, 64),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Summary",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow("Total Items", _items.length.toString()),
            const Divider(),
            _buildSummaryRow("Low Stock Items", _lowStockCount.toString()),
            const Divider(),
            _buildSummaryRow("Total Shops", _totalShops.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16)),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLowStockList() {
    final lowStockItems = _items.where((item) {
      final stock = item['stock'];
      if (stock is int) return stock <= 10;
      if (stock is String) {
        final parsed = int.tryParse(stock);
        return parsed != null && parsed <= 10;
      }
      return false;
    }).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Low Stock Items",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: lowStockItems.length,
                itemBuilder: (context, index) {
                  final item = lowStockItems[index];
                  return ListTile(
                    title: Text(
                      item['itemName'] ?? 'Unnamed',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: Text(
                      item['stock'].toString(),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChart() {
    final chartItems = _items.take(5).toList();
    final barGroups = chartItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final stock = item['stock'] is int
          ? (item['stock'] as int).toDouble()
          : double.tryParse(item['stock'].toString()) ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(toY: stock, color: Colors.blueAccent)],
      );
    }).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Stock Chart",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          return Text(
                            index < chartItems.length
                                ? chartItems[index]['itemName'] ?? ''
                                : '',
                            style: GoogleFonts.poppins(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
