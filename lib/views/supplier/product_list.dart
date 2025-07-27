import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ItemList extends StatefulWidget {
  final String shopId;
  const ItemList({super.key, required this.shopId});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  String? shopDocId; // Firestore document ID of the shop
  String? customShopId; // Custom shopId field from Firestore
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
        setState(() {
          loading = false;
        });
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
      setState(() {
        loading = false;
      });
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
    setState(() {
      items.removeAt(index);
    });
    _updateItemsInFirestore();
  }

  void _editItem(int index) {
    final currentItem = items[index];
    final controller = TextEditingController(text: currentItem);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Item Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newItem = controller.text.trim();
              if (newItem.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item name cannot be empty')),
                );
                return;
              }

              setState(() {
                items[index] = newItem;
              });
              _updateItemsInFirestore();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Item Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newItem = controller.text.trim();
              if (newItem.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item name cannot be empty')),
                );
                return;
              }

              setState(() {
                items.add(newItem);
              });
              _updateItemsInFirestore();
              Navigator.pop(context);
            },
            child: const Text('Add'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          customShopId != null
              ? 'Items List (Shop ID: $customShopId)'
              : 'Items List',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: 'Add Item',
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No items found.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  color: const Color.fromARGB(200, 0, 0, 0),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      item.toUpperCase(),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 20,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          onPressed: () => _editItem(index),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          onPressed: () => _deleteItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
