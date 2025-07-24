import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddShopPage extends StatefulWidget {
  final String? docId;
  final String? initialName;
  final String? initialOwner;
  final String? initialNumber;
  final String? initialLocation;

  const AddShopPage({
    this.docId,
    this.initialName,
    this.initialOwner,
    this.initialNumber,
    this.initialLocation,
    super.key,
  });

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ownerController;
  late TextEditingController _numberController;
  late TextEditingController _locationController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _ownerController = TextEditingController(text: widget.initialOwner ?? '');
    _numberController = TextEditingController(text: widget.initialNumber ?? '');
    _locationController = TextEditingController(
      text: widget.initialLocation ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _numberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final owner = _ownerController.text.trim();
    final number = _numberController.text.trim();
    final location = _locationController.text.trim();

    final shopsCollection = FirebaseFirestore.instance.collection('shops');

    try {
      final Map<String, dynamic> shopData = {
        'name': name,
        'owner': owner,
        'number': number,
        'location': location,
      };

      if (widget.docId == null) {
        // Only add timestamp when creating a new shop
        shopData['timestamp'] = FieldValue.serverTimestamp();
        await shopsCollection.add(shopData);
      } else {
        await shopsCollection.doc(widget.docId).update(shopData);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save shop: $e')));
    }
  }

  Future<void> _deleteShop() async {
    if (widget.docId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop?'),
        content: const Text('Are you sure you want to delete this shop?'),
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
            .collection('shops')
            .doc(widget.docId)
            .delete();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete shop: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Shop' : 'Add Shop'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: _isSaving ? null : _deleteShop,
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
              // Shop Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Shop Name',
                  labelStyle: TextStyle(color: Colors.black, fontSize: 24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black45),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter shop name'
                    : null,
              ),
              const SizedBox(height: 20),

              // Owner Name
              TextFormField(
                controller: _ownerController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Owner Name',
                  labelStyle: TextStyle(color: Colors.black, fontSize: 24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black45),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter owner name'
                    : null,
              ),
              const SizedBox(height: 20),

              // Mobile Number
              TextFormField(
                controller: _numberController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  labelStyle: TextStyle(color: Colors.black, fontSize: 24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black45),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter mobile number'
                    : null,
              ),
              const SizedBox(height: 20),

              // Location
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.black, fontSize: 24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black45),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveShop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'Update Shop' : 'Add Shop',
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
