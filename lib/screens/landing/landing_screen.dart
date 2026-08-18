import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../guest/guest_camera_screen.dart';
import '../home/home_screen.dart';
import '../auth/auth_page.dart';
import '../../services/session_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _selectedMoodIndex = 0;
  Timer? _autoSlideTimer;

  // Updated master mood categories precisely as requested
  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Joyful',
      'bgColor': const Color(0xFFFFC000), // Vibrant Yellow
      'textColor': Colors.black,
      'subMoods': ['Cheerful', 'Joyful', 'Content'],
      'expression': 'happy',
      'wavePhase': 0.0,
    },
    {
      'name': 'Neutral',
      'bgColor': const Color(0xFF2EAD5C), // Rich Organic Green
      'textColor': Colors.white,
      'subMoods': ['Satisfied', 'Neutral', 'Reflective'],
      'expression': 'calm',
      'wavePhase': 1.5,
    },
    {
      'name': 'Sadness',
      'bgColor': const Color(0xFFB079E9), // Lavish Muted Purple
      'textColor': Colors.white,
      'subMoods': ['Melancholy', 'Sadness', 'Disappointed'],
      'expression': 'worried',
      'wavePhase': 3.0,
    },
    {
      'name': 'Angry',
      'bgColor': const Color(0xFFE54A4A), // Deep Premium Red
      'textColor': Colors.white,
      'subMoods': ['Heartbroken', 'Angry', 'Devastated'],
      'expression': 'angry',
      'wavePhase': 4.5,
    }
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the smooth automated cyclic slider mechanism
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(milliseconds:2000),(timer) {
      if (!mounted) return;
      setState(() {
        _selectedMoodIndex = (_selectedMoodIndex + 1) % _moods.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentMood = _moods[_selectedMoodIndex];

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _selectedMoodIndex == 0 ? Brightness.dark : Brightness.light,
      ),
    );

    return PopScope( 
      canPop: false, // Menghalang aplikasi daripada tertutup terus
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        // 🚀 REPAIR: Tolak user balik ke Auth Page menggunakan MaterialPageRoute
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
        );
      },
      child: Scaffold(
        // DIBAIKI: Menggunakan warna Dark Purple premium sebagai warna latar belakang utama
        backgroundColor: const Color(0xFF151221), 
        body: Column(
          children: [
            // 1. TOP ILLUSTRATION AREA (Wavy Canvas + Liquid Fluid Cartoon Character)
            Expanded(
              flex: 12,
              child: AnimatedContainer(
                duration: const Duration(milliseconds:2000),
                curve: Curves.easeInOutCubic,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: currentMood['bgColor'],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(54),
                    bottomRight: Radius.circular(54),
                  ),
                ),
                child: Stack(
                  children: [
                    // Minimal Clean Header Bar (No Save Button)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              
                              ),
                            
                            const SizedBox(width: 48), 
                          ],
                        ),
                      ),
                    ),

                    // Interesting Organic Wavy / Fluid Character Body and Face
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 550),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeInBack,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: CustomPaint(
                          key: ValueKey<int>(_selectedMoodIndex),
                          size: Size(size.width * 0.65, size.height * 0.28),
                          painter: FluidWavyBlobPainter(
                            expression: currentMood['expression'],
                            featureColor: currentMood['textColor'],
                            phase: currentMood['wavePhase'],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. BOTTOM CONTROL DECK (Highlight Camera & Home Trigger)
            Expanded(
              flex: 10,
              child: Container(
                // DIBAIKI: Menggunakan warna Dark Purple yang konsisten dengan background skrin
                color: const Color(0xFF151221),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(height: 5),
                    
                    // Primary Headline Text
                    const Text(
                      "Scan your\nmoods today",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.5,
                    ),
                    ),

                    // Audio Pattern Wave Bar
                    SizedBox(
                      height: 20,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(20, (index) {
                          int middle = 10;
                          double dist = (index - middle).abs().toDouble();
                          double heightFactor = (7 - dist).clamp(1.0, 7.0);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 2,
                            height: 3 + (heightFactor * 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(index == 9 || index == 10 ? 0.9 : 0.2),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Horizontal Selected Smooth Submood Category Scroller
                    SizedBox(
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(currentMood['subMoods'].length, (index) {
                          bool isMain = index == 1; 
                          return AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: isMain ? currentMood['bgColor'] : Colors.white.withOpacity(0.30),
                              fontSize: isMain ? 16 : 13,
                              fontWeight: isMain ? FontWeight.w800 : FontWeight.w500,
     
     
                            ),
                            child: Text(currentMood['subMoods'][index]),
                          );
                        }),
                      ),
                    ),

                    // HIGH-LIGHTED & BIGGER CAMERA TRIGGER BUTTON (Core Element focus)
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          _autoSlideTimer?.cancel(); // Halt auto-slider upon manual click engagement
                          
                          // 🌟 REPAIR DI SINI: Semak status user secara dinamik
                          final user = await SessionService.getUser();
                          final String userId = (user["id"] ?? user["uid"] ?? "").toString().trim();
                          bool loggedIn = userId.isNotEmpty && userId != "null";

                          if (!context.mounted) return;

                          // Ambil kamera depan
                          final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // 🌟 Jika loggedIn = true (maksudnya dah login), isGuest akan dihantar sebagai FALSE
                              builder: (_) => GuestCameraScreen(camera: frontCamera, isGuest: !loggedIn),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Concentric Outer Pulsating/Glowing Ring Indicator for layout depth
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 104,
                              width: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (currentMood['bgColor'] as Color).withOpacity(0.12),
                              ),
                            ),
                            
                            // Massive High-fidelity Central Active Button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 86, // Expanded size to completely stand out
                              width: 86,
                              decoration: BoxDecoration(
                                color: currentMood['bgColor'],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (currentMood['bgColor'] as Color).withOpacity(0.4),
                                    blurRadius: 22,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: currentMood['textColor'],
                                size: 38, // Amplified icon presence
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Enter Home Trigger Button placed exactly underneath the layout
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          _autoSlideTimer?.cancel();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC000),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                          ),
                          child: const Center(
                            child: Text(
                              "Enter Home",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ), // Penutup Scaffold
    ); // Penutup PopScope
  }
}

