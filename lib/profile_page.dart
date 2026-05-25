import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_track/goal_calculator_page.dart';
import 'package:food_track/models/user_profile.dart';
import 'package:food_track/services/auth_service.dart';
import 'package:food_track/services/user_profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    AuthService? authService,
    UserProfileService? profileService,
  })  : _authService = authService,
        _profileService = profileService;

  final AuthService? _authService;
  final UserProfileService? _profileService;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _goalController = TextEditingController();
  final _goalFocusNode = FocusNode(); // Added: Tracks if the user is typing
  bool _isSaving = false;
  String? _message;

  AuthService get _auth => widget._authService ?? AuthService();
  UserProfileService get _profiles =>
      widget._profileService ?? UserProfileService();

  @override
  void dispose() {
    _goalController.dispose();
    _goalFocusNode.dispose(); // Added: Clean up the focus node
    super.dispose();
  }

  Future<void> _saveGoal(String uid) async {
    final parsed = int.tryParse(_goalController.text.trim());
    if (parsed == null || parsed < 500 || parsed > 10000) {
      setState(() => _message = 'Enter a goal between 500 and 10000 kcal.');
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await _profiles.updateCalorieGoal(uid, parsed);
      if (mounted) {
        setState(() => _message = 'Saved!');
        _goalFocusNode.unfocus(); // Close keyboard after saving
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Could not save. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: _profiles.profileStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = snapshot.data;
            
            // SYNC LOGIC: 
            // If we have data, and the user is NOT currently typing, 
            // update the controller to match the database.
            if (profile != null && !_goalFocusNode.hasFocus) {
              final goalStr = profile.calorieGoal.toString();
              if (_goalController.text != goalStr) {
                _goalController.text = goalStr;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Profile',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.displayName ?? 'Your account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email ?? user.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Daily calorie goal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _goalController,
                    focusNode: _goalFocusNode, // Connect the focus node
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories (kcal)',
                      border: OutlineInputBorder(),
                      suffixText: 'kcal',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : () => _saveGoal(user.uid),
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save goal manually'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: profile == null ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GoalCalculatorPage(profile: profile)),
                      );
                    },
                    icon: const Icon(Icons.calculate_rounded),
                    label: const Text('Help me calculate my goal'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _message == 'Saved!'
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
