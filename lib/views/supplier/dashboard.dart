import 'package:flutter/material.dart';

class SupplierDashboard extends StatelessWidget {
  const SupplierDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Supplier Dashboard")),
      body: Center(child: Text("Welcome to your shop dashboard!")),
    );
  }
}
