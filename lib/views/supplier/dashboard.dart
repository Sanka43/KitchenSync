import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/login_page.dart';
import 'create_shop_page.dart';
import 'product_list.dart';
import 'supplier_order_list_page.dart';

class SupplierDashboard extends StatefulWidget {
  final String shopId;
  final String shopName;
  final String shopContact;

  const SupplierDashboard({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.shopContact,
  });

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  int totalShops = 0;
  int totalItems = 0;
  int receivedOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummaryCounts();
  }

  Future<void> _fetchSummaryCounts() async {
    try {
      final supplierId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch shops with supplierId == current user
      final shopsSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('supplierId', isEqualTo: supplierId)
          .get();

      int itemCount = 0;

      for (var doc in shopsSnapshot.docs) {
        final data = doc.data();
        final items = data['items'];
        if (items is List) {
          itemCount += items.length;
        }
      }

      // Fetch orders for this specific shop
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('shopId', isEqualTo: widget.shopId)
          .get();

      setState(() {
        totalShops = shopsSnapshot.docs.length;
        totalItems = itemCount;
        receivedOrders = ordersSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching summary counts: $e');
    }
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.shopName,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF151640),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Where Quality Meets Every Meal!',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            _buildSummaryWidgets(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryWidgets() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryCard('Total Shops', totalShops, Icons.store, Colors.orange),
        _summaryCard('Total Items', totalItems, Icons.inventory, Colors.teal),
        _summaryCard(
          'Orders',
          receivedOrders,
          Icons.shopping_cart,
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _summaryCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF151640),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
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
                  widget.shopName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF151640),
                  ),
                ),
                accountEmail: Text(
                  widget.shopContact,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF151640).withOpacity(0.8),
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(
                    Icons.store,
                    size: 44,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              _drawerItem(Icons.home, 'Create Shop', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateShopPage()),
                );
              }),
              _drawerItem(Icons.shopping_cart, 'Orders', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SupplierOrderListPage(shopId: widget.shopId),
                  ),
                );
              }),
              _drawerItem(Icons.inventory, 'Items', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemList(shopId: widget.shopId),
                  ),
                );
              }),
              const Divider(thickness: 1, indent: 20, endIndent: 20),
              _drawerItem(Icons.logout, 'Logout', _logout),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF151640)),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF151640),
        ),
      ),
      hoverColor: Colors.blue.shade50,
      onTap: onTap,
    );
  }
}
