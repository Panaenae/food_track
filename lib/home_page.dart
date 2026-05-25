import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_track/main_shell.dart';
import 'package:food_track/models/food_entry.dart';
import 'package:food_track/models/exercise_entry.dart';
import 'package:food_track/models/user_profile.dart';
import 'package:food_track/services/diary_service.dart';
import 'package:food_track/services/user_profile_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final diaryService = DiaryService();
    final today = DateTime.now();
    final mainShell = MainShell.of(context);

    return StreamBuilder<UserProfile?>(
      stream: UserProfileService().profileStream(user.uid),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final calorieGoal = profile?.calorieGoal ?? 2000;

        return StreamBuilder<List<FoodEntry>>(
          stream: diaryService.getDailyEntries(user.uid, today),
          builder: (context, foodSnapshot) {
            final foodEntries = foodSnapshot.data ?? [];
            final caloriesEaten = foodEntries.fold<int>(
              0,
              (sum, entry) => sum + entry.calories,
            );

            return StreamBuilder<List<ExerciseEntry>>(
              stream: diaryService.getDailyExerciseEntries(user.uid, today),
              builder: (context, exerciseSnapshot) {
                final exerciseEntries = exerciseSnapshot.data ?? [];
                final caloriesBurned = exerciseEntries.fold<int>(
                  0,
                  (sum, entry) => sum + entry.caloriesBurned,
                );

                final remaining = calorieGoal - caloriesEaten + caloriesBurned;
                final progress = (caloriesEaten / calorieGoal).clamp(0.0, 1.0);

                // Combine and sort recent activity
                final List<dynamic> allActivity = [...foodEntries, ...exerciseEntries];
                allActivity.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return Scaffold(
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  body: SafeArea(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: _Header(
                              theme: theme,
                              displayName: profile?.displayName,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _CalorieSummaryCard(
                              goal: calorieGoal,
                              eaten: caloriesEaten,
                              burned: caloriesBurned,
                              remaining: remaining,
                              progress: progress,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Text(
                              'Quick actions',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.restaurant_menu_rounded,
                                    label: 'Log food',
                                    subtitle: 'Meals & snacks',
                                    color: colorScheme.primary,
                                    onTap: () {
                                      mainShell?.setIndex(3, libraryTab: 0);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.directions_run_rounded,
                                    label: 'Log exercise',
                                    subtitle: 'Workouts & steps',
                                    color: colorScheme.tertiary,
                                    onTap: () {
                                      mainShell?.setIndex(3, libraryTab: 1);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Text(
                              'Macros today',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _MacroRow(
                              protein: foodEntries.fold(0, (s, e) => s + (e.protein ?? 0)),
                              proteinGoal: profile?.proteinGoal ?? 120,
                              carbs: foodEntries.fold(0, (s, e) => s + (e.carbs ?? 0)),
                              carbsGoal: profile?.carbsGoal ?? 250,
                              fat: foodEntries.fold(0, (s, e) => s + (e.fat ?? 0)),
                              fatGoal: profile?.fatGoal ?? 70,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Today\'s activity',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    mainShell?.setIndex(1);
                                  },
                                  child: const Text('See all'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: allActivity.isEmpty
                                ? Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text(
                                        'No activity yet today. Log your first meal or exercise!',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: allActivity.take(5).map((activity) {
                                      final bool isExercise = activity is ExerciseEntry;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _ActivityTile(
                                          icon: isExercise ? Icons.fitness_center_rounded : Icons.restaurant_rounded,
                                          iconColor: isExercise ? colorScheme.tertiary : colorScheme.primary,
                                          title: activity.name,
                                          subtitle: isExercise ? activity.durationLabel ?? 'Workout' : activity.mealType ?? 'Meal',
                                          calories: isExercise ? activity.caloriesBurned : activity.calories,
                                          time: '${activity.timestamp.hour}:${activity.timestamp.minute.toString().padLeft(2, '0')}',
                                          isExercise: isExercise,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme, this.displayName});

  final ThemeData theme;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = _weekdayName(now.weekday);
    final date = '$weekday, ${now.month}/${now.day}';

    final greetingText = displayName != null
        ? '${_greeting(now.hour)}, $displayName'
        : _greeting(now.hour);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }
}

class _CalorieSummaryCard extends StatelessWidget {
  const _CalorieSummaryCard({
    required this.goal,
    required this.eaten,
    required this.burned,
    required this.remaining,
    required this.progress,
  });

  final int goal;
  final int eaten;
  final int burned;
  final int remaining;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor:
                              colorScheme.surface.withValues(alpha: 0.8),
                          color: colorScheme.primary,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$remaining',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            'remaining',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily calories',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Goal $goal kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StatLine(
                        label: 'Eaten',
                        value: eaten,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      _StatLine(
                        label: 'Burned',
                        value: burned,
                        color: colorScheme.tertiary,
                        prefix: '+',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
    required this.color,
    this.prefix = '',
  });

  final String label;
  final int value;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          '$prefix$value kcal',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.protein,
    required this.proteinGoal,
    required this.carbs,
    required this.carbsGoal,
    required this.fat,
    required this.fatGoal,
  });

  final int protein;
  final int proteinGoal;
  final int carbs;
  final int carbsGoal;
  final int fat;
  final int fatGoal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroCard(
            label: 'Protein',
            current: protein,
            goal: proteinGoal,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            label: 'Carbs',
            current: carbs,
            goal: carbsGoal,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            label: 'Fat',
            current: fat,
            goal: fatGoal,
            color: const Color(0xFFEC4899),
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  final String label;
  final int current;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (current / goal).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${current}g',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '/ ${goal}g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.15),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.calories,
    required this.time,
    this.isExercise = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int calories;
  final String time;
  final bool isExercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayCalories =
        isExercise ? '$calories' : '+$calories';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$displayCalories kcal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isExercise
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
              ),
            ),
            Text(
              time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
