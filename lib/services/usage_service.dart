import 'package:cloud_firestore/cloud_firestore.dart';

class UsageService {
  final _usageRef = FirebaseFirestore.instance.collection('usage_logs');

  Future<double> getTodayUsage(String hotelId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final snapshot = await _usageRef
        .where('hotelId', isEqualTo: hotelId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    return snapshot.docs.fold<double>(0.0, (double sum, doc) {
      return sum + (doc['amount'] as num).toDouble();
    });
  }

  Future<void> saveTodayUsage(String userId, double todayUsage) async {}
}
