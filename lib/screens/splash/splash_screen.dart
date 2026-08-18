import 'dart:ui'; // Diperlukan untuk kesan ImageFilter.blur
import 'package:flutter/material.dart';
import '../auth/auth_page.dart'; // Import ke AuthPage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Dikosongkan supaya tidak berpindah halaman secara automatik
  }

  // FUNGSI NAVIGASI: Dipanggil apabila skrin atau logo diketuk
  void _navigateToNextPage() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dibungkus dengan GestureDetector supaya seluruh kawasan skrin boleh diketuk
      body: GestureDetector(
        onTap: _navigateToNextPage,
        behavior: HitTestBehavior.opaque, // Memastikan kawasan kosong pun boleh menerima ketukan
        child: Stack(
          children: [
            // 1. GAMBAR LATAR BELAKANG (bg03.jpg)
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg03.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFF1E192E)); 
                },
              ),
            ),

            // 2. KESAN BLUR LEMBUT & LAPISAN GELAP
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Container(
                  color: Colors.black.withOpacity(0.25), 
                ),
              ),
            ),

            // 3. LOGO DI TENGAH SKRIN
            Center(
              child: Hero(
                tag: 'app_logo', 
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 140,
                  height: 140,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.face_retouching_natural, size: 80, color: Colors.white);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}