import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final FirestoreService firestoreService = FirestoreService();

  List<Map<String, dynamic>> shops = [];
  List<Map<String, dynamic>> itemsFromDb = [];

  String? selectedShopId;

  List<Map<String, String>> items = [
    {'itemId': '', 'quantity': ''},
  ];

  final TextEditingController noteController = TextEditingController();

  bool isSubmitting = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopsAndItems();
  }

  Future<void> _loadShopsAndItems() async {
    try {
      final fetchedShops = await firestoreService.getShops();
      final fetchedItems = await firestoreService.getItems();

      setState(() {
        shops = fetchedShops;
        itemsFromDb = fetchedItems;
        if (shops.isNotEmpty) {
          selectedShopId = shops.first['id'];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading shops/items: $e")));
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Add Order"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildGlassContainer(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Target Shop',
                      style: TextStyle(color: Colors.black87, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedShopId,
                      items: shops
                          .map(
                            (shop) => DropdownMenuItem<String>(
                              value: shop['id'],
                              child: Text(
                                shop['name'],
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedShopId = value;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Order Items',
                      style: TextStyle(color: Colors.black87, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    ..._buildItemFields(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          if (items.length < 10) {
                            setState(() {
                              items.add({'itemId': '', 'quantity': ''});
                            });
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.teal),
                        label: const Text(
                          "Add Item",
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Note (optional)",
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(noteController, "Enter a note"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();
                              setState(() => isSubmitting = true);

                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  throw Exception("User not logged in");
                                }
                                if (selectedShopId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please select a shop"),
                                    ),
                                  );
                                  setState(() => isSubmitting = false);
                                  return;
                                }

                                final filteredItems = items.where((item) {
                                  final qtyValid =
                                      int.tryParse(item['quantity'] ?? '') !=
                                          null &&
                                      int.parse(item['quantity']!) > 0;
                                  final itemSelected =
                                      (item['itemId'] ?? '').isNotEmpty;
                                  return qtyValid && itemSelected;
                                }).toList();

                                if (filteredItems.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please add at least one valid item with quantity > 0",
                                      ),
                                    ),
                                  );
                                  setState(() => isSubmitting = false);
                                  return;
                                }

                                await firestoreService.createOrder(
                                  hotelId: user.uid,
                                  shopId: selectedShopId!,
                                  items: filteredItems,
                                  note: noteController.text.trim(),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Order submitted successfully",
                                    ),
                                  ),
                                );

                                setState(() {
                                  items = [
                                    {'itemId': '', 'quantity': ''},
                                  ];
                                  noteController.clear();
                                  isSubmitting = false;
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                                setState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        shadowColor: Colors.tealAccent,
                        elevation: 10,
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Order",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGlassContainer(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  List<Widget> _buildItemFields() {
    return List.generate(items.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: items[index]['itemId']!.isEmpty
                    ? null
                    : items[index]['itemId'],
                items: itemsFromDb
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['id'],
                        child: Text(
                          item['name'],
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    items[index]['itemId'] = value ?? '';
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Select Item',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: items[index]['quantity'],
                style: const TextStyle(color: Colors.black87),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  items[index]['quantity'] = value;
                },
                decoration: InputDecoration(
                  hintText: 'Qty',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (index != 0)
              IconButton(
                onPressed: () {
                  setState(() => items.removeAt(index));
                },
                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
