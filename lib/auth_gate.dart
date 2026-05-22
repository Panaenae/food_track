import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_track/login_page.dart';
import 'package:food_track/main_shell.dart';
import 'package:food_track/services/auth_service.dart';
import 'package:food_track/services/user_profile_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    AuthService? authService,
    UserProfileService? profileService,
  })  : _authService = authService,
        _profileService = profileService;

  final AuthService? _authService;
  final UserProfileService? _profileService;

  @override
  Widget build(BuildContext context) {
    final auth = _authService ?? AuthService();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginPage(
            authService: _authService,
            profileService: _profileService,
          );
        }

        return _SignedInGate(
          user: user,
          profileService: _profileService,
        );
      },
    );
  }
}

class _SignedInGate extends StatefulWidget {
  const _SignedInGate({
    required this.user,
    UserProfileService? profileService,
  }) : _profileService = profileService;

  final User user;
  final UserProfileService? _profileService;

  @override
  State<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<_SignedInGate> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepareProfile();
  }

  Future<void> _prepareProfile() async {
    try {
      final profiles = widget._profileService ?? UserProfileService();
      await profiles.ensureProfileForUser(widget.user);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not load your profile. Check Firestore.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const MainShell();
  }
}
