import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_detail_page.dart';
import 'add_order_page.dart';

class OrderListPage extends StatelessWidget {
  const OrderListPage({super.key});

  Future<String> _getShopName(String shopId) async {
    final shopDoc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .get();
    return shopDoc.exists ? shopDoc['name'] ?? 'Unknown Shop' : 'Unknown Shop';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy • hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    const lightBackground = Color(0xFFF1F3F6);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Order List',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddOrderPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: lightBackground,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No orders found',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;
              final shopId = data['shopId'] ?? '';

              return FutureBuilder<String>(
                future: _getShopName(shopId),
                builder: (context, shopSnapshot) {
                  final shopName =
                      shopSnapshot.connectionState == ConnectionState.waiting
                      ? 'Loading...'
                      : shopSnapshot.data ?? 'Unknown Shop';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(orderDoc: orderDoc),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        title: Text(
                          'Order at $shopName',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(createdAt),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
