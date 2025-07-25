import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import 'create_shop_page.dart';
import 'product_list.dart';
import 'supplier_order_list_page.dart'; // Make sure to import this!
import '../../services/firestore_service.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  int totalShops = 0;
  int totalItems = 0;

  String shopName = 'Loading...';
  String shopEmail = 'Loading...';
  String? shopId;

  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchSummaryCounts();
    _loadShopInfo();
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

  Future<void> _loadShopInfo() async {
    final shopDocId = await firestoreService.getFirstShopIdForCurrentSupplier();

    if (shopDocId != null) {
      final shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopDocId)
          .get();

      if (shopDoc.exists) {
        final data = shopDoc.data();
        setState(() {
          shopName = data?['name'] ?? 'Unnamed Shop';
          shopEmail = data?['contact'] ?? 'No Contact';
          shopId = shopDocId;
        });
      } else {
        setState(() {
          shopName = 'Shop Not Found';
          shopEmail = '';
          shopId = null;
        });
      }
    } else {
      setState(() {
        shopName = 'No Shop Linked';
        shopEmail = '';
        shopId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Supplier Dashboard',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryCard(
              'Total Shops',
              totalShops,
              Icons.store,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              'Total Items',
              totalItems,
              Icons.inventory,
              Colors.green,
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Activity (Coming Soon)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Center(
                child: Text(
                  'Charts, logs, or task summaries can go here.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 28,
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18)),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
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
            accountName: Text(
              shopName,
              style: const TextStyle(color: Colors.white),
            ),
            accountEmail: Text(
              shopEmail,
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
          ),
          _buildDrawerItem(Icons.home, 'Shops', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateShopPage()),
            );
          }),
          _buildDrawerItem(Icons.shopping_cart, 'Orders', () {
            if (shopId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SupplierOrderListPage(shopId: shopId!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shop ID not found.')),
              );
            }
          }),
          _buildDrawerItem(Icons.shopping_bag, 'Items', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ItemList()),
            );
          }),
          _buildDrawerItem(Icons.logout, 'Logout', () async {
            await FirebaseAuth.instance.signOut();
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
