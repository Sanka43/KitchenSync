import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemList extends StatefulWidget {
  final String shopId;
  const ItemList({super.key, required this.shopId});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  String? shopDocId;
  String? customShopId;
  List<String> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadShopItems();
  }

  Future<void> _loadShopItems() async {
    try {
      final shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .get();

      if (!shopDoc.exists) {
        setState(() => loading = false);
        return;
      }

      final data = shopDoc.data()!;
      List<dynamic> rawItems = data['items'] ?? [];

      setState(() {
        shopDocId = shopDoc.id;
        customShopId = data['shopId'] as String?;
        items = rawItems.map((e) => (e as String).trim()).toList();
        loading = false;
      });
    } catch (e) {
      print('Error loading shop items: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _updateItemsInFirestore() async {
    if (shopDocId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopDocId)
          .update({'items': items});
    } catch (e) {
      print('Error updating items: $e');
    }
  }

  void _deleteItem(int index) {
    setState(() => items.removeAt(index));
    _updateItemsInFirestore();
  }

  void _addItem() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Item', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Item Name',
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              final newItem = controller.text.trim();
              if (newItem.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Item name cannot be empty',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
                return;
              }
              setState(() => items.add(newItem));
              _updateItemsInFirestore();
              Navigator.pop(context);
            },
            child: Text('Add', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Items List',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        // centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No items found.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: Container(
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      title: Text(
                        item.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_outlined,
                          size: 30,
                          color: Color.fromARGB(255, 154, 0, 0),
                        ),
                        onPressed: () => _deleteItem(index),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.green[600],
        tooltip: 'Add Item',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
