import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final DocumentSnapshot orderDoc;

  const OrderDetailPage({Key? key, required this.orderDoc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderData = orderDoc.data() as Map<String, dynamic>;
    final Timestamp? timestamp = orderData['createdAt'];
    final DateTime? createdAt = timestamp?.toDate();

    final String status = orderData['status'] ?? 'unknown';
    final List<dynamic> items = orderData['items'] ?? [];

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black,
        title: const Text("Order Details"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      createdAt != null
                          ? 'Ordered At: ${createdAt.toLocal()}'
                          : 'Date not available',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ordered Items',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ...items.map((item) {
              final itemMap = item as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.inventory_2,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  title: Text(
                    itemMap['itemId'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  subtitle: Text(
                    'Quantity: ${itemMap['quantity'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            Card(
              color: status == 'delivered'
                  ? Colors.green[100]
                  : const Color.fromARGB(255, 9, 255, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      status == 'delivered'
                          ? Icons.check_circle
                          : Icons.pending_actions,
                      color: status == 'delivered'
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : const Color.fromARGB(255, 0, 0, 0),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Status: ${status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: status == 'delivered'
                            ? const Color.fromARGB(255, 255, 255, 255)
                            : const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (status == 'delivered')
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text("Confirm Delivery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final firestore = FirebaseFirestore.instance;

                      // Save to history
                      await firestore.collection('history').add({
                        ...orderData,
                        'confirmedAt': Timestamp.now(),
                      });

                      // Delete from orders
                      await orderDoc.reference.delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Order confirmed and removed from list!",
                          ),
                        ),
                      );

                      Navigator.pop(context); // Go back to list
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                ),
              )
            else
              Center(
                child: Text(
                  'Order not delivered yet...',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
