import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ----------------- ORDER METHODS -----------------

  Future<void> createOrder({
    required String hotelId,
    required String shopId,
    required List<Map<String, String>> items,
    required String note,
  }) async {
    await _firestore.collection('orders').add({
      'hotelId': hotelId,
      'shopId': shopId,
      'items': items,
      'note': note,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all shops (with document ID included)
  Future<List<Map<String, dynamic>>> getShops() async {
    final querySnapshot = await _firestore.collection('shops').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get all items (with document ID included)
  Future<List<Map<String, dynamic>>> getItems() async {
    final querySnapshot = await _firestore.collection('items').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Optional real-time stream of items
  Stream<List<Map<String, dynamic>>> getItemsStream() {
    return _firestore
        .collection('items')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  /// Count of all orders
  Future<int> getTotalOrders() async {
    final snapshot = await _firestore.collection('orders').get();
    return snapshot.docs.length;
  }

  /// Count of pending orders
  Future<int> getPendingBills() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  /// Count of delivered orders
  Future<int> getDeliveredOrders() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'delivered')
        .get();
    return snapshot.docs.length;
  }

  /// ----------------- SUPPLIER / SHOP METHODS -----------------

  /// Add a new shop
  Future<void> addShop({
    required String name,
    required String location,
    required String contact,
    required List<String> items,
  }) async {
    final uid = _auth.currentUser!.uid;
    final shopRef = _firestore.collection('shops').doc();
    final shopId = shopRef.id;

    await shopRef.set({
      'name': name,
      'location': location,
      'contact': contact,
      'items': items,
      'supplierId': uid,
      'shopId': shopId,
      'createdAt': Timestamp.now(),
    });
  }

  /// Get real-time stream of shops owned by the logged-in supplier
  Stream<QuerySnapshot> getUserShops() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('shops')
        .where('supplierId', isEqualTo: uid)
        .snapshots();
  }

  /// Get current logged-in user's name (from 'users' collection)
  Future<String?> getCurrentUserName() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['username'];
    }
    return null;
  }

  /// Get list of item IDs assigned to the given shop
  Future<List<String>> getItemsForShop(String shopId) async {
    final doc = await _firestore.collection('shops').doc(shopId).get();
    if (doc.exists) {
      final data = doc.data();
      return List<String>.from(data?['items'] ?? []);
    }
    return [];
  }

  /// Get list of shop IDs for the logged-in supplier
  Future<List<String>> getShopIdsForCurrentSupplier() async {
    final uid = _auth.currentUser!.uid;
    final querySnapshot = await _firestore
        .collection('shops')
        .where('supplierId', isEqualTo: uid)
        .get();

    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  /// Get first shop ID for supplier (used before when no shop selection was available)
  Future<String?> getFirstShopIdForCurrentSupplier() async {
    final uid = _auth.currentUser!.uid;
    final querySnapshot = await _firestore
        .collection('shops')
        .where('supplierId', isEqualTo: uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  /// 🆕 Get a specific shop by ID (full data)
  Future<Map<String, dynamic>?> getShopById(String shopId) async {
    final doc = await _firestore.collection('shops').doc(shopId).get();
    if (doc.exists) {
      final data = doc.data();
      data?['id'] = doc.id;
      return data;
    }
    return null;
  }

  /// 🆕 Get just name and contact for a shop
  Future<Map<String, String>?> getShopInfo(String shopId) async {
    final doc = await _firestore.collection('shops').doc(shopId).get();
    if (doc.exists) {
      final data = doc.data();
      return {
        'name': data?['name'] ?? 'Unnamed Shop',
        'contact': data?['contact'] ?? '',
      };
    }
    return null;
  }
}
