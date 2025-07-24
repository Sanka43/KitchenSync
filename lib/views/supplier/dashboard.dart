import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import 'create_shop_page.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  int totalShops = 0;
  int totalItems = 0;

  String shopName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchSummaryCounts();
    _loadShopName();
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

  Future<void> _loadShopName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        shopName = 'No User Signed In';
      });
      return;
    }

    final shopsSnapshot = await FirebaseFirestore.instance
        .collection('shops')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (shopsSnapshot.docs.isNotEmpty) {
      setState(() {
        shopName = shopsSnapshot.docs.first['name'] ?? 'Unnamed Shop';
      });
    } else {
      setState(() {
        shopName = 'No Shop Found';
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
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh, color: Colors.black),
        //     onPressed: () {
        //       // _loadData();
        //       // _loadHistoryData();
        //     },
        //   ),
        // ],
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
            accountName: const Text(
              "Blue Ocean Hotel",
              style: TextStyle(color: Colors.white),
            ),
            accountEmail: const Text(
              "Main Kitchen",
              style: TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: GestureDetector(
              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (_) => const EditProfilePage()),
              //   );
              // },
              child: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
          ),
          _buildDrawerItem(Icons.home, 'Shops', () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => CreateShopPage()));
          }),
          // _buildDrawerItem(Icons.list_alt, 'Order List', () {
          //   Navigator.of(
          //     context,
          //   ).push(MaterialPageRoute(builder: (context) => OrderListPage()));
          // }),
          // _buildDrawerItem(Icons.inventory, 'Items', () {
          //   Navigator.of(
          //     context,
          //   ).push(MaterialPageRoute(builder: (_) => const ItemsListPage()));
          // }),
          // _buildDrawerItem(Icons.shopping_cart, 'Shops', () {
          //   Navigator.of(
          //     context,
          //   ).push(MaterialPageRoute(builder: (_) => const ShopListPage()));
          // }),
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
