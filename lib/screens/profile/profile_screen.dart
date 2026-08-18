import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/session_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import '../auth/auth_page.dart';

class ProfileScreen extends StatefulWidget {
  final double passedHappy;
  final double passedNeutral;
  final double passedSad;
  final double passedAngry;

  const ProfileScreen({
    super.key,
    this.passedHappy = 0.0,
    this.passedNeutral = 0.0,
    this.passedSad = 0.0,
    this.passedAngry = 0.0,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Palet Warna Ketat: Hanya Dark Purple & Yellow Premium
  static const Color darkPurple = Color(0xFF1A0B2E);
  static const Color midPurple = Color(0xFF32145A);
  static const Color accentYellow = Color(0xFFFFD700);
  
  // Warna Kad Dinamik (Dark Purple VS Premium Soft Cream)
  static const Color darkCardPurple = Color(0xFF25123E);
  static const Color lightCardCream = Color(0xFFFDFBF7); // Soft Aesthetic Cream
  static const Color lightBgCream = Color(0xFFFFFDD0);   // Rich Rich Cream

  // Keadaan Suis Tema (Default: Gelap / Dark Mode)
  bool isDarkMode = true;

  String username = "User";
  String email = "";
  File? profileImage;
  String profileImagePath = "";
  final ImagePicker picker = ImagePicker();
  final TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =========================
  // VIEW PROFILE IMAGE
  // =========================
  void viewProfileImage() {
    if (profileImagePath.isEmpty && profileImage == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.85),
      builder: (_) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Container(
                  height: MediaQuery.of(context).size.height * .60,
                  width: MediaQuery.of(context).size.width * .88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: accentYellow, width: 2),
                    image: DecorationImage(
                      image: profileImage != null
                          ? FileImage(profileImage!)
                          : NetworkImage(
                              profileImagePath.startsWith("http")
                                  ? profileImagePath
                                  : "http://10.223.102.154/moodify_api/${profileImagePath.replaceFirst("/", "")}",
                            ) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 25,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: darkPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: accentYellow, size: 20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // PICK IMAGE
  // =========================
  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      compressQuality: 90,
      compressFormat: ImageCompressFormat.jpg,
    );
    if (croppedFile == null) return;

    final croppedPath = croppedFile.path;
    final user = await SessionService.getUser();
    final userId = user["id"].toString();

    final url = await CloudinaryService.uploadImage(File(croppedPath));
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cloud upload failed")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'profile_image': url}, SetOptions(merge: true));

      setState(() {
        profileImagePath = url;
        profileImage = File(croppedPath);
      });

      await SessionService.saveProfileImage(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile picture updated successfully!"),
          backgroundColor: midPurple,
        ),
      );
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
    }
  }

