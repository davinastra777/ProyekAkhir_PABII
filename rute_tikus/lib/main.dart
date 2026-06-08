import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Rute Tikus',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color.fromARGB(255, 1, 1, 129),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            cardColor: Colors.white,
            dividerColor: Colors.grey[300],
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 1, 1, 129),
              brightness: Brightness.light,
              primary: const Color.fromARGB(255, 1, 1, 129),
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF7986CB),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.grey[800],
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 1, 1, 129),
              brightness: Brightness.dark,
              primary: const Color(0xFF7986CB),
              surface: const Color(0xFF1E1E1E),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}