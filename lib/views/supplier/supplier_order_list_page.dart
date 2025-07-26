import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SupplierOrderListPage extends StatefulWidget {
  final String shopId;

  const SupplierOrderListPage({super.key, required this.shopId});

  @override
  State<SupplierOrderListPage> createState() => _SupplierOrderListPageState();
}

class _SupplierOrderListPageState extends State<SupplierOrderListPage> {
  final Map<String, String> _hotelNameCache = {};

  Future<String> _getHotelName(String hotelId) async {
    if (_hotelNameCache.containsKey(hotelId)) {
      return _hotelNameCache[hotelId]!;
    }

    final doc = await FirebaseFirestore.instance
        .collection('hotels')
        .doc(hotelId)
        .get();
    final name = doc.exists
        ? doc['name'] ?? 'Unnamed Hotel'
        : 'Hotel Not Found';

    _hotelNameCache[hotelId] = name;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('shopId', isEqualTo: widget.shopId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
              final formattedDate = createdAt != null
                  ? DateFormat('yyyy-MM-dd – hh:mm a').format(createdAt)
                  : 'Unknown';
              final items = List<Map<String, dynamic>>.from(
                order['items'] ?? [],
              );
              final hotelId = order['hotelId'] ?? '';

              return FutureBuilder<String>(
                future: _getHotelName(hotelId),
                builder: (context, snapshot) {
                  final hotelName = snapshot.data ?? 'Loading...';

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hotel: $hotelName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Order Date: $formattedDate',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['itemId'] ?? 'Unnamed',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                Text(
                                  'Qty: ${item['quantity'] ?? '0'}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
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
