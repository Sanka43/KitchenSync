import 'package:cloud_firestore/cloud_firestore.dart';

class UsageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save today's usage for the current user
  Future<void> saveTodayUsage(String userId, double usage) async {
    final today = DateTime.now();
    final dateString =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      await _firestore
          .collection('usage')
          .doc(userId)
          .collection('daily_usage')
          .doc(dateString)
          .set({'usage': usage, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print('⚠️ Error saving today\'s usage: $e');
      rethrow;
    }
  }

  /// Get today's usage for the current user
  Future<double> getTodayUsage(String userId) async {
    final today = DateTime.now();
    final dateString =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final doc = await _firestore
          .collection('usage')
          .doc(userId)
          .collection('daily_usage')
          .doc(dateString)
          .get();

      if (doc.exists && doc.data() != null) {
        return (doc.data()!['usage'] ?? 0).toDouble();
      } else {
        return 0.0;
      }
    } catch (e) {
      print('⚠️ Error getting today\'s usage: $e');
      return 0.0;
    }
  }
}
