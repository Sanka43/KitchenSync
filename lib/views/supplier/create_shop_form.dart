import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class CreateShopForm extends StatefulWidget {
  const CreateShopForm({super.key});

  @override
  State<CreateShopForm> createState() => _CreateShopFormState();
}

class _CreateShopFormState extends State<CreateShopForm> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final contactController = TextEditingController();
  final itemsController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  bool isLoading = false;

  void _submitShop() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      await firestoreService.addShop(
        name: nameController.text.trim(),
        location: locationController.text.trim(),
        contact: contactController.text.trim(),
        items: itemsController.text.trim().split(','),
      );
      setState(() => isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Shop")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, "Shop Name"),
              _buildTextField(locationController, "Location"),
              _buildTextField(contactController, "Contact Number"),
              _buildTextField(
                itemsController,
                "Providing Items (comma-separated)",
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _submitShop,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? "Required" : null,
      ),
    );
  }
}
