import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_track/models/food_entry.dart';
import 'package:food_track/services/diary_service.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  DateTime _selectedDate = DateTime.now();
  final DiaryService _diaryService = DiaryService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Food Diary', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surfaceContainerLowest,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: StreamBuilder<List<FoodEntry>>(
        stream: _diaryService.getDailyEntries(user.uid, _selectedDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];
          final groupedEntries = _groupEntries(entries);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _DateSelector(
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                _buildEmptyState(theme)
              else ...[
                ...groupedEntries.entries.map((group) {
                  return _MealSection(
                    mealType: group.key,
                    entries: group.value,
                    onDelete: (entryId) => _diaryService.deleteFoodEntry(user.uid, entryId),
                  );
                }),
              ],
              const SizedBox(height: 80), // Space for FAB
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food_outlined, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No entries for this day',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _selectDate(context),
            child: const Text('Pick another date'),
          ),
        ],
      ),
    );
  }

  Map<String, List<FoodEntry>> _groupEntries(List<FoodEntry> entries) {
    final Map<String, List<FoodEntry>> groups = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snack': [],
    };

    for (var entry in entries) {
      final type = entry.mealType ?? 'Snack';
      if (groups.containsKey(type)) {
        groups[type]!.add(entry);
      } else {
        groups['Snack']!.add(entry);
      }
    }
    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.selectedDate, required this.onDateSelected});
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(selectedDate, DateTime.now());
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => onDateSelected(selectedDate.subtract(const Duration(days: 1))),
        ),
        Text(
          isToday ? 'Today' : '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: isToday ? null : () => onDateSelected(selectedDate.add(const Duration(days: 1))),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({required this.mealType, required this.entries, required this.onDelete});
  final String mealType;
  final List<FoodEntry> entries;
  final Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCals = entries.fold(0, (sum, e) => sum + e.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mealType,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              Text(
                '$totalCals kcal',
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        ...entries.map((entry) => _DiaryEntryTile(entry: entry, onDelete: () => onDelete(entry.id))),
        const Divider(height: 32),
      ],
    );
  }
}

class _DiaryEntryTile extends StatelessWidget {
  const _DiaryEntryTile({required this.entry, required this.onDelete});
  final FoodEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: entry.protein != null 
            ? Text('${entry.protein}P · ${entry.carbs}C · ${entry.fat}F')
            : null,
          trailing: Text('${entry.calories} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
