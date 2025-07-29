// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';

// import '../../services/realtime_service.dart';
// import '../../services/usage_service.dart' as services_usage;
// import '../auth/login_page.dart';
// import 'edit_profile_page.dart';
// import 'order_list_page.dart';
// import 'items_list_page.dart';
// import 'shop_list_page.dart';

// class HotelDashboard extends StatefulWidget {
//   const HotelDashboard({super.key});

//   @override
//   State<HotelDashboard> createState() => _HotelDashboardState();
// }

// class _HotelDashboardState extends State<HotelDashboard> {
//   late final String currentUserId;
//   final RealtimeService _realtimeService = RealtimeService();
//   final services_usage.UsageService _usageService =
//       services_usage.UsageService();

//   List<Map<String, dynamic>> _items = [];
//   double _todayUsage = 0;
//   String _hotelName = "Loading...";
//   bool _isLoading = true;

//   /// Set this to true to test hardcoded supplierId ignoring currentUserId
//   final bool testHardcodedSupplierId = false;
//   final String hardcodedSupplierId = 'rYOVtiYNaDcYHsseguhM1fepkZH3';

//   @override
//   void initState() {
//     super.initState();
//     currentUserId = FirebaseAuth.instance.currentUser!.uid;
//     print('Current User ID: $currentUserId');
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     try {
//       final supplierIdToQuery = testHardcodedSupplierId
//           ? hardcodedSupplierId
//           : currentUserId;

//       print('Querying shops with supplierId: $supplierIdToQuery');

//       final shopQuery = await FirebaseFirestore.instance
//           .collection('shops')
//           .where('supplierId', isEqualTo: supplierIdToQuery)
//           .get();

//       print('Shops found: ${shopQuery.docs.length}');
//       for (var doc in shopQuery.docs) {
//         print(
//           'Shop doc ID: ${doc.id}, Name: ${doc['name']}, supplierId: ${doc['supplierId']}',
//         );
//       }

//       if (shopQuery.docs.isEmpty) {
//         setState(() {
//           _hotelName = "No shop found";
//           _items = [];
//           _isLoading = false;
//         });
//         return;
//       }

//       final shop = shopQuery.docs.first.data();
//       final itemNames = List<String>.from(shop['items'] ?? []);

//       final itemsSnapshot = await FirebaseFirestore.instance
//           .collection('items')
//           .get();
//       final relevantItems = itemsSnapshot.docs
//           .where((doc) => itemNames.contains(doc['itemName']))
//           .map((doc) => doc.data())
//           .toList();

//       final usage = await _usageService.getTodayUsage(supplierIdToQuery);

//       setState(() {
//         _items = relevantItems;
//         _todayUsage = usage;
//         _hotelName = shop['name'] ?? 'Unnamed Hotel';
//         _isLoading = false;
//       });

//       await _usageService.saveTodayUsage(supplierIdToQuery, _todayUsage);
//     } catch (e) {
//       debugPrint("Error loading data: $e");
//       setState(() {
//         _hotelName = "Error loading data";
//         _isLoading = false;
//       });
//     }
//   }

//   int get _lowStockCount => _items.where((item) {
//     final stock = item['stock'];
//     if (stock is int) return stock <= 10;
//     if (stock is String) {
//       final parsed = int.tryParse(stock);
//       return parsed != null && parsed <= 10;
//     }
//     return false;
//   }).length;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F3F6),
//       drawer: _buildDrawer(context),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text('', style: GoogleFonts.poppins(color: Colors.black)),
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
//                   final itemWidth =
//                       (constraints.maxWidth - (16.0 * (crossAxisCount - 1))) /
//                       crossAxisCount;
//                   return Wrap(
//                     spacing: 16,
//                     runSpacing: 16,
//                     children: [
//                       _buildTotalShopsCard(itemWidth),
//                       // add other cards/widgets here
//                     ],
//                   );
//                 },
//               ),
//             ),
//     );
//   }

//   Widget _buildDrawer(BuildContext context) {
//     return Drawer(
//       child: Stack(
//         children: [
//           Container(color: Colors.white.withOpacity(1)),
//           BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//             child: Container(color: const Color.fromARGB(255, 245, 245, 245)),
//           ),
//           ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               UserAccountsDrawerHeader(
//                 decoration: BoxDecoration(color: Colors.white.withOpacity(1)),
//                 accountName: Text(
//                   _hotelName,
//                   style: GoogleFonts.poppins(
//                     color: const Color.fromARGB(255, 21, 22, 64),
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//                 accountEmail: Text(
//                   "Main Kitchen",
//                   style: GoogleFonts.poppins(
//                     color: const Color.fromARGB(230, 21, 22, 64),
//                     fontSize: 14,
//                   ),
//                 ),
//                 currentAccountPicture: GestureDetector(
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const EditProfilePage()),
//                   ),
//                   child: const CircleAvatar(
//                     backgroundColor: Colors.black12,
//                     child: Icon(
//                       Icons.person,
//                       color: Color.fromARGB(255, 21, 22, 64),
//                       size: 40,
//                     ),
//                   ),
//                 ),
//               ),
//               _buildDrawerItem(Icons.list_alt, 'Order List', () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => OrderListPage()),
//                 );
//               }),
//               _buildDrawerItem(Icons.inventory, 'Items', () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const ItemsListPage()),
//                 );
//               }),
//               _buildDrawerItem(Icons.shopping_cart, 'Shops', () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ShopListPage(hotelId: currentUserId),
//                   ),
//                 );
//               }),
//               const Divider(thickness: 0.5),
//               _buildDrawerItem(Icons.edit, 'Edit Profile', () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const EditProfilePage()),
//                 );
//               }),
//               _buildDrawerItem(Icons.logout, 'Logout', () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => const LoginPage()),
//                 );
//               }),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
//     return ListTile(
//       leading: Icon(icon, color: const Color.fromARGB(255, 21, 22, 64)),
//       title: Text(
//         title,
//         style: GoogleFonts.poppins(
//           color: const Color.fromARGB(255, 21, 22, 64),
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }

//   Widget _buildTotalShopsCard(double width) {
//     final supplierIdToQuery = testHardcodedSupplierId
//         ? hardcodedSupplierId
//         : currentUserId;

//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('shops')
//           .where('supplierId', isEqualTo: supplierIdToQuery)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return SizedBox(
//             width: width,
//             child: const Center(child: CircularProgressIndicator()),
//           );
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return SizedBox(
//             width: width,
//             child: Card(
//               color: Colors.white,
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   'No shops found',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     color: Colors.black54,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           );
//         }

//         final totalShops = snapshot.data!.docs.length;

//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           color: Colors.white,
//           child: Container(
//             width: width,
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Total Shops',
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Icon(Icons.storefront, color: Colors.green, size: 40),
//                     Text(
//                       '$totalShops',
//                       style: GoogleFonts.poppins(
//                         fontSize: 36,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
