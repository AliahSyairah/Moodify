import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'screens/splash/splash_screen.dart';
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);

late List<CameraDescription> cameras;

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  cameras = await availableCameras();

  runApp(const MoodifyApp());
}

class MoodifyApp extends StatelessWidget {
  const MoodifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Moodify',
          theme: ThemeData(
            fontFamily: 'Poppins',
            // Menukar warna latar belakang asas MaterialApp mengikut status tema
            scaffoldBackgroundColor: isDarkMode ? const Color(0xFF151221) : const Color(0xFFFFFDD0),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}