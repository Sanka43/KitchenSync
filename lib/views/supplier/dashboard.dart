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

  @override
  void initState() {
    super.initState();
    _fetchSummaryCounts();
  }

  Future<void> _fetchSummaryCounts() async {
    try {
      final shopsSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .get();
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .get();

      setState(() {
        totalShops = shopsSnapshot.docs.length;
        totalItems = itemsSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching counts: $e');
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
        iconTheme: const IconThemeData(color: Color(0xFF151640)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.shopName,
          style: GoogleFonts.poppins(
            color: const Color(0xFF151640),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.shopName}!',
              style: GoogleFonts.poppins(
                color: const Color(0xFF151640),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 32),
            Text(
              'Recent Activity (Coming Soon)',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF151640),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  'Charts, logs, or task summaries can go here.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(Icons.store, 'Total Shops', totalShops, Colors.blue),
        _buildStatCard(
          Icons.inventory,
          'Total Items',
          totalItems,
          Colors.green,
        ),
      ],
    );
  }

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
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
                  widget.shopName,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF151640),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                accountEmail: Text(
                  widget.shopContact,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF151640).withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(
                    Icons.store,
                    color: Colors.blueAccent,
                    size: 44,
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
