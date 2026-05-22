import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_track/models/food_entry.dart';
import 'package:food_track/models/exercise_entry.dart';

class DiaryService {
  DiaryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _diaryCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('diary');

  CollectionReference<Map<String, dynamic>> _exerciseCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('exercises');

  // Food Entries
  Future<void> addFoodEntry(String uid, FoodEntry entry) async {
    await _diaryCollection(uid).add(entry.toMap());
  }

  Future<void> deleteFoodEntry(String uid, String entryId) async {
    await _diaryCollection(uid).doc(entryId).delete();
  }

  Stream<List<FoodEntry>> getDailyEntries(String uid, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _diaryCollection(uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FoodEntry.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Exercise Entries
  Future<void> addExerciseEntry(String uid, ExerciseEntry entry) async {
    await _exerciseCollection(uid).add(entry.toMap());
  }

  Future<void> deleteExerciseEntry(String uid, String entryId) async {
    await _exerciseCollection(uid).doc(entryId).delete();
  }

  Stream<List<ExerciseEntry>> getDailyExerciseEntries(String uid, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _exerciseCollection(uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExerciseEntry.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
