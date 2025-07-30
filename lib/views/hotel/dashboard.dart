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
  int itemCount = 0;
  int shopCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCounts();
  }

  Future<void> loadCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    hotelId = user.uid;

    try {
      final itemsSnap = await FirebaseFirestore.instance
          .collection('items')
          .where('hotelId', isEqualTo: hotelId)
          .get();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(hotelId)
          .get();

      final location = userDoc.data()?['location'];

      final shopsSnap = await FirebaseFirestore.instance
          .collection('shops')
          .where('location', isEqualTo: location)
          .get();

      setState(() {
        itemCount = itemsSnap.size;
        shopCount = shopsSnap.size;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading counts: $e');
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
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Center(
                  child: Text(
                    'Hotel Dashboard',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildDrawerItem(Icons.list_alt, 'Orders', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderListPage()),
                );
              }),
              _buildDrawerItem(Icons.inventory, 'Items', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemsListPage(hotelId: hotelId ?? ''),
                  ),
                );
              }),
              _buildDrawerItem(Icons.store, 'Shops', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopListPage(hotelId: hotelId ?? ''),
                  ),
                );
              }),
              _buildDrawerItem(Icons.person, 'Edit Profile', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              }),
              _buildDrawerItem(Icons.logout, 'Logout', _logout),
            ],
          ),
        ),
      ),
      // drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Hotel Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF1F3F6),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard('Total Items', itemCount, Icons.inventory),
                  _buildStatCard('Nearby Shops', shopCount, Icons.store),
                  const SizedBox(height: 16),
                  // Add more summary cards here if needed
                ],
              ),
            ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: GoogleFonts.poppins(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$title: $count',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
