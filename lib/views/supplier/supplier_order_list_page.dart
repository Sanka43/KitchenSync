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
        backgroundColor: Colors.transparent,
        elevation: 0,
        // centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Order List",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
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
                  ? DateFormat(
                      'yyyy-MM-dd • hh:mm a',
                    ).format(timestamp.toDate())
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotelName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Order ID: ${order.id}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Divider(height: 20, thickness: 0.5),
                        Text(
                          "Items Ordered:",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 3),
                            child: Text(
                              "• ${item['itemId']} x ${item['quantity']}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusChip(status),
                            const Spacer(),
                            Text(
                              createdAt,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (status == 'pending') ...[
                              _buildActionButton("Accept", Colors.green, () {
                                _updateStatus(order.id, 'accepted');
                              }),
                              _buildActionButton("Reject", Colors.red, () {
                                _updateStatus(order.id, 'rejected');
                              }),
                            ] else if (status == 'accepted') ...[
                              _buildActionButton("Deliver", Colors.blue, () {
                                _updateStatus(order.id, 'delivered');
                              }),
                            ] else ...[
                              Text(
                                "No further actions",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600],
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
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData icon;
    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'accepted':
        chipColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'delivered':
        chipColor = Colors.blue;
        icon = Icons.local_shipping_outlined;
        break;
      case 'rejected':
        chipColor = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      default:
        chipColor = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.poppins(
              color: chipColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
