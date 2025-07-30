import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/login_page.dart';
import 'edit_profile_page.dart';
import 'items_list_page.dart';
import 'order_list_page.dart';
import 'shop_list_page.dart';

class HotelDashboard extends StatefulWidget {
  const HotelDashboard({super.key});

  @override
  State<HotelDashboard> createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> {
  String? hotelId;
  String hotelName = '';
  String location = '';
  int itemCount = 0;
  int shopCount = 0;
  int pendingOrderCount = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> lowStockItems = [];

  @override
  void initState() {
    super.initState();
    loadCounts();
    _fetchPendingOrders();
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

      // Calculate low stock items
      lowStockItems = itemsSnap.docs
          .where((doc) {
            final data = doc.data();
            final int stock = data['stock'] ?? 0;
            final int maxStock = data['maxStock'] ?? 1;
            return maxStock > 0 && stock < maxStock * 0.25;
          })
          .map((doc) {
            final data = doc.data();
            return {
              'name': data['itemName'] ?? 'Unnamed',
              'stock': data['stock'] ?? 0,
              'maxStock': data['maxStock'] ?? 0,
            };
          })
          .toList();

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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCards(),
                  const SizedBox(height: 16),
                  _buildLowStockWidget(),
                ],
              ),
            ),
    );
  }

  Widget _buildLowStockWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Low Stock Items',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 12),
        if (lowStockItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'No low stock items 🎉',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          ...lowStockItems.map((item) {
            final int stock = item['stock'] ?? 0;
            final int maxStock = item['maxStock'] ?? 1;
            final String percent = (maxStock > 0)
                ? ((stock / maxStock) * 100).toStringAsFixed(1)
                : '0.0';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
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
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    ' $percent%  ($stock/$maxStock)',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.red[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSummaryCards() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildStatCard('Items', itemCount, Colors.blue),
      _buildStatCard('Pending Orders', pendingOrderCount, Colors.red),
      _buildStatCard('Shops', shopCount, Colors.orange),
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
                  hotelName.isEmpty ? 'Loading...' : hotelName,
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 21, 22, 64),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  location.isEmpty ? '' : location,
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
                      color: Color.fromARGB(255, 21, 22, 64),
                      size: 40,
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
              _drawerItem(Icons.inventory, 'Items', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemsListPage(hotelId: hotelId ?? ''),
                  ),
                );
              }),
              _drawerItem(Icons.shopping_cart, 'Shops', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopListPage(hotelId: hotelId ?? ''),
                  ),
                );
              }),
              const Divider(thickness: 0.5),
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
}
