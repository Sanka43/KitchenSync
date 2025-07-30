import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemPage extends StatefulWidget {
  final String? docId;
  final String? initialName;
  final int? initialStock;
  final int? initialMaxStock;
  final String hotelId; // <- Required hotel ID

  const ItemPage({
    super.key,
    this.docId,
    this.initialName,
    this.initialStock,
    this.initialMaxStock,
    required this.hotelId, // <- Pass this when opening ItemPage
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
      _showMessage('Current stock cannot exceed max stock');
      return;
    }

    final itemsCollection = FirebaseFirestore.instance.collection('items');

    try {
      if (widget.docId == null) {
        final existing = await itemsCollection
            .where('itemName', isEqualTo: name)
            .where('hotelId', isEqualTo: widget.hotelId)
            .get();
        if (existing.docs.isNotEmpty) {
          setState(() => _isSaving = false);
          _showMessage('Item name already exists for this hotel');
          return;
        }
      }

      final itemData = {
        'itemName': name,
        'stock': stock,
        'maxStock': maxStock,
        'hotelId': widget.hotelId,
      };

      if (widget.docId == null) {
        await itemsCollection.add(itemData);
      } else {
        await itemsCollection.doc(widget.docId).update(itemData);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _isSaving = false);
      _showMessage('Failed to save item');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteItem() async {
    if (widget.docId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Item?', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete this item?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
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
      } catch (_) {
        setState(() => _isSaving = false);
        _showMessage('Failed to delete item');
      }
    }
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: const Color.fromARGB(255, 156, 156, 156),
      ),
      filled: true,
      fillColor: const Color.fromARGB(43, 123, 123, 123),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          isEdit ? 'Edit Item' : 'Add Item',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: isEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.black,
                  onPressed: _isSaving ? null : _deleteItem,
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formLabel('Item Name'),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        autofocus: true,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: _inputStyle('Enter item name'),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Item name required'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      _formLabel('Max Stock'),
                      TextFormField(
                        controller: _maxStockController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: _inputStyle('Enter max stock'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Max stock required';
                          }
                          final max = int.tryParse(val.trim());
                          if (max == null || max <= 0) {
                            return 'Enter number > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _formLabel('Current Stock'),
                      TextFormField(
                        controller: _stockController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: _inputStyle('Enter current stock'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Current stock required';
                          }
                          final stock = int.tryParse(val.trim());
                          if (stock == null || stock < 0) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      AnimatedOpacity(
                        opacity: _isSaving ? 0.7 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton.icon(
                          icon: Icon(
                            isEdit ? Icons.update : Icons.add,
                            color: Colors.white,
                          ),
                          label: Text(
                            isEdit ? 'Update Item' : 'Add Item',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _formLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