  // =========================
  // LOAD USER
  // =========================
  Future<void> loadUser() async {
    final user = await SessionService.getUser();
    final userId = user["id"].toString();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = doc.data() ?? {};

      setState(() {
        username = data['username'] ?? user["username"] ?? "User";
        email = user["email"] ?? "";
        usernameController.text = username;
        profileImagePath = data['profile_image'] ?? "";
      });
    } catch (e) {
      debugPrint("LOAD USER ERROR: $e");
    }
  }

  // =========================
  // EDIT USERNAME DIALOG
  // =========================
  Future<void> showEditUsernameDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? darkPurple : lightCardCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26), // 🟢 DIBAIKI: Lengkungan dibesarkan daripada 24 ke 26
            side: BorderSide(color: isDarkMode ? accentYellow : midPurple, width: 1.5),
          ),
          title: Text(
            "Update Username",
            style: TextStyle(
              color: isDarkMode ? Colors.white : darkPurple, 
              fontSize: 20, // 🟢 DIBAIKI: Saiz tajuk dialog dibesarkan
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: usernameController,
            style: TextStyle(color: isDarkMode ? Colors.white : darkPurple, fontSize: 16), // 🟢 DIBAIKI: Fon input dibesarkan
            decoration: InputDecoration(
              hintText: "Enter new username",
              hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38, fontSize: 15),
              filled: true,
              fillColor: isDarkMode ? darkCardPurple : Colors.orange.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18), // 🟢 DIBAIKI: Ruang padding dinaikkan
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDarkMode ? accentYellow : midPurple, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel", 
                style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.black54, fontSize: 15, fontWeight: FontWeight.w600), // 🟢 DIBAIKI: Teks dibesarkan
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? accentYellow : midPurple,
                foregroundColor: isDarkMode ? darkPurple : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), // 🟢 DIBAIKI: Ditambah padding butang
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                if (newUsername.isEmpty) return;

                final user = await SessionService.getUser();
                final userId = user["id"].toString();

                final success = await ApiService.updateProfile(
                  userId: userId,
                  username: newUsername,
                  profileImage: profileImagePath,
                );

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update username")),
                  );
                  return;
                }

                await SessionService.saveUsername(newUsername);
                setState(() {
                  username = newUsername;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: midPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: accentYellow),
                        SizedBox(width: 12),
                        Text("Username updated successfully", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
              child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), // 🟢 DIBAIKI: Teks dibesarkan
            ),
          ],
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    // Pengawalan dinamik mengikut mod tema aktif (Sokongan Tona Krim)
    final Color currentCardBg = isDarkMode ? darkCardPurple.withOpacity(0.85) : lightCardCream.withOpacity(0.95);
    final Color mainTextColor = isDarkMode ? Colors.white : darkPurple;
    final Color subTextColor = isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black54;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg03.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                darkPurple.withOpacity(isDarkMode ? 0.4 : 0.1),
                isDarkMode ? darkPurple.withOpacity(0.85) : lightBgCream.withOpacity(0.5),
                isDarkMode ? darkPurple : lightBgCream, // Layer bawah bertukar penuh ke Krim
              ],
              stops: const [0.0, 0.5, 0.9],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              child: Column(
                children: [
                  // APP BAR HEADER (BUTANG LIGHT THEME TELAH DIBUANG)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Text(
                          "MY PROFILE",
                          style: const TextStyle(
                            color: accentYellow, 
                            fontSize: 24, // 🟢 DIBAIKI: Diubah daripada 22 ke 24 supaya lebih jelas
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                            shadows: [
                              Shadow(
                                color: Colors.black38, 
                                blurRadius: 4, 
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // 🟢 DIBAIKI: Jarak kotak dinaikkan daripada 25 ke 30

                  // PROFILE AVATAR LAYOUT
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 140, // 🟢 DIBAIKI: Dibesarkan daripada 130 ke 140
                        width: 140,  // 🟢 DIBAIKI: Dibesarkan daripada 130 ke 140
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDarkMode ? accentYellow : midPurple, width: 3.5), // Tebal border dinaikkan sedikit
                          boxShadow: [
                            BoxShadow(
                              color: (isDarkMode ? accentYellow : midPurple).withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 3,
                            )
                          ],
                        ),
                        child: GestureDetector(
                          onTap: viewProfileImage,
                          child: CircleAvatar(
                            backgroundColor: isDarkMode ? darkCardPurple : Colors.orange.withOpacity(0.1),
                            backgroundImage: profileImagePath.isNotEmpty
                                ? NetworkImage(
                                    profileImagePath.startsWith("http")
                                        ? profileImagePath
                                        : "http://10.223.102.154/moodify_api/${profileImagePath.replaceFirst("/", "")}",
                                  )
                                : null,
                            child: profileImagePath.isEmpty
                                ? Icon(Icons.person, color: isDarkMode ? Colors.white : midPurple, size: 75) // 🟢 DIBAIKI: Saiz ikon placeholder dibesarkan
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 6,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10), // 🟢 DIBAIKI: Padding ikon kamera dibesarkan
                            decoration: BoxDecoration(
                              color: isDarkMode ? accentYellow : midPurple,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded, 
                              color: isDarkMode ? darkPurple : Colors.white, 
                              size: 20, // 🟢 DIBAIKI: Saiz ikon kamera dibesarkan daripada 18 ke 20
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24), // 🟢 DIBAIKI: Jarak dinaikkan daripada 20 ke 24

                  // USERNAME DISPLAY WITH EDIT ACTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mainTextColor,
                            fontSize: 28, // 🟢 DIBAIKI: Saiz nama pengguna dibesarkan daripada 26 ke 28
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // 🟢 DIBAIKI: Jarak horizontal dibesarkan sedikit
                      GestureDetector(
                        onTap: showEditUsernameDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8), // 🟢 DIBAIKI: Kotak sentuhan ikon edit dibesarkan
                          decoration: BoxDecoration(
                            color: currentCardBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isDarkMode ? accentYellow : midPurple).withOpacity(0.5), 
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.edit_rounded, color: isDarkMode ? accentYellow : midPurple, size: 16), // 🟢 DIBAIKI: Saiz ikon dibesarkan
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // EMAIL SUBTITLE
                  Text(
                    email,
                    style: TextStyle(color: subTextColor, fontSize: 15, fontWeight: FontWeight.w500), // 🟢 DIBAIKI: Fon dibesarkan daripada 14 ke 15
                  ),
                  const SizedBox(height: 35), // 🟢 DIBAIKI: Jarak dinaikkan daripada 30 ke 35

                  // PREMIUM MEMBER BANNER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22), // 🟢 DIBAIKI: Padding dalaman kontena dibesarkan
                    decoration: BoxDecoration(
                      color: isDarkMode ? darkCardPurple.withOpacity(0.9) : midPurple,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accentYellow, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: midPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded, color: accentYellow, size: 30), // 🟢 DIBAIKI: Ikon dibesarkan
                                SizedBox(width: 10),
                                Text(
                                  "Moodify Premium",
                                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900), // 🟢 DIBAIKI: Teks dibesarkan
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 🟢 DIBAIKI: Badging dibesarkan
                              decoration: BoxDecoration(
                                color: accentYellow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "PRO MEMBER",
                                style: TextStyle(color: darkPurple, fontSize: 11, fontWeight: FontWeight.w900), // 🟢 DIBAIKI: Teks dibesarkan
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Your emotional well-being and tailored music stream ecosystem are fully unlocked.",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.45), // 🟢 DIBAIKI: Fon teks dibesarkan daripada 13 ke 14
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22), // 🟢 DIBAIKI: Jarak di antara seksyen dinaikkan

                  // SECTION: PERSONAL INFO TILES
                  _buildSectionTitle("PERSONAL ACCOUNT"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20), // 🟢 DIBAIKI: Padding kad maklumat akaun dibesarkan daripada 18 ke 20
                    decoration: BoxDecoration(
                      color: currentCardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: mainTextColor.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _profileRowItem(Icons.person_outline_rounded, "Username", username, mainTextColor, subTextColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14), // 🟢 DIBAIKI: Jarak pemisah ditinggikan sedikit
                          child: Divider(color: mainTextColor.withOpacity(0.08), height: 1),
                        ),
                        _profileRowItem(Icons.mail_outline_rounded, "Email Address", email, mainTextColor, subTextColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // SECTION: DAILY ENERGY BOOSTER (100% HARDCODED, SAFE & AYAT DIPANJANGKAN)
                  _buildSectionTitle("DAILY ENERGY BOOSTER"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22), // 🟢 DIBAIKI: Padding kontena dibesarkan ke 22
                    decoration: BoxDecoration(
                      color: currentCardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: mainTextColor.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded, 
                              color: isDarkMode ? accentYellow : darkPurple, 
                              size: 22 // 🟢 DIBAIKI: Saiz ikon booster dibesarkan daripada 20 ke 22
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Mindful Reminder",
                              style: TextStyle(
                                color: mainTextColor,
                                fontSize: 15, // 🟢 DIBAIKI: Saiz teks tajuk dibesarkan daripada 14 ke 15
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: mainTextColor.withOpacity(0.08), height: 1),
                        ),
                        
                        // 🟢 DIBAIKI: Ayat motivasi dipanjangkan lagi dengan tambahan kata-kata inspirasi yang mendalam dan saiz teks dibesarkan ke 14.5
                        Text(
                          "\"Your mind is a powerful thing. When you fill it with positive thoughts, your entire reality will start to change beautifully. Remember that progress is not linear; it is okay to have quiet days. Take a deep, slow breath, protect your inner peace at all costs, celebrate your small victories, and keep moving forward with confidence! You are stronger than you think, and your journey matters. ✨🌻🌟\"",
                          style: TextStyle(
                            color: mainTextColor.withOpacity(0.85),
                            fontSize: 14.5, // 🟢 DIBAIKI: Saiz teks motivasi dibesarkan daripada 13 ke 14.5 agar sangat mudah dibaca
                            fontWeight: FontWeight.w600,
                            height: 1.65,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40), // 🟢 DIBAIKI: Ruang sebelum butang keluar dinaikkan daripada 35 ke 40
                  
                  // LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 20), // 🟢 DIBAIKI: Padding butang logout ditinggikan daripada 18 ke 20
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFFF4A4A), width: 1.8), // Border ditebalkan sedikit
                        ),
                      ),
                      onPressed: () async {
                        await SessionService.clearSession();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                          (route) => false,
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFFFF4A4A), size: 22), // 🟢 DIBAIKI: Ikon keluar dibesarkan sedikit
                          SizedBox(width: 12),
                          Text(
                            "Logout Account",
                            style: TextStyle(color: Color(0xFFFF4A4A), fontSize: 17, fontWeight: FontWeight.w900), // 🟢 DIBAIKI: Teks dibesarkan daripada 16 ke 17 dengan ketebalan penuh
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET PEMBANTU: Section Title
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10), // 🟢 DIBAIKI: Jarak bawah tajuk seksyen ditambah sedikit
        child: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? accentYellow : midPurple,
            fontSize: 13, // 🟢 DIBAIKI: Saiz teks seksyen kecil dibesarkan daripada 12 ke 13
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
      ),
    );
  }

  // WIDGET PEMBANTU: Baris Info Profil Static
  Widget _profileRowItem(IconData icon, String label, String value, Color textStyleColor, Color subStyleColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12), // 🟢 DIBAIKI: Padding pembungkus ikon dilaraskan lebih luas daripada 10 ke 12
          decoration: BoxDecoration(
            color: (isDarkMode ? midPurple : Colors.orange.withOpacity(0.1)).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isDarkMode ? accentYellow : midPurple, size: 22), // 🟢 DIBAIKI: Saiz ikon dibesarkan daripada 20 ke 22
        ),
        const SizedBox(width: 16), // 🟢 DIBAIKI: Ruang antara ikon dan teks dibesarkan sedikit
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: subStyleColor, fontSize: 12, fontWeight: FontWeight.w600)), // 🟢 DIBAIKI: Kapsyen dibesarkan daripada 11 ke 12
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: textStyleColor, fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis), // 🟢 DIBAIKI: Nilai teks dibesarkan daripada 14 ke 15
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET PEMBANTU: Baris Menu Interaktif Tambahan
  Widget _actionRowMenu(IconData icon, String title, Color textStyleColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12), // 🟢 DIBAIKI: Dibesarkan sedikit padding aksi menu
            decoration: BoxDecoration(
              color: (isDarkMode ? midPurple : Colors.orange.withOpacity(0.1)).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isDarkMode ? Colors.white70 : darkPurple.withOpacity(0.7), size: 22), // 🟢 DIBAIKI: Ikon dibesarkan ke 22
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: textStyleColor, fontSize: 15.5, fontWeight: FontWeight.w700), // 🟢 DIBAIKI: Teks aksi dibesarkan daripada 14 ke 15.5
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: isDarkMode ? accentYellow : midPurple, size: 22), // 🟢 DIBAIKI: Ikon anak panah dibesarkan
        ],
      ),
    );
  }
}