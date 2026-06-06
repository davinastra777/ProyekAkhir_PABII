import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rute_tikus/screens/sign_in_screen.dart';
import 'firebase_options.dart';

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
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 1, 1, 129),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color.fromARGB(255, 1, 1, 129),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 1, 1, 129),
              brightness: Brightness.dark,
            ),
          ),
          home: const SignInScreen(),
        );
      },
    );
  }
}