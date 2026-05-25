import 'package:flutter/material.dart';
import 'package:food_track/models/user_profile.dart';
import 'package:food_track/services/user_profile_service.dart';

class GoalCalculatorPage extends StatefulWidget {
  const GoalCalculatorPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<GoalCalculatorPage> createState() => _GoalCalculatorPageState();
}

class _GoalCalculatorPageState extends State<GoalCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  
  String _gender = 'male';
  String _activityLevel = 'sedentary';
  int? _calculatedTdee;
  Map<String, int>? _calculatedMacros;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.profile.age?.toString());
    _weightController = TextEditingController(text: widget.profile.weight?.toString());
    _heightController = TextEditingController(text: widget.profile.height?.toString());
    _gender = widget.profile.gender ?? 'male';
    _activityLevel = widget.profile.activityLevel ?? 'sedentary';
    _calculateLocal();
  }

  void _calculateLocal() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age != null && weight != null && height != null) {
      final tempProfile = UserProfile(
        uid: widget.profile.uid,
        email: widget.profile.email,
        age: age,
        weight: weight,
        height: height,
        gender: _gender,
        activityLevel: _activityLevel,
      );
      final tdee = tempProfile.calculateTDEE();
      setState(() {
        _calculatedTdee = tdee;
        _calculatedMacros = tempProfile.calculateRecommendedMacros(tdee);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Calculator')),
      body: Form(
        key: _formKey,
        onChanged: _calculateLocal,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Calculate your maintenance calories (TDEE) and macro targets based on your profile.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'male', label: Text('Male'), icon: Icon(Icons.male)),
                ButtonSegment(value: 'female', label: Text('Female'), icon: Icon(Icons.female)),
              ],
              selected: {_gender},
              onSelectionChanged: (val) => setState(() {
                _gender = val.first;
                _calculateLocal();
              }),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age', suffixText: 'yrs', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight', suffixText: 'kg', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Height', suffixText: 'cm', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            Text('Activity Level', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _ActivityOption(
              value: 'sedentary',
              title: 'Sedentary',
              subtitle: 'Office job, little exercise (0.8g protein/kg)',
              groupValue: _activityLevel,
              onChanged: (v) => setState(() { _activityLevel = v!; _calculateLocal(); }),
            ),
            _ActivityOption(
              value: 'light',
              title: 'Lightly Active',
              subtitle: 'Exercise 1-3 days/week (0.9g protein/kg)',
              groupValue: _activityLevel,
              onChanged: (v) => setState(() { _activityLevel = v!; _calculateLocal(); }),
            ),
            _ActivityOption(
              value: 'moderate',
              title: 'Moderately Active',
              subtitle: 'Exercise 3-5 days/week (1.0g protein/kg)',
              groupValue: _activityLevel,
              onChanged: (v) => setState(() { _activityLevel = v!; _calculateLocal(); }),
            ),
            _ActivityOption(
              value: 'active',
              title: 'Very Active',
              subtitle: 'Hard exercise 6-7 days/week (1.1g protein/kg)',
              groupValue: _activityLevel,
              onChanged: (v) => setState(() { _activityLevel = v!; _calculateLocal(); }),
            ),

            const SizedBox(height: 32),
            if (_calculatedTdee != null && _calculatedMacros != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('Daily Targets', style: theme.textTheme.labelLarge),
                    Text('$_calculatedTdee kcal', style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    )),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MacroSummary(label: 'Protein', value: _calculatedMacros!['protein']!, unit: 'g'),
                        _MacroSummary(label: 'Carbs', value: _calculatedMacros!['carbs']!, unit: 'g'),
                        _MacroSummary(label: 'Fat', value: _calculatedMacros!['fat']!, unit: 'g'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveAndClose,
                        child: const Text('Apply Goals to Profile'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndClose() async {
    if (!_formKey.currentState!.validate()) return;
    if (_calculatedTdee == null || _calculatedMacros == null) return;

    final updatedProfile = UserProfile(
      uid: widget.profile.uid,
      email: widget.profile.email,
      calorieGoal: _calculatedTdee!,
      proteinGoal: _calculatedMacros!['protein']!,
      carbsGoal: _calculatedMacros!['carbs']!,
      fatGoal: _calculatedMacros!['fat']!,
      age: int.parse(_ageController.text),
      weight: double.parse(_weightController.text),
      height: double.parse(_heightController.text),
      gender: _gender,
      activityLevel: _activityLevel,
    );

    await UserProfileService().updateProfile(updatedProfile);
    if (mounted) Navigator.pop(context);
  }
}

class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.label, required this.value, required this.unit});
  final String label;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text('$value$unit', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ActivityOption extends StatelessWidget {
  const _ActivityOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.groupValue,
    required this.onChanged,
  });

  final String value;
  final String title;
  final String subtitle;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }
}
