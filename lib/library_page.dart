import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_track/data/sample_library.dart';
import 'package:food_track/models/exercise_entry.dart';
import 'package:food_track/models/exercise_item.dart';
import 'package:food_track/models/food_entry.dart';
import 'package:food_track/models/food_item.dart';
import 'package:food_track/services/diary_service.dart';
import 'package:food_track/services/food_api_service.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FoodApiService _apiService = FoodApiService();
  
  String _query = '';
  List<FoodItem> _apiResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure the index is within bounds (0 or 1)
    final index = (widget.initialTab >= 0 && widget.initialTab < 2) 
        ? widget.initialTab 
        : 0;
        
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: index
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // This handles the "Real Database" search
  Future<void> _performSearch(String value) async {
    if (_tabController == null) return;

    setState(() {
      _query = value;
      _isLoading = true;
    });

    if (_tabController!.index == 0) {
      // Searching Foods via API
      final results = await _apiService.searchFoods(value);
      if (mounted) {
        setState(() {
          _apiResults = results;
          _isLoading = false;
        });
      }
    } else {
      // Searching Exercises (still local for now)
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ExerciseItem> get _filteredExercises {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sampleExercises;
    return sampleExercises.where((item) {
      return item.name.toLowerCase().contains(q) ||
          (item.category?.toLowerCase().contains(q) ?? false) ||
          (item.intensity?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Safety check: if for some reason initState failed
    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Library',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search foods or exercises',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: () => _performSearch(_searchController.text),
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(text: 'Foods'),
                Tab(text: 'Exercises'),
              ],
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController!,
                    children: [
                      _FoodList(
                        items: _query.isEmpty ? sampleFoods : _apiResults,
                        onTap: (item) => _showFoodDetail(context, item),
                      ),
                      _ExerciseList(
                        items: _filteredExercises,
                        onTap: (item) => _showExerciseDetail(context, item),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetail(BuildContext context, FoodItem item) {
    final theme = Theme.of(context);
    String selectedMealType = 'Breakfast';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.category!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      '${item.calories} kcal',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per ${item.servingLabel}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Select Meal Type',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                        final isSelected = selectedMealType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => selectedMealType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final entry = FoodEntry(
                              id: '', // Firestore will generate this
                              name: item.name,
                              calories: item.calories,
                              timestamp: DateTime.now(),
                              mealType: selectedMealType,
                              protein: item.protein,
                              carbs: item.carbs,
                              fat: item.fat,
                            );
                            await DiaryService().addFoodEntry(user.uid, entry);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added ${item.name} to $selectedMealType')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add to Diary'),
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
  }

  void _showExerciseDetail(BuildContext context, ExerciseItem item) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.category != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${item.category}${item.intensity != null ? ' · ${item.intensity}' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  '${item.caloriesBurned} kcal burned',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.durationLabel,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                    ),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final entry = ExerciseEntry(
                          id: '', // Firestore will generate this
                          name: item.name,
                          caloriesBurned: item.caloriesBurned,
                          timestamp: DateTime.now(),
                          durationLabel: item.durationLabel,
                          category: item.category,
                          intensity: item.intensity,
                        );
                        await DiaryService().addExerciseEntry(user.uid, entry);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logged ${item.name}'),
                              backgroundColor: theme.colorScheme.tertiary,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log Exercise'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FoodList extends StatelessWidget {
  const _FoodList({
    required this.items,
    required this.onTap,
  });

  final List<FoodItem> items;
  final void Function(FoodItem item) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySearch(message: 'No foods match your search.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _LibraryListTile(
          title: item.name,
          subtitle: item.servingLabel,
          trailing: '${item.calories} kcal',
          icon: Icons.restaurant_rounded,
          onTap: () => onTap(item),
        );
      },
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({
    required this.items,
    required this.onTap,
  });

  final List<ExerciseItem> items;
  final void Function(ExerciseItem item) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySearch(message: 'No exercises match your search.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _LibraryListTile(
          title: item.name,
          subtitle: item.durationLabel,
          trailing: '${item.caloriesBurned} kcal',
          icon: Icons.fitness_center_rounded,
          isExercise: true,
          onTap: () => onTap(item),
        );
      },
    );
  }
}

class _LibraryListTile extends StatelessWidget {
  const _LibraryListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.onTap,
    this.isExercise = false,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final VoidCallback onTap;
  final bool isExercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent =
        isExercise ? colorScheme.tertiary : colorScheme.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          trailing,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
