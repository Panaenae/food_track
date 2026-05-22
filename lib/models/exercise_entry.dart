import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseEntry {
  const ExerciseEntry({
    required this.id,
    required this.name,
    required this.caloriesBurned,
    required this.timestamp,
    this.durationLabel,
    this.category,
    this.intensity,
  });

  final String id;
  final String name;
  final int caloriesBurned;
  final DateTime timestamp;
  final String? durationLabel;
  final String? category;
  final String? intensity;

  factory ExerciseEntry.fromMap(String id, Map<String, dynamic> map) {
    return ExerciseEntry(
      id: id,
      name: map['name'] as String? ?? '',
      caloriesBurned: map['caloriesBurned'] as int? ?? 0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      durationLabel: map['durationLabel'] as String?,
      category: map['category'] as String?,
      intensity: map['intensity'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'caloriesBurned': caloriesBurned,
      'timestamp': Timestamp.fromDate(timestamp),
      'durationLabel': durationLabel,
      'category': category,
      'intensity': intensity,
    };
  }
}