// Custom Painter implementing advanced Fluid/Wavy Bezier curve interpolation to build exciting organic structures
class FluidWavyBlobPainter extends CustomPainter {
  final String expression;
  final Color featureColor;
  final double phase;

  FluidWavyBlobPainter({
    required this.expression,
    required this.featureColor,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final baseRadius = size.width * 0.42;

    final blobPaint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final featurePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    // Constructing a fluid, interesting dynamic wavy body shape instead of simple primitives
    final path = Path();
    
    // Smooth custom fluid math simulation mapping 8 control anchor spline points
    Offset p1 = Offset(center.dx - baseRadius * 0.9, center.dy - baseRadius * 0.7);
    Offset p2 = Offset(center.dx, center.dy - baseRadius * 1.1);
    Offset p3 = Offset(center.dx + baseRadius * 1.0, center.dy - baseRadius * 0.6);
    Offset p4 = Offset(center.dx + baseRadius * 1.1, center.dy + baseRadius * 0.4);
    Offset p5 = Offset(center.dx + baseRadius * 0.6, center.dy + baseRadius * 0.9);
    Offset p6 = Offset(center.dx - baseRadius * 0.5, center.dy + baseRadius * 1.0);
    Offset p7 = Offset(center.dx - baseRadius * 1.1, center.dy + baseRadius * 0.5);

    path.moveTo(p1.dx, p1.dy);
    path.cubicTo(p1.dx + 20, p1.dy - 30, p2.dx - 40, p2.dy, p2.dx, p2.dy);
    path.cubicTo(p2.dx + 40, p2.dy, p3.dx - 20, p3.dy - 20, p3.dx, p3.dy);
    path.cubicTo(p3.dx + 20, p3.dy + 20, p4.dx, p4.dy - 30, p4.dx, p4.dy);
    path.cubicTo(p4.dx, p4.dy + 30, p5.dx + 20, p5.dy, p5.dx, p5.dy);
    path.cubicTo(p5.dx - 20, p5.dy, p6.dx + 20, p6.dy, p6.dx, p6.dy);
    path.cubicTo(p6.dx - 20, p6.dy, p7.dx, p7.dy + 20, p7.dx, p7.dy);
    path.cubicTo(p7.dx, p7.dy - 20, p1.dx - 20, p1.dy + 20, p1.dx, p1.dy);
    path.close();

    canvas.drawPath(path, blobPaint);

    // Render precise facial emotion mechanics over the active fluid organic body
    if (expression == 'happy') {
      canvas.drawCircle(Offset(center.dx - 24, center.dy - 12), 7.5, featurePaint);
      canvas.drawCircle(Offset(center.dx + 24, center.dy - 12), 7.5, featurePaint);

      final smilePath = Path()
        ..moveTo(center.dx - 28, center.dy + 12)
        ..quadraticBezierTo(center.dx, center.dy + 48, center.dx + 28, center.dy + 12)
        ..quadraticBezierTo(center.dx, center.dy + 20, center.dx - 28, center.dy + 12);
      canvas.drawPath(smilePath, featurePaint);
    } 
    else if (expression == 'calm') {
      canvas.drawArc(Rect.fromLTWH(center.dx - 34, center.dy - 22, 24, 18), 3.14, 3.14, false, strokePaint);
      canvas.drawArc(Rect.fromLTWH(center.dx + 10, center.dy - 22, 24, 18), 3.14, 3.14, false, strokePaint);

      final calmMouth = Path()
        ..moveTo(center.dx - 20, center.dy + 18)
        ..quadraticBezierTo(center.dx, center.dy + 28, center.dx + 20, center.dy + 18);
      canvas.drawPath(calmMouth, strokePaint);
    } 
    else if (expression == 'worried') {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - 28, center.dy - 18, 13, 20), const Radius.circular(8)), featurePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx + 15, center.dy - 18, 13, 20), const Radius.circular(8)), featurePaint);

      final worriedMouth = Path()
        ..moveTo(center.dx - 18, center.dy + 20)
        ..quadraticBezierTo(center.dx - 9, center.dy + 15, center.dx, center.dy + 20)
        ..quadraticBezierTo(center.dx + 9, center.dy + 25, center.dx + 18, center.dy + 20);
      canvas.drawPath(worriedMouth, strokePaint);
    } 
    else if (expression == 'angry') {
      // Inward furious slanted eyebrows
      canvas.drawLine(Offset(center.dx - 36, center.dy - 30), Offset(center.dx - 12, center.dy - 18), strokePaint);
      canvas.drawLine(Offset(center.dx + 36, center.dy - 30), Offset(center.dx + 12, center.dy - 18), strokePaint);

      canvas.drawCircle(Offset(center.dx - 22, center.dy - 6), 8.5, featurePaint);
      canvas.drawCircle(Offset(center.dx + 22, center.dy - 6), 8.5, featurePaint);

      final angryMouth = Path()
        ..moveTo(center.dx - 22, center.dy + 24)
        ..quadraticBezierTo(center.dx, center.dy + 10, center.dx + 22, center.dy + 24);
      canvas.drawPath(angryMouth, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FluidWavyBlobPainter oldDelegate) {
    return oldDelegate.expression != expression || 
           oldDelegate.featureColor != featureColor || 
           oldDelegate.phase != phase;
  }
}