import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_track/firebase_setup_page.dart';
import 'package:food_track/login_page.dart';
import 'package:food_track/main.dart';

void main() {
  testWidgets('App shows Firebase setup when init failed', (tester) async {
    await tester.pumpWidget(const FoodTrackApp(firebaseReady: false));

    expect(find.text('Firebase setup required'), findsOneWidget);
  });

  testWidgets('Login page shows sign in form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage()),
    );

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
  });
}
