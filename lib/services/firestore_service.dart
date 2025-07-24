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

  /// ✅ FIXED: Now includes document ID as 'id'
  Future<List<Map<String, dynamic>>> getShops() async {
    final querySnapshot = await _firestore.collection('shops').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include document ID
      return data;
    }).toList();
  }

  /// ✅ FIXED: Now includes document ID as 'id'
  Future<List<Map<String, dynamic>>> getItems() async {
    final querySnapshot = await _firestore.collection('items').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include document ID
      return data;
    }).toList();
  }

  /// ✅ Optional: Stream version (if needed for real-time updates)
  Stream<List<Map<String, dynamic>>> getItemsStream() {
    return _firestore
        .collection('items')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Include ID
            return data;
          }).toList(),
        );
  }

  Future<int> getTotalOrders() async {
    final snapshot = await _firestore.collection('orders').get();
    return snapshot.docs.length;
  }

  Future<int> getPendingBills() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  Future<int> getDeliveredOrders() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'delivered')
        .get();
    return snapshot.docs.length;
  }

  /// ----------------- SUPPLIER / SHOP METHODS -----------------

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

  Stream<QuerySnapshot> getUserShops() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('shops')
        .where('supplierId', isEqualTo: uid)
        .snapshots();
  }

  Future<String?> getCurrentUserName() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['username'];
    }
    return null;
  }

  // ITEM METHODS
  Future<List<String>> getItemsForShop(String shopId) async {
    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      return List<String>.from(data?['items'] ?? []);
    }
    return [];
  }
}
