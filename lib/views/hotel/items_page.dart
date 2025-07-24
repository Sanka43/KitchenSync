import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemPage extends StatefulWidget {
  final String? docId;
  final String? initialName;
  final int? initialStock;
  final int? initialMaxStock;

  const ItemPage({
    this.docId,
    this.initialName,
    this.initialStock,
    this.initialMaxStock,
    super.key,
  });

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _maxStockController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _stockController = TextEditingController(
      text: widget.initialStock?.toString() ?? '0',
    );
    _maxStockController = TextEditingController(
      text: widget.initialMaxStock?.toString() ?? '100',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _maxStockController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final maxStock = int.tryParse(_maxStockController.text.trim()) ?? 0;

    if (stock > maxStock) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current stock cannot exceed max stock')),
      );
      return;
    }

    final itemsCollection = FirebaseFirestore.instance.collection('items');

    try {
      final itemData = {'itemName': name, 'stock': stock, 'maxStock': maxStock};

      if (widget.docId == null) {
        await itemsCollection.add(itemData);
      } else {
        await itemsCollection.doc(widget.docId).update(itemData);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
    }
  }

  Future<void> _deleteItem() async {
    if (widget.docId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.docId)
            .delete();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete item: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Item' : 'Add Item'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isSaving ? null : _deleteItem,
              color: Colors.red,
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Item Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 24,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(115, 0, 0, 0)),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter item name'
                    : null,
              ),

              const SizedBox(height: 20),

              // Max Stock
              TextFormField(
                controller: _maxStockController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Max Stock',
                  labelStyle: TextStyle(color: Colors.black87, fontSize: 24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black45),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Enter max stock';
                  final max = int.tryParse(val.trim());
                  if (max == null || max <= 0)
                    return 'Enter a valid number > 0';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Current Stock
              TextFormField(
                controller: _stockController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Current Stock',
                  labelStyle: TextStyle(color: Colors.black87, fontSize: 24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black45),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Enter current stock';
                  final stock = int.tryParse(val.trim());
                  if (stock == null || stock < 0) return 'Enter a valid number';
                  return null;
                },
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'Update Item' : 'Add Item',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
