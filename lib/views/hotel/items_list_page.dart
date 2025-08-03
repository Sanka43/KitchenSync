import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'items_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemsListPage extends StatefulWidget {
  final String hotelId;

  const ItemsListPage({super.key, required this.hotelId});

  @override
  State<ItemsListPage> createState() => _ItemsListPageState();
}

class _ItemsListPageState extends State<ItemsListPage> {
  String _searchQuery = '';

  void updateItemStockFromOrder(
    List<Map<String, dynamic>> deliveredItems,
  ) async {
    final firestore = FirebaseFirestore.instance;
    bool allSuccess = true;

    for (final item in deliveredItems) {
      final itemId = item['itemId'];
      final deliveredQty = item['quantity'] ?? 0;

      if (itemId != null && deliveredQty is int) {
        try {
          final itemDoc = await firestore.collection('items').doc(itemId).get();
          if (itemDoc.exists) {
            final data = itemDoc.data()!;
            final currentStock = data['stock'] ?? 0;
            final maxStock = data['maxStock'] ?? 0;

            int newStock = currentStock + deliveredQty;
            if (newStock > maxStock) newStock = maxStock;

            await firestore.collection('items').doc(itemId).update({
              'stock': newStock,
            });
          }
        } catch (e) {
          allSuccess = false;
          debugPrint('Failed to update $itemId: $e');
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allSuccess
              ? 'Stocks updated successfully!'
              : 'Some items failed to update.',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Items',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemPage(hotelId: widget.hotelId),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.black54,
                  size: 24,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black26, width: 1.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black87, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('hotelId', isEqualTo: widget.hotelId)
            .orderBy('itemName')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['itemName'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery);
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No results match your search.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['itemName'] ?? 'Unnamed';
              final stock = data['stock'] ?? 0;
              final maxStock = data['maxStock'] ?? 100;
              final itemId = doc.id;

              return FutureBuilder<DatabaseEvent>(
                future: FirebaseDatabase.instance.ref('weights/$itemId').once(),
                builder: (context, rtdbSnapshot) {
                  double? weight;
                  if (rtdbSnapshot.connectionState == ConnectionState.done &&
                      rtdbSnapshot.hasData &&
                      rtdbSnapshot.data!.snapshot.value != null) {
                    final val = rtdbSnapshot.data!.snapshot.value;
                    if (val is Map) {
                      weight = (val['weight'] as num?)?.toDouble();
                    }
                  }

                  final double percentage = (stock / maxStock)
                      .clamp(0.0, 1.0)
                      .toDouble();
                  Color progressColor;
                  if (percentage <= 0.25) {
                    progressColor = Colors.red;
                  } else if (percentage <= 0.5) {
                    progressColor = Colors.orange;
                  } else if (percentage <= 0.75) {
                    progressColor = Colors.yellow[700]!;
                  } else {
                    progressColor = Colors.green;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            'Stock: $stock / $maxStock',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          if (weight != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Weight: ${weight.toStringAsFixed(2)} g',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 8,
                              backgroundColor: const Color.fromARGB(
                                60,
                                0,
                                0,
                                0,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.edit, color: Colors.black54),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemPage(
                              hotelId: widget.hotelId,
                              docId: doc.id,
                              initialName: name,
                              initialStock: stock,
                              initialMaxStock: maxStock,
                            ),
                          ),
                        );
                      },
                      onLongPress: () =>
                          _showDeleteConfirmation(context, doc.id, name),
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

  void _showDeleteConfirmation(
    BuildContext context,
    String docId,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Delete Item', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$itemName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('items')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('"$itemName" deleted')));
            },
          ),
        ],
      ),
    );
  }
}
