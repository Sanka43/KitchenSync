import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatelessWidget {
  final DocumentSnapshot orderDoc;

  const OrderDetailPage({Key? key, required this.orderDoc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderData = orderDoc.data() as Map<String, dynamic>;
    final Timestamp? timestamp = orderData['createdAt'];
    final DateTime? createdAt = timestamp?.toDate();
    final formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : 'Date not available';

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
              color: const Color.fromARGB(255, 0, 0, 0),
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
                      'Ordered At: $formattedDate',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
                color: const Color.fromARGB(255, 0, 0, 0),
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
                      fontSize: 20,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  subtitle: Text(
                    'Quantity: ${itemMap['quantity'] ?? ''}',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),

            // Status Card
            Card(
              color: status == 'accepted'
                  ? Colors.green[300]
                  : status == 'pending'
                  ? const Color.fromARGB(255, 255, 127, 77)
                  : status == 'rejected'
                  ? Colors.red[300]
                  : Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      status == 'accepted'
                          ? Icons.check_circle
                          : status == 'pending'
                          ? Icons.access_time
                          : status == 'rejected'
                          ? Icons.cancel
                          : Icons.help,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Status: ${status.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Conditional UI based on status
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

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                ),
              )
            else if (status == 'rejected')
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit and Reorder"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    // You can navigate to edit/reorder page here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Implement reorder/edit logic here."),
                      ),
                    );
                  },
                ),
              )
            else if (status == 'pending')
              Center(
                child: Text(
                  'Waiting for supplier to accept/reject...',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (status == 'accepted')
              Center(
                child: Text(
                  'Order has been accepted!',
                  style: TextStyle(
                    color: Colors.green[800],
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
