import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final DocumentSnapshot orderDoc;

  const OrderDetailPage({Key? key, required this.orderDoc}) : super(key: key);

  Future<String> _getShopName(String shopId) async {
    final shopDoc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .get();
    return shopDoc.exists ? shopDoc['name'] ?? 'Unknown Shop' : 'Unknown Shop';
  }

  @override
  Widget build(BuildContext context) {
    final orderData = orderDoc.data() as Map<String, dynamic>;
    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();
    final shopId = orderData['shopId'] ?? '';
    final items = orderData['items'] as List<dynamic>? ?? [];

    return FutureBuilder<String>(
      future: _getShopName(shopId),
      builder: (context, snapshot) {
        final shopName = snapshot.data ?? 'Loading...';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Order Details'),
            backgroundColor: Colors.black87,
          ),
          backgroundColor: Colors.black,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text(
                      'Shop Name: $shopName',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (createdAt != null)
                      Text(
                        'Order Time: ${createdAt.day}/${createdAt.month}/${createdAt.year} '
                        '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Items:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...items.map((item) {
                      final itemId = item['itemId'] ?? 'Unknown';
                      final quantity = item['quantity'] ?? '0';
                      return ListTile(
                        title: Text(
                          itemId.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Quantity: $quantity',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        leading: const Icon(
                          Icons.shopping_cart,
                          color: Colors.white54,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
