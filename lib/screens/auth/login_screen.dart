import 'dart:ui'; // Diperlukan untuk ImageFilter.blur
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/session_service.dart';
import '../landing/landing_screen.dart';
import '../auth/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  // Tracking Ralat Input
  String? emailError;
  String? passwordError;

  // Focus Nodes untuk mengesan status menaip kata laluan (animasi tangan)
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordFocused = false;

  // Palet Warna Komponen Premium
  static const Color themeYellow = Color(0xFFF9BA36);      
  static const Color themePurpleCard = Color(0xFF1E192E);  
  static const Color inputPurpleTint = Color(0xFF2A233D);  

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isPasswordFocused = _passwordFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool validateInputs() {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    bool isValid = true;

    if (!emailController.text.contains("@") || !emailController.text.contains(".")) {
      emailError = "Enter a valid email address";
      isValid = false;
    }

    if (passwordController.text.isEmpty) {
      passwordError = "Password cannot be empty";
      isValid = false;
    }

    return isValid;
  }

  Future<void> _login() async {
    if (!validateInputs()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(themeYellow),
        ),
      ),
    );

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = doc.data();

        // 1. Simpan data user seperti biasa
        await SessionService.saveUser(
          user.uid,
          userData?['username'] ?? '',
          user.email ?? '',
        );

        // 🔥 2. TAMBAH BARIS INI UNTUK UPDATE / BERSIHKAN GAMBAR PROFIL LAMA
        // Jika user baharu tidak mempunyai imej (empty string), ia akan overwriting data cache yang lama!
        await SessionService.saveProfileImage(userData?['profile_image'] ?? '');

        if (!mounted) return;
        Navigator.pop(context); // Tutup loading

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // ... kod catch ralat anda yang seterusnya (kekal sama)
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      } else if (e.code == 'invalid-email') {
        message = "The email address is badly formatted";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: themePurpleCard,
        resizeToAvoidBottomInset: true, 
        body: Stack(
          children: [
            // 1. BACKGROUND IMAGE
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg03.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: themePurpleCard);
                },
              ),
            ),

            // 2. KESAN BLUR LEMBUT
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.8, sigmaY: 1.8),
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),

            // 3. LOGO & TEKS MOODIFY (MENGGUNAKAN DESIGN & FONT SAMA SEPERTI AUTH PAGE)
            Positioned(
              top: screenHeight * 0.03,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 90, 
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.blur_circular_rounded, color: Colors.white, size: 52);
                        },
                      ),
                    ),
                    const SizedBox(height: 16), // Jarak diselaraskan dengan AuthPage
                    const Text(
                      "MOODify",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,            // Sama seperti Auth Page
                        fontWeight: FontWeight.bold, // Sama seperti Auth Page
                        letterSpacing: 2,         // Sama seperti Auth Page
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. KANDUNGAN UTAMA: KAD DI TENGAH HALAMAN
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 150, 24, 24),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        
                        // KAD UNGU GELAP TERAPUNG
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: themePurpleCard,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 50, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // DIBAIKI: Kesilapan taip dibetulkan di sini
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Center(
                                child: Text(
                                  "Welcome Back!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Input E-mel
                              _buildVisualInputField(
                                controller: emailController,
                                focusNode: _emailFocusNode,
                                hint: "Email address",
                                keyboardType: TextInputType.emailAddress,
                                errorText: emailError,
                              ),
                              const SizedBox(height: 14),

                              // Input Kata Laluan
                              _buildVisualInputField(
                                controller: passwordController,
                                focusNode: _passwordFocusNode,
                                hint: "Password",
                                obscureText: obscurePassword,
                                errorText: passwordError,
                                suffix: GestureDetector(
                                  onTap: () => setState(() => obscurePassword = !obscurePassword),
                                  child: Icon(
                                    obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Butang Log In
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeYellow,
                                    foregroundColor: themePurpleCard,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    "Log In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Pautan ke Signup
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                                      );
                                    },
                                    child: const Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: themeYellow,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // MASKOT ANIMASI SEBELUM MENAIP
                        Positioned(
                          top: -76,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildYellowGradientCharacter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYellowGradientCharacter() {
    return SizedBox(
      width: 160,
      height: 110,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 116,
            height: 86,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF699),
                  Color(0xFFFFAE19),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
          ),

          Positioned(
            top: 10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFF1E192E).withOpacity(0.7),
                      width: 4.0,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(top: 34, left: 14, child: Container(width: 14, height: 26, decoration: BoxDecoration(color: const Color(0xFF1E192E), borderRadius: BorderRadius.circular(6)))),
          Positioned(top: 34, right: 14, child: Container(width: 14, height: 26, decoration: BoxDecoration(color: const Color(0xFF1E192E), borderRadius: BorderRadius.circular(6)))),

          Positioned(
            bottom: 46,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMascotEyeStructure(),
                const SizedBox(width: 24),
                _buildMascotEyeStructure(),
              ],
            ),
          ),

          Positioned(
            bottom: 24,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _isPasswordFocused ? 0.3 : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                  ),
                  Positioned(
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            bottom: _isPasswordFocused ? 44 : 2,
            left: _isPasswordFocused ? 20 : 6,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFF9E00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.back_hand_rounded, size: 16, color: Colors.white),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            bottom: _isPasswordFocused ? 44 : 2,
            right: _isPasswordFocused ? 20 : 6,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFF9E00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.front_hand_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotEyeStructure() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: _isPasswordFocused ? 0 : 24,
      height: _isPasswordFocused ? 0 : 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black87, width: 1.8),
      ),
      child: _isPasswordFocused
          ? const SizedBox.shrink()
          : Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                  ),
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVisualInputField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    bool obscureText = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: inputPurpleTint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              filled: true,
              fillColor: Colors.transparent,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 14),
              suffixIcon: suffix,
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.redAccent : themeYellow,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 6),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}