import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_shop_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class ShopListPage extends StatefulWidget {
  final String hotelId;

  const ShopListPage({super.key, required this.hotelId});

  @override
  State<ShopListPage> createState() => _ShopListPageState();
}

class _ShopListPageState extends State<ShopListPage> {
  Map<String, dynamic>? _selectedShop;
  String? _selectedDocId;
  Map<String, String> supplierNames = {};

  @override
  void initState() {
    super.initState();
    _loadSupplierNames();
  }

  Future<void> _loadSupplierNames() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'supplier')
        .get();

    final Map<String, String> tempMap = {};
    for (var doc in snapshot.docs) {
      tempMap[doc['uid']] = doc['username'];
    }

    setState(() {
      supplierNames = tempMap;
    });
  }

  void _showDetails(DocumentSnapshot doc) {
    final shop = doc.data() as Map<String, dynamic>;
    final supplierId = shop['supplierId'];
    final ownerName = supplierNames[supplierId] ?? 'Unknown';

    setState(() {
      _selectedShop = {...shop, 'owner': ownerName};
      _selectedDocId = doc.id;
    });
  }

  void _deleteShop(String? docId) async {
    if (docId == null) return;
    try {
      await FirebaseFirestore.instance.collection('shops').doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shop deleted')));
      setState(() {
        _selectedShop = null;
        _selectedDocId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete shop: $e')));
    }
  }

  void _editShopDialog() {
    final nameController = TextEditingController(text: _selectedShop?['name']);
    final ownerController = TextEditingController(
      text: _selectedShop?['owner'],
    ); // Not editable now
    final mobileController = TextEditingController(
      text: _selectedShop?['number'],
    );
    final locationController = TextEditingController(
      text: _selectedShop?['location'],
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Shop"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Shop Name'),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('shops')
                  .doc(_selectedDocId)
                  .update({
                    'name': nameController.text.trim(),
                    'number': mobileController.text.trim(),
                    'location': locationController.text.trim(),
                  });
              Navigator.pop(context);
              setState(() {
                _selectedShop = null;
              });
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteShop(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this shop?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteShop(docId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: const Text("Shop List", style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddShopPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shops')
                  .where('hotelId', isEqualTo: widget.hotelId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading shops"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No shops available",
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final shopData = docs[index].data() as Map<String, dynamic>;
                    final shopName = shopData['name'] ?? 'Unnamed Shop';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          shopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        leading: const Icon(Icons.store, color: Colors.white),
                        onTap: () => _showDetails(docs[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedShop != null) ...[
            const Divider(),
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 140, 255).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Shop Name: ${_selectedShop?['name']}",
                    style: const TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  Text(
                    "Owner: ${_selectedShop?['owner']}",
                    style: const TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  Text(
                    "Mobile: ${_selectedShop?['number']}",
                    style: const TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  Text(
                    "Location: ${_selectedShop?['location']}",
                    style: const TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _editShopDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _confirmDeleteShop(_selectedDocId!),
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
