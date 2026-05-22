class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.calorieGoal = 2200,
  });

  final String uid;
  final String email;
  final String? displayName;
  final int calorieGoal;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      calorieGoal: (map['calorieGoal'] as num?)?.toInt() ?? 2200,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      'calorieGoal': calorieGoal,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
