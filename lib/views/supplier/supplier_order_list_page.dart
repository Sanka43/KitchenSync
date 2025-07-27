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
        .doc(hotelId) // use UID as hotelId
        .get();

    final name = doc.exists
        ? doc['hotelName'] ?? 'Unnamed Hotel'
        : 'Hotel Not Found';

    _hotelNameCache[hotelId] = name;
    return name;
  }

  Future<void> _updateStatus(String orderId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order List"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('shopId', isEqualTo: widget.shopId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data!.docs;

            if (orders.isEmpty) {
              return const Center(child: Text("No orders found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final data = order.data() as Map<String, dynamic>;
                final timestamp = data['createdAt'] as Timestamp?;
                final createdAt = timestamp != null
                    ? DateFormat(
                        'yyyy-MM-dd – kk:mm',
                      ).format(timestamp.toDate())
                    : 'Unknown';

                final status = data['status'] ?? 'pending';
                final items = List<Map<String, dynamic>>.from(
                  data['items'] ?? [],
                );

                return FutureBuilder<String>(
                  future: _getHotelName(data['hotelId']),
                  builder: (context, snapshot) {
                    final hotelName = snapshot.data ?? 'Loading...';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hotel: $hotelName",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Order ID: ${order.id}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Items:",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            ...items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(
                                  left: 12.0,
                                  top: 2,
                                ),
                                child: Text(
                                  "- ${item['itemId']} x ${item['quantity']}",
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Status: ${status.toUpperCase()}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Created: $createdAt",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (status == 'pending') ...[
                                  _buildButton(
                                    "Accept",
                                    Colors.green,
                                    () => _updateStatus(order.id, 'accepted'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildButton(
                                    "Reject",
                                    Colors.red,
                                    () => _updateStatus(order.id, 'rejected'),
                                  ),
                                ] else if (status == 'accepted') ...[
                                  _buildButton(
                                    "Deliver",
                                    Colors.blue,
                                    () => _updateStatus(order.id, 'delivered'),
                                  ),
                                ] else ...[
                                  Text(
                                    "Action Completed",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
