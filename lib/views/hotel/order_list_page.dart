import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatelessWidget {
  const OrderListPage({Key? key}) : super(key: key);

  Future<String> _getShopName(String shopId) async {
    final shopDoc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .get();
    return shopDoc.exists ? shopDoc['name'] ?? 'Unknown Shop' : 'Unknown Shop';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order List')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text('No orders found'));

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;
              final Timestamp? createdAtTimestamp = data['createdAt'];
              final createdAt = createdAtTimestamp?.toDate();
              final shopId = data['shopId'] ?? '';

              return FutureBuilder<String>(
                future: _getShopName(shopId),
                builder: (context, snapshot) {
                  final shopName = snapshot.data ?? 'Loading...';
                  return ListTile(
                    title: Text('Order at $shopName'),
                    subtitle: Text(
                      createdAt != null ? createdAt.toString() : 'No date',
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(orderDoc: orderDoc),
                        ),
                      );
                    },
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
