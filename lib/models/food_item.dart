class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.servingLabel,
    this.category,
    this.protein,
    this.carbs,
    this.fat,
  });

  final String id;
  final String name;
  final int calories;
  final String servingLabel;
  final String? category;
  final int? protein;
  final int? carbs;
  final int? fat;
}
