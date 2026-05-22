import 'package:cloud_firestore/cloud_firestore.dart';

class FoodEntry {
  const FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.timestamp,
    this.mealType,
    this.protein,
    this.carbs,
    this.fat,
  });

  final String id;
  final String name;
  final int calories;
  final DateTime timestamp;
  final String? mealType; // e.g., 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final int? protein;
  final int? carbs;
  final int? fat;

  factory FoodEntry.fromMap(String id, Map<String, dynamic> map) {
    return FoodEntry(
      id: id,
      name: map['name'] as String? ?? '',
      calories: map['calories'] as int? ?? 0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      mealType: map['mealType'] as String?,
      protein: map['protein'] as int?,
      carbs: map['carbs'] as int?,
      fat: map['fat'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'timestamp': Timestamp.fromDate(timestamp),
      'mealType': mealType,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
