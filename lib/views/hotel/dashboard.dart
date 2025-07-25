import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/realtime_service.dart';
import '../../services/usage_service.dart' as services_usage;
import '../auth/login_page.dart';
import 'edit_profile_page.dart';
import 'add_order_page.dart';
import 'order_list_page.dart';
import 'items_list_page.dart';
import 'shop_list_page.dart';

class HotelDashboard extends StatefulWidget {
  const HotelDashboard({super.key});

  @override
  State<HotelDashboard> createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> {
  final RealtimeService _realtimeService = RealtimeService();
  final services_usage.UsageService _usageService =
      services_usage.UsageService();

  List<Map<String, dynamic>> _items = [];
  double _todayUsage = 0;

  List<FlSpot> _historySpots = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadHistoryData();
  }

  Future<void> _loadData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final items = await _realtimeService.fetchItems();
      final usage = await _usageService.getTodayUsage(userId);

      setState(() {
        _items = items;
        _todayUsage = usage;
      });

      await _usageService.saveTodayUsage(userId, _todayUsage);
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    }
  }

  Future<void> _loadHistoryData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('usage_history')
          .where('userId', isEqualTo: userId)
          .orderBy('date')
          .get();

      final spots = <FlSpot>[];
      int index = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        double usage = 0;
        if (data['usage'] is num) {
          usage = (data['usage'] as num).toDouble();
        }
        spots.add(FlSpot(index.toDouble(), usage));
        index++;
      }

      setState(() {
        _historySpots = spots;
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('Error loading history data: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  int get _lowStockCount => _items.where((item) {
    final quantity = item['quantity'];
    if (quantity is int) {
      return quantity <= 10;
    } else if (quantity is String) {
      return int.tryParse(quantity) != null && int.parse(quantity) <= 10;
    }
    return false;
  }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hotel Dashboard',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _loadData();
              _loadHistoryData();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildGlassCard(
                  child: _buildStatBox(
                    "Low Stock",
                    "$_lowStockCount",
                    icon: Icons.warning,
                  ),
                ),
                _buildGlassCard(
                  child: _buildStatBox(
                    "Today's Usage",
                    "${_todayUsage.toStringAsFixed(1)} kg",
                    icon: Icons.bar_chart,
                  ),
                ),
                _buildGlassCard(child: _buildHistory()),
                _buildGlassCard(
                  child: _buildPlaceholderChart("Low Stock Alerts"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Icon(icon, size: 36, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistory() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historySpots.isEmpty) {
      return const Center(child: Text('No history data available'));
    }

    final maxY =
        _historySpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Usage History",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 380,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: _historySpots.isNotEmpty
                  ? (_historySpots.length - 1).toDouble()
                  : 0,
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        'Day ${value.toInt() + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white60,
                        ),
                      );
                    },
                    interval: 1,
                    reservedSize: 30,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _historySpots,
                  isCurved: true,
                  color: Colors.lightBlueAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderChart(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          height: 100,
          width: double.infinity,
          alignment: Alignment.center,
          child: const Text(
            "Chart Placeholder",
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 24, 24, 24),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
            accountName: const Text(
              "Blue Ocean Hotel",
              style: TextStyle(color: Colors.white),
            ),
            accountEmail: const Text(
              "Main Kitchen",
              style: TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
          ),
          // _buildDrawerItem(Icons.add_shopping_cart, 'Add Order', () {
          //   Navigator.of(
          //     context,
          //   ).push(MaterialPageRoute(builder: (context) => AddOrderPage()));
          // }),
          _buildDrawerItem(Icons.list_alt, 'Order List', () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => OrderListPage()));
          }),
          _buildDrawerItem(Icons.inventory, 'Items', () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ItemsListPage()));
          }),
          _buildDrawerItem(Icons.shopping_cart, 'Shops', () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ShopListPage()));
          }),
          _buildDrawerItem(Icons.logout, 'Logout', () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
