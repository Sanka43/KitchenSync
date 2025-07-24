import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrder({
    required String hotelId,
    required String shopId,
    required List<Map<String, String>> items,
    required String note,
  }) async {
    await _firestore.collection('orders').add({
      'hotelId': hotelId,
      'items': items,
      'note': note,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getShops() async {
    final querySnapshot = await _firestore.collection('shops').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final querySnapshot = await _firestore.collection('items').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<Map<String, dynamic>>> getItemsStream() {
    return _firestore
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
