import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          "Order List",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: const Color(0xFF151640),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF151640)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return Center(
              child: Text(
                "No orders found",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;
              final timestamp = data['createdAt'] as Timestamp?;
              final createdAt = timestamp != null
                  ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
                  : 'Unknown';

              final status = data['status'] ?? 'pending';
              final items = List<Map<String, dynamic>>.from(
                data['items'] ?? [],
              );

              return FutureBuilder<String>(
                future: _getHotelName(data['hotelId']),
                builder: (context, hotelSnapshot) {
                  final hotelName = hotelSnapshot.data ?? 'Loading...';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.99),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hotel: $hotelName",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 12, 12, 29),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Order ID: ${order.id}",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[900],
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Items:",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF151640),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(left: 12, top: 2),
                            child: Text(
                              "* ${item['itemId']} x ${item['quantity']}",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: const Color.fromARGB(255, 27, 27, 27),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Status: ${status.toUpperCase()}...",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: const Color.fromARGB(200, 0, 0, 0),
                          ),
                        ),
                        Text(
                          "Created: $createdAt",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (status == 'pending') ...[
                              _buildActionButton("Accept", Colors.green, () {
                                _updateStatus(order.id, 'accepted');
                              }),
                              const SizedBox(width: 12),
                              _buildActionButton("Reject", Colors.red, () {
                                _updateStatus(order.id, 'rejected');
                              }),
                            ] else if (status == 'accepted') ...[
                              _buildActionButton("Deliver", Colors.blue, () {
                                _updateStatus(order.id, 'delivered');
                              }),
                            ] else ...[
                              Text(
                                "Action Completed",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
