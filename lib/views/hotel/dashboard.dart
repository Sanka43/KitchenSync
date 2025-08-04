import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pie_chart/pie_chart.dart' as pie;
import 'package:fl_chart/fl_chart.dart';

import '../../main.dart';
import '../auth/login_page.dart';
import 'edit_profile_page.dart';
import 'items_list_page.dart';
import 'order_list_page.dart';
import 'shop_list_page.dart';
import 'report_page.dart'; // adjust the path as needed

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
  Map<String, double> weightsData = {};

  late DatabaseReference weightsRef;
  StreamSubscription<DatabaseEvent>? weightsSubscription;

  final Map<String, double> maxScales = {
    'chili_powder': 1,
    'corn_flour': 10,
    'rice': 20,
    'sugar': 10,
    'oil_liter': 4,
  };

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
    weightsSubscription?.cancel();
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
      final hotelSnap = await FirebaseFirestore.instance
          .collection('hotels')
          .where('uid', isEqualTo: hotelId)
          .limit(1)
          .get();

      if (hotelSnap.docs.isEmpty) return;

      final hotelData = hotelSnap.docs.first.data();
      hotelName = hotelData['hotelName'] ?? '';
      location = hotelData['location'] ?? '';
      final rtdbHotelId = hotelData['hotelId'] ?? '';

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

      weightsRef = FirebaseDatabase.instance.ref('hotels/$rtdbHotelId/weights');
      weightsSubscription = weightsRef.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        final Map<String, double> parsed = {
          'chili_powder': 0,
          'corn_flour': 0,
          'rice': 0,
          'sugar': 0,
          'oil_liter': 0,
        };

        if (data != null) {
          data.forEach((key, value) {
            final normalizedKey = key.toString().toLowerCase().replaceAll(
              ' ',
              '_',
            );
            switch (normalizedKey) {
              case 'chili_powder':
              case 'corn_flour':
              case 'rice':
              case 'sugar':
              case 'oil_liter':
                parsed[normalizedKey] = double.tryParse(value.toString()) ?? 0;
                break;
              default:
                break;
            }
          });
        }

        setState(() {
          weightsData = parsed;
        });
      });

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
                      '${hotelName.isNotEmpty ? hotelName : 'Guest'}!',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF151640),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          'Stock Level Overview ',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF151640),
                          ),
                        ),
                        Icon(
                          Icons.arrow_downward,
                          size: 20,
                          color: const Color.fromARGB(255, 143, 20, 20),
                        ),
                      ],
                    ),
                    _buildStockLevelWidget(),
                    Text(
                      'RTDB Weights',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF151640),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildBarChart(weightsData, maxScales),
                    const SizedBox(height: 24),
                    Text(
                      'Low Stock Items',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF151640),
                      ),
                    ),
                    _buildLowStockWidget(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBarChart(
    Map<String, double> weightsData,
    Map<String, double> maxScales,
  ) {
    return AnimatedLowBarChart(weightsData: weightsData, maxScales: maxScales);
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
                fontWeight: FontWeight.w400,
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
              _drawerItem(Icons.picture_as_pdf, 'Generate Report', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportPage()),
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

class AnimatedLowBarChart extends StatefulWidget {
  final Map<String, double> weightsData;
  final Map<String, double> maxScales;

  const AnimatedLowBarChart({
    Key? key,
    required this.weightsData,
    required this.maxScales,
  }) : super(key: key);

  @override
  State<AnimatedLowBarChart> createState() => _AnimatedLowBarChartState();
}

class _AnimatedLowBarChartState extends State<AnimatedLowBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const double pulseMin = 0.9; // 90% scale
  static const double pulseMax = 1.0; // 100% scale

  final Map<String, Color> colors = {
    'Chill_Powder': Colors.redAccent,
    'Corn_Flour': Colors.orangeAccent,
    'Rice': Colors.green,
    'Suger': Colors.purple,
    'oil_liter': Colors.blueAccent,
  };

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // duration of one pulse cycle
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: pulseMin,
      end: pulseMax,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose(); // always dispose controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataToShow = widget.weightsData.isNotEmpty
        ? widget.weightsData
        : {
            'Chill_Powder': 0,
            'Corn_Flour': 0,
            'Rice': 0,
            'Suger': 0,
            'oil_liter': 0,
          };

    final Map<String, double> percentages = {};
    dataToShow.forEach((key, value) {
      final max = widget.maxScales[key] ?? 1;
      final pct = ((value / max) * 100).clamp(0, 100).toDouble();
      percentages[key] = pct;
    });

    final keys = percentages.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth;
                final chartHeight = constraints.maxHeight;
                final barWidth = 24.0;
                final spacing = chartWidth / keys.length;

                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        BarChart(
                          BarChartData(
                            maxY: 110,
                            barTouchData: BarTouchData(enabled: false),
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index < 0 || index >= keys.length)
                                      return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Transform.rotate(
                                        angle: -0.6,
                                        child: Text(
                                          keys[index],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(keys.length, (index) {
                              final key = keys[index];
                              final pct = percentages[key]!;
                              final color = colors[key] ?? Colors.blue;

                              final animatedHeight = pct < 25
                                  ? pct * _animation.value
                                  : pct;

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: animatedHeight,
                                    color: color,
                                    width: barWidth,
                                    borderRadius: BorderRadius.circular(12),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: false,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                        // Percentage labels above bars
                        ...List.generate(keys.length, (index) {
                          final pct = percentages[keys[index]]!;
                          final dx =
                              spacing * index + spacing / 2 - barWidth / 2;
                          final animatedPct = pct < 25
                              ? pct * _animation.value
                              : pct;
                          final dy = ((1 - (animatedPct / 110)) * chartHeight)
                              .clamp(12.0, chartHeight - 30);

                          return Positioned(
                            left: dx,
                            top: dy - 20,
                            child: Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
