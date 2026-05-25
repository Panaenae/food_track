class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.calorieGoal = 2200,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.activityLevel,
    this.proteinGoal = 120,
    this.carbsGoal = 250,
    this.fatGoal = 70,
  });

  final String uid;
  final String email;
  final String? displayName;
  final int calorieGoal;
  
  // Fields for TDEE calculation
  final int? age;
  final double? weight; // in kg
  final double? height; // in cm
  final String? gender; // 'male' or 'female'
  final String? activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'veryActive'

  // Macro Goals
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      calorieGoal: (map['calorieGoal'] as num?)?.toInt() ?? 2200,
      age: (map['age'] as num?)?.toInt(),
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      gender: map['gender'] as String?,
      activityLevel: map['activityLevel'] as String?,
      proteinGoal: (map['proteinGoal'] as num?)?.toInt() ?? 120,
      carbsGoal: (map['carbsGoal'] as num?)?.toInt() ?? 250,
      fatGoal: (map['fatGoal'] as num?)?.toInt() ?? 70,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      'calorieGoal': calorieGoal,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activityLevel': activityLevel,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Calculates TDEE based on the Mifflin-St Jeor Equation
  int calculateTDEE() {
    if (age == null || weight == null || height == null || gender == null) {
      return calorieGoal;
    }

    double bmr;
    if (gender == 'male') {
      bmr = (10 * weight!) + (6.25 * height!) - (5 * age!) + 5;
    } else {
      bmr = (10 * weight!) + (6.25 * height!) - (5 * age!) - 161;
    }

    double multiplier = switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'veryActive' => 1.9,
      _ => 1.2,
    };

    return (bmr * multiplier).round();
  }

  /// Calculates recommended macros based on weight and activity level
  Map<String, int> calculateRecommendedMacros(int tdee) {
    if (weight == null) return {'protein': 120, 'carbs': 250, 'fat': 70};

    // 1. Protein Calculation (0.8 to 1.2 g/kg based on activity)
    double proteinMultiplier = switch (activityLevel) {
      'sedentary' => 0.8,
      'light' => 0.9,
      'moderate' => 1.0,
      'active' => 1.1,
      'veryActive' => 1.2,
      _ => 0.8,
    };
    
    int protein = (weight! * proteinMultiplier).round();
    
    // 2. Fat Calculation (Fixed at 25% of total calories)
    // 1g fat = 9 kcal
    int fat = ((tdee * 0.25) / 9).round();
    
    // 3. Carbs Calculation (Remaining calories)
    // 1g protein = 4 kcal, 1g carb = 4 kcal
    int proteinCalories = protein * 4;
    int fatCalories = fat * 9;
    int remainingCalories = tdee - proteinCalories - fatCalories;
    int carbs = (remainingCalories / 4).round();

    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
