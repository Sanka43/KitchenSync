import 'dart:ui';
import 'package:flutter/material.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  // Dummy data placeholders
  int totalOrders = 12;
  int pendingBills = 3;
  int deliveredOrders = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Supplier Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildGlassCard(child: _buildStatBox("Total Orders", "$totalOrders")),
              _buildGlassCard(child: _buildStatBox("Pending Bills", "$pendingBills")),
              _buildGlassCard(child: _buildStatBox("Delivered Orders", "$deliveredOrders")),
              _buildGlassCard(child: _buildSectionPlaceholder("Order Tracking")),
              _buildGlassCard(child: _buildSectionPlaceholder("Bill Management")),
              _buildGlassCard(child: _buildSectionPlaceholder("Connect New Hotel")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionPlaceholder(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text("$title content coming soon...", style: const TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Supplier Panel",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                SizedBox(height: 4),
                Text("Manage Your Orders", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.track_changes, color: Colors.white),
            title: const Text('Order Tracking', style: TextStyle(color: Colors.white)),
            onTap: () {
              // TODO: Navigate to Order Tracking page
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.white),
            title: const Text('Bill Management', style: TextStyle(color: Colors.white)),
            onTap: () {
              // TODO: Navigate to Bill Management page
            },
          ),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.white),
            title: const Text('Connect New Hotel', style: TextStyle(color: Colors.white)),
            onTap: () {
              // TODO: Navigate to Connect New Hotel page
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
