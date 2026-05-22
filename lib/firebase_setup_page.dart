import 'package:flutter/material.dart';

class FirebaseSetupPage extends StatelessWidget {
  const FirebaseSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase setup required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Food Track needs Firebase before sign-in and cloud save work. '
                'Follow FIREBASE_SETUP.md in the project folder.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _Step(
                number: '1',
                text: 'console.firebase.google.com → Add project (create project first)',
              ),
              _Step(
                number: '2',
                text: 'Left menu: Authentication → Sign-in method → enable Email/Password',
              ),
              _Step(
                number: '3',
                text: 'Left menu: Firestore Database → Create database',
              ),
              _Step(
                number: '4',
                text: 'Project settings (gear) → Your apps → Add Android app, package com.example.food_track',
              ),
              _Step(
                number: '5',
                text: 'Download google-services.json → android/app/google-services.json',
              ),
              _Step(
                number: '6',
                text: 'Run: dart pub global activate flutterfire_cli',
              ),
              _Step(
                number: '7',
                text: 'Run: flutterfire configure (generates lib/firebase_options.dart)',
              ),
              _Step(
                number: '8',
                text: 'Hot restart the app',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(number, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
