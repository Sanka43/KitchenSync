import 'package:firebase_database/firebase_database.dart';

class RealtimeService {
  final _db = FirebaseDatabase.instance.ref('inventory_items');

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final snapshot = await _db.get();
    if (!snapshot.exists) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.entries.map((e) {
      final item = Map<String, dynamic>.from(e.value);
      item['id'] = e.key;
      return item;
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> listenToInventory() {
    return _db.onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) {
        final item = Map<String, dynamic>.from(e.value);
        item['id'] = e.key;
        return item;
      }).toList();
    });
  }
}
