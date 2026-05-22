import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_track/auth_gate.dart';
import 'package:food_track/firebase_options.dart';
import 'package:food_track/firebase_setup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(FoodTrackApp(firebaseReady: firebaseReady));
}

class FoodTrackApp extends StatelessWidget {
  const FoodTrackApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0D9488);

    return MaterialApp(
      title: 'Food Track',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: firebaseReady ? const AuthGate() : const FirebaseSetupPage(),
    );
  }
}
