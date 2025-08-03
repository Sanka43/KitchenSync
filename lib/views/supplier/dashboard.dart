import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/login_page.dart';
import 'create_shop_page.dart';
import 'product_list.dart';
import 'supplier_order_list_page.dart';
import 'supplier_report_page.dart';

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
  List<Map<String, dynamic>> allItems = [];
  bool isLoading = true;
  int totalShops = 0;
  int totalItems = 0;
  int receivedOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummaryCounts();
    super.initState();
    fetchShopItems();
  }

  Future<void> fetchShopItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('shops')
        .where('supplierId', isEqualTo: user.uid)
        .get();

    List<Map<String, dynamic>> itemsList = [];

    for (var doc in querySnapshot.docs) {
      final shopData = doc.data();
      final shopName = shopData['name'] ?? 'Unnamed Shop';
      final items = List<String>.from(shopData['items'] ?? []);

      for (var item in items) {
        itemsList.add({'shopName': shopName, 'itemName': item.trim()});
      }
    }

    setState(() {
      allItems = itemsList;
      isLoading = false;
    });
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
      backgroundColor: const Color(0xFFF1F3F6),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
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
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildSummaryWidgets(),
            const SizedBox(height: 24),
            _buildPendingOrdersList(),
            Text(
              'Items',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF151640),
              ),
            ),
            const SizedBox(height: 24),
            _buildItemList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allItems.isEmpty) {
      return Center(
        child: Text(
          'No items found.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allItems.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = allItems[index];
        final shopName = item['shopName'] ?? 'Unknown Shop';
        final itemName = item['itemName'] ?? 'Unnamed Item';

        return ListTile(
          leading: const Icon(Icons.inventory_2_outlined, color: Colors.green),
          title: Text(
            itemName.toUpperCase(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            shopName,
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        );
      },
    );
  }

  Widget _buildSummaryWidgets() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _modernSummaryCard(
          'Total Shops',
          totalShops,
          Icons.store,
          Colors.orange,
        ),
        _modernSummaryCard(
          'Total Items',
          totalItems,
          Icons.inventory,
          Colors.teal,
        ),
        _modernSummaryCard(
          'Orders',
          receivedOrders,
          Icons.shopping_cart,
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _modernSummaryCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 26,
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF151640),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
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
                    size: 44,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              _drawerItem(Icons.add_business, 'Create Shop', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateShopPage()),
                );
              }),
              _drawerItem(Icons.receipt_long, 'Orders', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SupplierOrderListPage(shopId: widget.shopId),
                  ),
                );
              }),
              _drawerItem(Icons.inventory_2_outlined, 'Items', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemList(shopId: widget.shopId),
                  ),
                );
              }),
              _drawerItem(Icons.insert_chart_outlined, 'Report', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupplierReportPage(
                      shopId: widget.shopId,
                      shopName: widget.shopName,
                    ),
                  ),
                );
              }),

              const Divider(thickness: 1, indent: 20, endIndent: 20),
              _drawerItem(Icons.logout_rounded, 'Logout', _logout),
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
      onTap: onTap,
      hoverColor: Colors.blue.shade50,
    );
  }

  Widget _buildPendingOrdersList() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('shopId', isEqualTo: widget.shopId)
          .where('status', isEqualTo: 'pending')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'No pending orders.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              'Pending Orders',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF151640),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: orders.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final order = orders[index];
                final data = order.data() as Map<String, dynamic>;
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final items = data['items'] as List?;

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => OrderDetailPopup(orderDoc: order),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 6)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF151640),
                              ),
                            ),
                            if (createdAt != null)
                              Text(
                                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (items != null)
                          Text(
                            '${items.length} item(s)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Popup dialog widget

class OrderDetailPopup extends StatefulWidget {
  final DocumentSnapshot orderDoc;

  const OrderDetailPopup({super.key, required this.orderDoc});

  @override
  State<OrderDetailPopup> createState() => _OrderDetailPopupState();
}

class _OrderDetailPopupState extends State<OrderDetailPopup> {
  String hotelName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchHotelName();
  }

  Future<void> _fetchHotelName() async {
    final data = widget.orderDoc.data() as Map<String, dynamic>;
    final hotelId = data['hotelId'];

    try {
      final hotelSnap = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(hotelId)
          .get();

      if (hotelSnap.exists && hotelSnap.data()!.containsKey('hotelName')) {
        setState(() {
          hotelName = hotelSnap.data()!['hotelName'];
        });
      } else {
        setState(() {
          hotelName = 'Hotel not found';
        });
      }
    } catch (e) {
      setState(() {
        hotelName = 'Error loading hotel';
      });
    }
  }

  Future<void> _confirmOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderDoc.id)
          .update({
            'status': 'accepted',
            'confirmedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order confirmed successfully!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to confirm order.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderDoc.data() as Map<String, dynamic>;
    final items = data['items'] as List? ?? [];
    final status = data['status'];
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final note = data['note'] ?? '';

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        ),
        Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 20,
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxHeight: 520, minWidth: 320),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF151640),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _infoRow('Hotel:', hotelName),

                    if (createdAt != null)
                      _infoRow(
                        'Date:',
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      ),

                    _infoRow('Status:', status.toString().toUpperCase()),

                    const Divider(height: 32),

                    Text(
                      'Items',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF151640),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildItemList(items),

                    if (note.toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Note:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF151640),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          note,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF151640),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                        ),

                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: status == 'pending' ? _confirmOrder : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF357ABD),
                            disabledBackgroundColor: Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF151640),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(List items) {
    if (items.isEmpty) {
      return Text(
        'No items found.',
        style: GoogleFonts.poppins(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map<Widget>((item) {
        final itemId = item['itemId'] ?? 'Unknown';
        final quantity = item['quantity'] ?? '0';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.fastfood, size: 20, color: Color(0xFF357ABD)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$itemId',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                'x $quantity',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
