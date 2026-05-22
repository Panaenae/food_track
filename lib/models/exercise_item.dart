class ExerciseItem {
  const ExerciseItem({
    required this.id,
    required this.name,
    required this.caloriesBurned,
    required this.durationLabel,
    this.category,
    this.intensity,
  });

  final String id;
  final String name;
  final int caloriesBurned;
  final String durationLabel;
  final String? category;
  final String? intensity;
}
