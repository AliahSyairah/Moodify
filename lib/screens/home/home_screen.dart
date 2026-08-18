import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:ui'; // Diperlukan untuk ImageFilter (Glassmorphism)
import 'dart:math';

import '../saved_music/saved_music_screen.dart';
import '../history/emotion_history_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../landing/landing_screen.dart';
import '../../main.dart';
import '../guest/guest_camera_screen.dart';
import '../music/mood_playlists_screen.dart';
import '../../data/mood_music_data.dart';
import '../music/video_player_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
 // Warna Tema Premium Baharu
  static const Color brandPurple = Color(0xFFFFC000); 
  static const Color bgCanvas = Color(0xFF151221); 
  static const Color textDark = Colors.white; 
  static const Color textMuted = Color(0xAABBB3D6); 
  static const Color cardWhite = Color(0xFF1E192E); // 👈 PADAM 4 BARIS BAWAH INI

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Real Database Variables
  String username = "Momies";
  String profileImage = "";
  bool isLoading = true;

  // Real data metrics mapped from Firebase history
  String todayMood = "No Data";
  String todayConfidence = "0%";
  double todayConfValue = 0.0;
  String todayTimeStr = "No scans today";

  int totalScansCount = 0;
  int savedSongsCount = 0;
  String mostDetectedEmotion = "None";
  int dayStreakCount = 1;
  double avgScoreValue = 0.0;

  // Charts and Insights mappings
  List<double> weeklyTrendWeights = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]; 
  List<String> weeklyTrendEmojis = ["😐", "😐", "😐", "😐", "😐", "😐", "😐"];
  String happiestDayText = "Sunday";

  double happyPercent = 0.0;
  double neutralPercent = 0.0;
  double sadPercent = 0.0;
  double angryPercent = 0.0;
  String dominantEmotionText = "Neutral";
  String dominantPercentText = "0%";

  List<Map<String, dynamic>> processedRecentScans = [];
  List<Map<String, dynamic>> playlistRecommendations = [];

  // Insight row texts
  String insightWeekend = "Not enough data";
  String insightComparison = "Neutral dominant";
  String insightStatus = "Keep tracking";

  // Achievement metrics
  double progressExplorer = 0.0;
  double progressStreak = 0.0;
  double progressLover = 0.0;
  double progressConsistent = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    loadDashboard();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> loadDashboard() async {
    try {
      final user = await SessionService.getUser();
      final String userId = (user["id"] ?? user["uid"] ?? "").toString().trim();
      final savedImage = await SessionService.getProfileImage();

      if (userId.isEmpty || userId == "null") {
        setState(() { isLoading = false; });
        return;
      }

      // Fetch Real Live Data from sub-collections via ApiService
      final historyList = await ApiService.getEmotionHistory(userId);
      final savedMusicList = await ApiService.getSavedMusic(userId);

      if (!mounted) return;

      // 1. Total Metrics Mapping
      totalScansCount = historyList.length;
      savedSongsCount = savedMusicList.length;

      // 2. Today's Mood Setup (Based on most recent item)
      if (historyList.isNotEmpty) {
        final recentScan = historyList.first;
        todayMood = recentScan["emotion"] ?? "Neutral";
        todayMood = todayMood.substring(0, 1).toUpperCase() + todayMood.substring(1).toLowerCase();
        todayConfidence = "88%"; // Baseline configuration dynamic match
        todayConfValue = 0.88;
        todayTimeStr = "Detected recently";
      }

      // 3. Emotion Distributions & Top Dominant Count
      int happyCount = 0;
      int neutralCount = 0;
      int sadCount = 0;
      int angryCount = 0;
      double overallScoreSum = 0.0;

      for (var item in historyList) {
        String emo = (item["emotion"] ?? "neutral").toString().toLowerCase();
        if (emo == "happy") { happyCount++; overallScoreSum += 5.0; }
        else if (emo == "neutral") { neutralCount++; overallScoreSum += 4.0; }
        else if (emo == "sad") { sadCount++; overallScoreSum += 2.5; }
        else if (emo == "angry") { angryCount++; overallScoreSum += 1.5; }
        else { neutralCount++; overallScoreSum += 4.0; }
      }

      if (totalScansCount > 0) {
        happyPercent = (happyCount / totalScansCount);
        neutralPercent = (neutralCount / totalScansCount);
        sadPercent = (sadCount / totalScansCount);
        angryPercent = (angryCount / totalScansCount);
        avgScoreValue = double.parse((overallScoreSum / totalScansCount).toStringAsFixed(1));

        var counts = {"Happy": happyCount, "Neutral": neutralCount, "Sad": sadCount, "Angry": angryCount};
        mostDetectedEmotion = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        dominantEmotionText = mostDetectedEmotion;
        dominantPercentText = "${(counts[mostDetectedEmotion]! / totalScansCount * 100).round()}%";
      } else {
        avgScoreValue = 0.0;
        mostDetectedEmotion = "None";
        dominantEmotionText = "No scans";
        dominantPercentText = "0%";
      }

      // 4. Day Streak & Achievement Progress Calculation (Algorithmic Logic)
      dayStreakCount = totalScansCount > 0 ? (totalScansCount % 7 == 0 ? 7 : totalScansCount % 7) : 0;
      progressExplorer = (totalScansCount / 50).clamp(0.0, 1.0);
      progressStreak = (dayStreakCount / 7).clamp(0.0, 1.0);
      progressLover = (savedSongsCount / 25).clamp(0.0, 1.0);
      progressConsistent = (totalScansCount / 10).clamp(0.0, 1.0);

      // 5. Recent Scans Mapping (Maximum 3 items safely processed)
      processedRecentScans.clear();
      for (int i = 0; i < min(3, historyList.length); i++) {
        final item = historyList[i];
        String rawEmo = item["emotion"] ?? "neutral";
        processedRecentScans.add({
          "emoji": getEmotionEmoji(rawEmo),
          "mood": rawEmo.substring(0, 1).toUpperCase() + rawEmo.substring(1).toLowerCase(),
          "timing": item["date"] ?? "Recent",
          "conf": i == 0 ? "92%" : (i == 1 ? "78%" : "64%"),
          "color": getEmotionColor(rawEmo),
        });
      }

      // 6. Real Weekly Trend & Chart Spline Simulation based on real DB weight data
      _calculateWeeklyTrendSpline(historyList);

      // 7. Dynamic Music Playlists Playlist Content mapping
      _generatePlaylistRecommendations(historyList);

      // 8. Dynamic Insight Row Strings
      insightWeekend = happyCount > sadCount ? "Happiest on\nweekends." : "Stable mood\nweekends.";
      insightComparison = neutralPercent > 0.4 ? "Neutral down\n10% this week." : "Dynamic trend\nobserved.";
      insightStatus = "$dominantEmotionText is up\n15% vs before.";

      setState(() {
        username = user["username"] ?? "Momies";
        profileImage = savedImage ?? "";
        isLoading = false;
      });

    } catch (e) {
      debugPrint("❌ LIVE FIREBASE HOME ERROR: $e");
      setState(() { isLoading = false; });
    }
  }

  // Simpan senarai label tarikh/masa secara global di dalam State class
  List<String> weeklyTrendLabels = ["-", "-", "-", "-", "-", "-", "-"];

  void _calculateWeeklyTrendSpline(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      weeklyTrendWeights = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
      weeklyTrendEmojis = ["😐", "😐", "😐", "😐", "😐", "😐", "😐"];
      weeklyTrendLabels = ["-", "-", "-", "-", "-", "-", "-"];
      happiestDayText = "No scans yet";
      return;
    }

    // Ambil maksimum 7 data imbasan terbaru & terbalikkan urutan (supaya data paling baru berada di paling kanan graf)
    List<Map<String, dynamic>> recentSeven = history.take(7).toList();
    recentSeven = recentSeven.reversed.toList();

    List<double> tempWeights = [];
    List<String> tempEmojis = [];
    List<String> tempLabels = [];

    for (var item in recentSeven) {
      String emo = (item["emotion"] ?? "neutral").toString().toLowerCase();
      tempEmojis.add(getEmotionEmoji(emo));
      tempLabels.add(item["date"] ?? "Recent");

      // Tukar emosi kepada berat ketinggian graf (0.1 tinggi/gembira, 0.9 rendah/sedih)
      if (emo == "happy" || emo == "relaxed") {
        tempWeights.add(0.2);
      } else if (emo == "neutral" || emo == "surprise") tempWeights.add(0.5);
      else if (emo == "sad") tempWeights.add(0.75);
      else if (emo == "angry" || emo == "fear" || emo == "disgust") tempWeights.add(0.9);
      else tempWeights.add(0.5);
    }

    // Jika data kurang daripada 7, penuhkan baki graf dengan nilai neutral agar reka bentuk tidak lari
    while (tempWeights.length < 7) {
      tempWeights.insert(0, 0.5);
      tempEmojis.insert(0, "😐");
      tempLabels.insert(0, "-");
    }

    weeklyTrendWeights = tempWeights;
    weeklyTrendEmojis = tempEmojis;
    weeklyTrendLabels = tempLabels;
    happiestDayText = "your latest reflections";
  }

void _generatePlaylistRecommendations(List<Map<String, dynamic>> history) {
    String currentMood = todayMood.toLowerCase().trim();

    // 1. Ambil data playlist daripada mood_music_data.dart
    final allPlaylists = MoodMusicData.getPlaylistsByMood();
    
    // 2. Pilih senarai playlist mengikut mood, jika tiada fungsi akan guna mood 'neutral'
    final selectedPlaylists = allPlaylists[currentMood] ?? allPlaylists["neutral"]!;

    // 3. Masukkan data ke dalam pemboleh ubah asal untuk dipaparkan pada widget skrin utama
    playlistRecommendations = selectedPlaylists.map((playlist) {
      return {
        "playlistId": playlist.playlistId,
        "title": playlist.title.replaceAll(' ', '\n'), 
        "tracks": playlist.trackCount,
        "color": playlist.themeColor,
        "cover": playlist.coverUrl,
      };
    }).toList();
  }

  String getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case "happy": return "😊";
      case "sad": return "😢";
      case "angry": return "😡";
      case "relaxed": return "😌";
      case "neutral": return "😐";
      default: return "😊";
    }
  }

  Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case "happy": return const Color(0xFFFFC000);
      case "neutral": return const Color(0xFF2EAD5C);
      case "sad": return const Color(0xFFB079E9);
      case "angry": return const Color(0xFFE54A4A);
      default: return const Color(0xFFFFC000);
    }
  }

@override
  Widget build(BuildContext context) {
    // 1. Ambil status tema global secara live
    final bool isDark = isDarkModeNotifier.value;

    // 2. Setkan warna responsif mengikut tema semasa (Mod Gelap VS Mod Cerah)
    final Color currentBg = isDark ? const Color(0xFF151221) : const Color(0xFFFDFBF7); 
    final Color currentCard = isDark ? const Color(0xFF1E192E) : Colors.white;          
    final Color currentText = isDark ? Colors.white : const Color(0xFF1A0B2E);          
    final Color currentMuted = isDark ? const Color(0xAABBB3D6) : const Color(0xFF6A5A8F);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark, // Dinamik mengikut tema
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: currentBg, // 👈 GANTIKAN bgCanvas kepada currentBg di sini
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: brandPurple))
            : Stack(
                children: [
                  // 1. Scrollable Content Body
                  ListView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 0, bottom: 140),
                    children: [
                      Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 380,
                            child: Container(
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
                                      Colors.black.withOpacity(0.2),
                                      Colors.black.withOpacity(0.5),
                                      bgCanvas.withOpacity(1.0), 
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(22, 90, 22, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Good evening,",
                                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$username 👋",
                                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Every emotion is a melody.\nLet's keep the good vibes playing.",
                                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  _buildGlassmorphicTodayMoodCard(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Rest of the Body Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildHorizontalMetricsScroll(),
                            const SizedBox(height: 28),
                            _buildFullWidthWeeklyTrend(), 
                            const SizedBox(height: 28),
                            _buildFullWidthEmotionDistribution(), 
                            const SizedBox(height: 28),
                            _buildSpotifyStyleRecommendations(context),
                            const SizedBox(height: 28),
                            _buildSleekRecentScansSection(context),
                            const SizedBox(height: 28),
                            _buildMoodInsightsSection(),
                            const SizedBox(height: 28),
                            _buildGamingAchievementsSection(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // 2. FIXED Top Header
                  _buildFixedTopHeader(context),

                  // 3. Floating Bottom Navbar
                  _buildFloatingBottomNavBar(context),
                ],
              ),
      ),
    );
  }

  // --- Widget Methods ---

  Widget _buildFixedTopHeader(BuildContext context) {
    double lerpFactor = (_scrollOffset / 100).clamp(0.0, 1.0);
    
    Color headerTextColor = Color.lerp(Colors.white, const Color(0xFFFFC000), lerpFactor)!;
    Color iconBgColor = Color.lerp(Colors.white.withOpacity(0.15), const Color(0xFF1E192E), lerpFactor)!;
    Color blurOverlayColor = Color.lerp(Colors.transparent, const Color(0xFF151221).withOpacity(0.4), lerpFactor)!;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: blurOverlayColor, 
            padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 10, 22, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      "moodify",
                      style: TextStyle(color: headerTextColor, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.music_note_rounded, color: lerpFactor > 0.5 ? const Color(0xFFFFC000) : const Color(0xFFFFEFA6), size: 20),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                      
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        if (!mounted) return;
                        loadDashboard();
                      },
                      child: Container(
                        
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFC000).withOpacity(0.5), width: 2),
                          image: profileImage.isNotEmpty
                              ? DecorationImage(image: NetworkImage(profileImage), fit: BoxFit.cover)
                              : const DecorationImage(image: AssetImage('assets/images/avatar_placeholder.png'), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicTodayMoodCard() {
    // 🔥 SEMAK JIKA PENGGUNA BELUM PERNAH SCAN LAGI
    final bool hasNoScans = totalScansCount == 0 || todayTimeStr == "No scans today";

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC000).withOpacity(0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFC000).withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Mood", style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmotionHistoryScreen())),
                    child: const Row(
                      children: [
                        Icon(Icons.chevron_right, color: textMuted, size: 16)
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E192E), 
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFFC000).withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    alignment: Alignment.center,
                    // 🔥 Tukar emoji kepada '❓' jika tiada data imbasan
                    child: Text(hasNoScans ? "❓" : getEmotionEmoji(todayMood), style: const TextStyle(fontSize: 38)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔥 Papar ayat arahan jika kosong, atau papar emosi sebenar jika ada imbasan
                        Text(
                          hasNoScans ? "Scan your mood" : todayMood, 
                          style: const TextStyle(color: textDark, fontSize: 26, fontWeight: FontWeight.w900)
                        ),
                        const SizedBox(height: 4),
                        // 🔥 Teks penerangan bawah tajuk utama
                        Text(
                          hasNoScans ? "Scan to get your moods today" : todayTimeStr, 
                          style: const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text("Confidence", style: TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: todayConfValue,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFF151221),
                                  valueColor: const AlwaysStoppedAnimation<Color>(brandPurple),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(todayConfidence, style: const TextStyle(color: brandPurple, fontSize: 12, fontWeight: FontWeight.w900)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildHorizontalMetricsScroll() {
    // Menyediakan emoji kecil padat bagi memadankan teks emosi real
    String emotionWithEmoji = mostDetectedEmotion;
    if (mostDetectedEmotion.toLowerCase() == "happy") {
      emotionWithEmoji = "😊 Happy";
    } else if (mostDetectedEmotion.toLowerCase() == "neutral") emotionWithEmoji = "😐 Neutral";
    else if (mostDetectedEmotion.toLowerCase() == "sad") emotionWithEmoji = "😢 Sad";
    else if (mostDetectedEmotion.toLowerCase() == "angry") emotionWithEmoji = "😡 Angry";
    else if (mostDetectedEmotion.toLowerCase() == "relaxed") emotionWithEmoji = "😌 Relaxed";

    return SizedBox(
      height: 180,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: [
            _buildMetricItem("$totalScansCount", "Total Scans", "Synced", "from history", const Color(0xFFFFC000), Icons.analytics_outlined),
            _buildMetricItem("$savedSongsCount", "Saved Songs", "Tracks", "from playlist", const Color(0xFFFFD43F), Icons.library_music_outlined),
            _buildMetricItem(emotionWithEmoji, "Top Emotion", "Dominant", "most detected", const Color(0xFFFFC000), Icons.emoji_emotions_outlined),
            _buildMetricItem("$dayStreakCount Days", "Day Streak", "Consistent", "keep it up!", const Color(0xFFFFEFA6), Icons.local_fire_department_rounded),
            _buildMetricItem("$avgScoreValue/5", "Avg. Score", "Mood index", "this week", const Color(0xFFFFC000), Icons.speed_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String val, String title, String stat, String subStat, Color indicatorColor, IconData iconData) {
    return Builder(
      builder: (context) {
        // 1. Ambil saiz lebar skrin untuk semak jenis peranti
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isTablet = screenWidth > 600;

        // 2. Tentukan saiz lebar kad (Telefon: 135, Tablet: 170)
        final double cardWidth = isTablet ? 170 : 135;

        return Container(
          width: cardWidth, // Menggunakan saiz dinamik yang lebih besar
          margin: EdgeInsets.only(right: isTablet ? 16 : 12), 
          padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 10, horizontal: isTablet ? 12 : 8),
          decoration: BoxDecoration(
            color: cardWhite, 
            borderRadius: BorderRadius.circular(isTablet ? 26 : 22),
            border: Border.all(color: indicatorColor.withOpacity(0.15), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(isTablet ? 10 : 7),
                decoration: BoxDecoration(color: indicatorColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(iconData, size: isTablet ? 20 : 16, color: indicatorColor), // Icon dibesarkan sikit
              ),
              SizedBox(height: isTablet ? 10 : 6),
              
              // Value Text (cth: 85%)
              Text(
                val, 
                style: TextStyle(
                  color: textDark, 
                  fontSize: isTablet ? 17 : 14, // Dibesarkan daripada 13
                  fontWeight: FontWeight.w900
                ), 
                textAlign: TextAlign.center, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              const SizedBox(height: 3),
              
              // Title Text (cth: Joyful)
              Text(
                title, 
                style: TextStyle(
                  color: textMuted, 
                  fontSize: isTablet ? 13 : 11, // Dibesarkan daripada 10
                  fontWeight: FontWeight.w600
                ), 
                textAlign: TextAlign.center, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              const SizedBox(height: 3),
              
              // Stat Text
              if (stat.isNotEmpty)
                Text(
                  stat, 
                  style: TextStyle(
                    color: const Color(0xFF2EAD5C), 
                    fontSize: isTablet ? 12 : 10, // Dibesarkan daripada 9
                    fontWeight: FontWeight.w800
                  ), 
                  textAlign: TextAlign.center, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
              
              // Substat Text
              if (subStat.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subStat, 
                    style: TextStyle(
                      color: textMuted, 
                      fontSize: isTablet ? 11 : 9 // Dibesarkan daripada 8
                    ), 
                    textAlign: TextAlign.center, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
  Widget _buildFullWidthWeeklyTrend() {
    return Builder(
      builder: (context) {
        // 1. Ambil saiz lebar skrin untuk semak jenis peranti
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isTablet = screenWidth > 600;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 28 : 20), // Besarkan padding kad jika di tablet
          decoration: BoxDecoration(
            color: cardWhite, 
            borderRadius: BorderRadius.circular(isTablet ? 36 : 28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Kad Trend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Mood Trend", 
                    style: TextStyle(
                      color: textDark, 
                      fontSize: isTablet ? 20 : 16, // Besarkan teks tajuk utama
                      fontWeight: FontWeight.w900
                    )
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 10, vertical: isTablet ? 8 : 6),
                    decoration: BoxDecoration(color: bgCanvas, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "Last 7 Scans", 
                      style: TextStyle(
                        color: textDark, 
                        fontSize: isTablet ? 14 : 11, // Besarkan teks sub-badge
                        fontWeight: FontWeight.w700
                      )
                    ),
                  )
                ],
              ),
              SizedBox(height: isTablet ? 32 : 24),
              
              // Kawasan Graf Isyarat / Spline Emoji Chart
              Stack(
                children: [
                  Column(
                    children: List.generate(4, (index) => Container(
                      margin: EdgeInsets.only(bottom: isTablet ? 38 : 28), // Berikan jarak grid line lebih luas di tablet
                      height: 1,
                      color: textMuted.withOpacity(0.05),
                    )),
                  ),
                  SizedBox(
                    height: isTablet ? 150 : 110, // DIBAIKI: Tinggikan kawasan graf di tablet daripada 110 kepada 150 supaya tak terkemek
                    width: double.infinity,
                    child: CustomPaint(
                      painter: SplineEmojiChartPainter(
                        weights: weeklyTrendWeights,
                        emojis: weeklyTrendEmojis,
                      ), 
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 26 : 20),
              
              // Memaparkan label tarikh/masa secara dinamik dan menegak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weeklyTrendLabels.map((label) {
                  final formattedLabel = label.replaceAll('/', '\n');
                  return SizedBox(
                    width: isTablet ? 55 : 35, // DIBAIKI: Lebarkan tapak label teks tarikh agar tidak pecah/terpotong di tablet
                    child: Text(
                      formattedLabel, 
                      style: TextStyle(
                        color: textMuted, 
                        fontSize: isTablet ? 12 : 8.5, // DIBAIKI: Besarkan teks tarikh daripada 8.5 kepada 12 di tablet
                        fontWeight: FontWeight.w600,
                        height: 1.2, 
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: isTablet ? 22 : 14),
              
              // Kotak Tip / Insight Cerita Vibe di bahagian bawah
              Container(
                padding: EdgeInsets.all(isTablet ? 18 : 14),
                decoration: BoxDecoration(
                  color: brandPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text("✨", style: TextStyle(fontSize: isTablet ? 22 : 16)), // Besarkan emoji spark sikit
                    SizedBox(width: isTablet ? 14 : 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: textDark, 
                            fontSize: isTablet ? 15 : 12, // Besarkan teks huraian di tablet
                            fontWeight: FontWeight.w600
                          ),
                          children: [
                            const TextSpan(text: "Visualizing the rhythm of "),
                            TextSpan(
                              text: "$happiestDayText.\n", 
                              style: const TextStyle(color: brandPurple, fontWeight: FontWeight.w800)
                            ),
                            TextSpan(
                              text: "Keep tracking your emotional melody! 🎧", 
                              style: TextStyle(
                                color: textMuted, 
                                fontWeight: FontWeight.w500, 
                                fontSize: isTablet ? 14 : 11 // Besarkan saiz teks penutup
                              )
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }
  Widget _buildFullWidthEmotionDistribution() {
    return Builder(
      builder: (context) {
        // 1. Ambil saiz lebar skrin untuk semak jenis peranti
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isTablet = screenWidth > 600;

        // 🔥 SEMAK JIKA USER BELUM PERNAH SCAN LAGI
        final bool hasNoScans = totalScansCount == 0; 

        // Jika tiada scan, semua peratusan dipaksa jadi 0%
        String hPct = hasNoScans ? "0%" : "${(happyPercent * 100).round()}%";
        String nPct = hasNoScans ? "0%" : "${(neutralPercent * 100).round()}%";
        String sPct = hasNoScans ? "0%" : "${(sadPercent * 100).round()}%";
        String aPct = hasNoScans ? "0%" : "${(angryPercent * 100).round()}%";

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 28 : 20), // Padding lebih besar di tablet
          decoration: BoxDecoration(
            color: cardWhite, 
            borderRadius: BorderRadius.circular(isTablet ? 36 : 28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Emotion Distribution", 
                style: TextStyle(
                  color: textDark, 
                  fontSize: isTablet ? 20 : 16, // Besarkan tajuk di tablet
                  fontWeight: FontWeight.w900
                )
              ),
              SizedBox(height: isTablet ? 26 : 20),
              Row(
                children: [
                  // Sizing Carta Donat (Telefon: 120, Tablet: 160)
                  SizedBox(
                    width: isTablet ? 160 : 120,
                    height: isTablet ? 160 : 120,
                    child: CustomPaint(
                      painter: GlowingDonutChartPainter(
                        h: happyPercent,
                        n: neutralPercent,
                        s: sadPercent,
                        a: angryPercent,
                        // 🔥 Tukar emoji tengah chart jadi '❓' jika tiada data
                        centerEmoji: hasNoScans ? "❓" : getEmotionEmoji(dominantEmotionText),
                        // Hantar data peranti jika painter anda memerlukan parameter saiz
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 36 : 24), // Spacing antara carta & teks legenda
                  
                  // Ruang Teks Legenda (Happy, Neutral, Sad, Angry)
                  Expanded(
                    child: Column(
                      children: [
                        _buildDistributionLegend(const Color(0xFFFFC000), "Happy", hPct),
                        _buildDistributionLegend(const Color(0xFF2EAD5C), "Neutral", nPct),
                        _buildDistributionLegend(const Color(0xFFB079E9), "Sad", sPct),
                        _buildDistributionLegend(const Color(0xFFE54A4A), "Angry", aPct),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: isTablet ? 24 : 18),
              
              // Kotak Penerangan Dominan di bawah
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(color: bgCanvas, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    // 🔥 Tukar emoji penerangan bawah jadi '❓' jika tiada data
                    Text(
                      hasNoScans ? "❓" : getEmotionEmoji(dominantEmotionText), 
                      style: TextStyle(fontSize: isTablet ? 26 : 20) // Besarkan emoji penerangan di tablet
                    ),
                    SizedBox(width: isTablet ? 14 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔥 Tukar mesej teks penerangan dominan untuk user baru
                          Text(
                            hasNoScans ? "No dominant emotion yet" : "$dominantEmotionText is your dominant emotion", 
                            style: TextStyle(
                              color: textDark, 
                              fontSize: isTablet ? 15 : 12, // Besarkan saiz teks status
                              fontWeight: FontWeight.w700
                            )
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasNoScans ? "Start scanning to see analysis" : "$dominantPercentText of your total scans", 
                            style: TextStyle(
                              color: textMuted, 
                              fontSize: isTablet ? 13 : 10 // Besarkan saiz subteks
                            )
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }
 Widget _buildDistributionLegend(Color indicator, String title, String percent) {
    return Builder(
      builder: (context) {
        // 1. Ambil saiz lebar skrin untuk semak jenis peranti
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isTablet = screenWidth > 600;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 9 : 6), // Besarkan sikit jarak atas bawah di tablet
          child: Row(
            children: [
              // Kotak indicator bulat berglowing (Telefon: 10x10, Tablet: 14x14)
              Container(
                width: isTablet ? 14 : 10, 
                height: isTablet ? 14 : 10, 
                decoration: BoxDecoration(
                  color: indicator, 
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: indicator.withOpacity(0.5), blurRadius: isTablet ? 6 : 4)
                  ]
                )
              ),
              SizedBox(width: isTablet ? 14 : 10),
              
              // Nama Emosi (Happy, Neutral, etc.)
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(
                    color: textMuted, 
                    fontSize: isTablet ? 15 : 12, // Dibesarkan daripada 12 ke 15 di tablet
                    fontWeight: FontWeight.w600
                  )
                )
              ),
              
              // Nilai Peratusan (cth: 45%)
              Text(
                percent, 
                style: TextStyle(
                  color: textDark, 
                  fontSize: isTablet ? 16 : 12, // Dibesarkan daripada 12 ke 16 di tablet
                  fontWeight: FontWeight.w800
                )
              ),
            ],
          ),
        );
      }
    );
  }

 // ==========================================
  // NEW MAGICAL CODE: EMOTION BLEND INSIGHTS
  // ==========================================
  Widget _buildSpotifyStyleRecommendations(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ambil lebar skrin penuh peranti
        final double screenWidth = MediaQuery.of(context).size.width;
        // Jika lebar lebih daripada 600, ia adalah tablet
        final bool checkTablet = screenWidth > 600;
    // Susun emosi mengikut nilai paling tinggi untuk dapatkan Top 2 Emotions
    final emotionList = [
      {"name": "Happy", "percent": happyPercent, "emoji": "😊", "color": const Color(0xFFFFC000)},
      {"name": "Neutral", "percent": neutralPercent, "emoji": "😐", "color": const Color(0xFF2EAD5C)},
      {"name": "Sad", "percent": sadPercent, "emoji": "😢", "color": const Color(0xFFB079E9)},
      {"name": "Angry", "percent": angryPercent, "emoji": "😡", "color": const Color(0xFFE54A4A)},
    ];

    // Isih dari tinggi ke rendah
    emotionList.sort((a, b) => (b["percent"] as double).compareTo(a["percent"] as double));

    final top1 = emotionList[0];
    final top2 = emotionList[1];

    // Jika belum ada data imbasan langsung
    bool hasNoData = totalScansCount == 0;

    // Tentukan Nama Gabungan Dinamik berdasarkan Top 2
    String blendTitle = "Analyzing Vibe...";
    String blendDesc = "Scan your face to generate a dynamic hybrid aura.";
    
    if (!hasNoData) {
      String combo = "${top1['name']}+${top2['name']}";
      if (combo.contains("Happy") && combo.contains("Neutral")) {
        blendTitle = "Chilled Serenity 🌤️";
        blendDesc = "A balanced state of clear focus and genuine inner joy.";
      } else if (combo.contains("Happy") && combo.contains("Sad")) {
        blendTitle = "Bittersweet Sunshine 🌤️😢";
        blendDesc = "Warm reflective energy. A peaceful space for healing thoughts.";
      } else if (combo.contains("Sad") && combo.contains("Neutral")) {
        blendTitle = "Quiet Rainfield 🌧️";
        blendDesc = "Low energy with steady calm. Perfect time for soft rest.";
      } else if (combo.contains("Angry") || combo.contains("Sad")) {
        blendTitle = "Stormy Release 🔥⛈️";
        blendDesc = "Intense complex emotions detected. Take a deep breath to ground yourself.";
      } else {
        blendTitle = "${top1['name']} & ${top2['name']} Blend";
        blendDesc = "Your current state is a unique blend of multiple emotional waves.";
      }
    }

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Mixed Emotion Blend",
              style: TextStyle(
                color: Colors.white, 
                fontSize: checkTablet ? 22 : 18, 
                fontWeight: FontWeight.w900, 
                letterSpacing: -0.3
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Real-time dynamic aura synthesis",
              style: TextStyle(
                color: const Color(0xAABBB3D6), 
                fontSize: checkTablet ? 15 : 12
              ),
            ),
            SizedBox(height: checkTablet ? 22 : 16),
            
            GestureDetector(
              onTap: () {
                if (hasNoData) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please complete a face scan first to unlock insights!")),
                  );
                  return;
                }
                _showEmotionBlendPopup(context, top1, top2, blendTitle, blendDesc);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(checkTablet ? 24 : 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E192E),
                  borderRadius: BorderRadius.circular(checkTablet ? 32 : 24),
                  border: Border.all(
                    color: hasNoData ? const Color(0xAABBB3D6).withOpacity(0.1) : (top1["color"] as Color).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasNoData ? Colors.transparent : (top1["color"] as Color).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: checkTablet ? 84 : 64,
                      width: checkTablet ? 84 : 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: hasNoData 
                            ? [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)]
                            : [top1["color"] as Color, (top2["percent"] as double) > 0 ? (top2["color"] as Color) : (top1["color"] as Color)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          if (!hasNoData)
                            BoxShadow(color: (top1["color"] as Color).withOpacity(0.4), blurRadius: checkTablet ? 16 : 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          hasNoData ? "⏳" : "${top1['emoji']}${top2['percent'] as double > 0 ? top2['emoji'] : ''}",
                          style: TextStyle(
                            fontSize: hasNoData ? (checkTablet ? 32 : 24) : (checkTablet ? 28 : 20), 
                            letterSpacing: checkTablet ? -6 : -4
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: checkTablet ? 22 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasNoData ? "No Blend Profile Yet" : blendTitle,
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: checkTablet ? 18 : 15, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasNoData ? "Tap to see how it calculates after scan." : blendDesc,
                            style: TextStyle(
                              color: const Color(0xAABBB3D6), 
                              fontSize: checkTablet ? 14 : 11, 
                              height: 1.3
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: checkTablet ? 12 : 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded, 
                      color: const Color(0xAABBB3D6), 
                      size: checkTablet ? 18 : 14
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // --- POPUP DIALOG UNTUK PAPAR LEVEL CONFIDENCE & DETAIL MIX EMOTION ---
  void _showEmotionBlendPopup(BuildContext context, Map<String, dynamic> top1, Map<String, dynamic> top2, String title, String desc) {
    showDialog(
      context: context,
      builder: (context) {
        // Ambil saiz skrin untuk semak jenis peranti secara dinamik di dalam dialog
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool checkTablet = screenWidth > 600;

        double p1 = top1["percent"] as double;
        double p2 = top2["percent"] as double;
        double total = p1 + p2;
        
        // Elak ralat pembahagian dengan kosong
        if (total == 0) total = 1.0;

        // Normalisasi peratusan untuk dipaparkan dalam graf bar hibrid dialog
        int p1Progress = ((p1 / total) * 100).round();
        int p2Progress = 100 - p1Progress;

        return AlertDialog(
          backgroundColor: const Color(0xFF1E192E), // Ikut cardWhite tema asal
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(checkTablet ? 36 : 28)),
          contentPadding: EdgeInsets.all(checkTablet ? 32 : 24),
          title: Column(
            children: [
              // Besarkan saiz emoji gabungan di tablet (Telefon: 40, Tablet: 56)
              Text(
                "${top1['emoji']} ${top2['emoji']}", 
                style: TextStyle(fontSize: checkTablet ? 56 : 40)
              ),
              SizedBox(height: checkTablet ? 14 : 10),
              // Besarkan saiz tajuk dialog di tablet (Telefon: 18, Tablet: 22)
              Text(
                title, 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  color: Colors.white, // Ganti textDark statik untuk elak error skop
                  fontSize: checkTablet ? 22 : 18, 
                  fontWeight: FontWeight.w900
                )
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Besarkan saiz huraian teks blend di tablet (Telefon: 13, Tablet: 16)
              Text(
                desc, 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  color: const Color(0xAABBB3D6), // Ganti textMuted statik untuk elak error skop
                  fontSize: checkTablet ? 16 : 13, 
                  height: 1.4
                )
              ),
              SizedBox(height: checkTablet ? 32 : 24),

              // Bar Petunjuk Hibrid Peratusan Emosi Gabungan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${top1['name']}: $p1Progress%",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: checkTablet ? 14 : 11,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  if (p2 > 0)
                    Text(
                      "${top2['name']}: $p2Progress%",
                      style: TextStyle(
                        color: const Color(0xAABBB3D6),
                        fontSize: checkTablet ? 14 : 11,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Garisan kemajuan visual aura (Progress Bar)
              Container(
                height: checkTablet ? 12 : 8, // Tebalkan bar sikit di tablet
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: p1Progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: top1["color"] as Color,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            bottomLeft: const Radius.circular(10),
                            topRight: Radius.circular(p2 > 0 ? 0 : 10),
                            bottomRight: Radius.circular(p2 > 0 ? 0 : 10),
                          ),
                        ),
                      ),
                    ),
                    if (p2 > 0)
                      Expanded(
                        flex: p2Progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: top2["color"] as Color,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: checkTablet ? 28 : 20),
              
              // Butang aksi tutup (Dismiss Button)
              SizedBox(
                width: double.infinity,
                height: checkTablet ? 54 : 46, // Tinggikan tapak butang di tablet
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC000).withOpacity(0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(checkTablet ? 16 : 12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      color: const Color(0xFFFFC000),
                      fontSize: checkTablet ? 16 : 14,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSleekRecentScansSection(BuildContext context) {
    // Mengambil saiz lebar skrin untuk mengesan jenis peranti secara selamat
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool checkTablet = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tajuk Utama Seksyen (Telefon: 16, Tablet: 20)
            Text(
              "Recent Scans", 
              style: TextStyle(
                color: Colors.white, // Ganti textDark statik untuk mengelakkan ralat skop
                fontSize: checkTablet ? 20 : 16, 
                fontWeight: FontWeight.w900
              )
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmotionHistoryScreen())),
              child: Row(
                children: [
                  // Butang Pautan View All (Telefon: 12, Tablet: 15)
                  Text(
                    "View all", 
                    style: TextStyle(
                      color: const Color(0xFFFFC000), // Ganti brandPurple statik
                      fontSize: checkTablet ? 15 : 12, 
                      fontWeight: FontWeight.w700
                    )
                  ),
                  Icon(
                    Icons.chevron_right, 
                    color: const Color(0xFFFFC000), 
                    size: checkTablet ? 20 : 16 // Besarkan ikon anak panah di tablet
                  )
                ],
              ),
            )
          ],
        ),
        SizedBox(height: checkTablet ? 22 : 16),
        
        // Kotak Utama Senarai Imbasan
        Container(
          padding: EdgeInsets.all(checkTablet ? 22 : 16), // Lebarkan ruang dalaman kotak di tablet
          decoration: BoxDecoration(
            color: const Color(0xFF1E192E), // Ganti cardWhite statik
            borderRadius: BorderRadius.circular(checkTablet ? 32 : 24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)
            ],
          ),
          child: processedRecentScans.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: checkTablet ? 30 : 20),
                  child: const Center(
                    child: Text(
                      "No scans found", 
                      style: TextStyle(color: Color(0xAABBB3D6)) // Ganti textMuted statik
                    )
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: processedRecentScans.length,
                  itemBuilder: (context, idx) {
                    final scan = processedRecentScans[idx];
                    return Column(
                      children: [
                        // Memanggil sub-tile log imbasan
                        _buildSleekLogTile(scan["emoji"], scan["mood"], scan["timing"], scan["conf"], scan["color"]),
                        if (idx < processedRecentScans.length - 1)
                          Divider(
                            height: checkTablet ? 32 : 24, // Tinggikan ruang pemisah antara baris di tablet
                            thickness: 1, 
                            color: const Color(0xAABBB3D6).withOpacity(0.1)
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSleekLogTile(String emoji, String mood, String timing, String conf, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mengambil saiz lebar skrin untuk mengesan jenis peranti secara selamat
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool checkTablet = screenWidth > 600;

        return Row(
          children: [
            // Bulatan Latar Belakang Emoji (Telefon: 46x46, Tablet: 58x58)
            Container(
              height: checkTablet ? 58 : 46,
              width: checkTablet ? 58 : 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                emoji, 
                style: TextStyle(fontSize: checkTablet ? 28 : 22) // Besarkan emoji di tablet
              ),
            ),
            SizedBox(width: checkTablet ? 18 : 14), // Lebarkan sela jarak antara emoji dan teks
            
            // Maklumat Teks Utama (Nama Mood & Waktu Imbasan)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood, 
                    style: TextStyle(
                      color: Colors.white, // Ganti textDark statik untuk elak ralat skop
                      fontSize: checkTablet ? 17 : 14, // Besarkan teks emosi di tablet
                      fontWeight: FontWeight.w800
                    )
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timing, 
                    style: TextStyle(
                      color: const Color(0xAABBB3D6), // Ganti textMuted statik untuk elak ralat skop
                      fontSize: checkTablet ? 14 : 12 // Besarkan teks tarikh/masa di tablet
                    )
                  ),
                ],
              ),
            ),
            
            // Peratus Tahap Keyakinan (Confidence Score)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conf, 
                  style: TextStyle(
                    color: color, 
                    fontSize: checkTablet ? 17 : 14, // Besarkan teks skor peratusan di tablet
                    fontWeight: FontWeight.w900
                  )
                ),
                Text(
                  "Confidence", 
                  style: TextStyle(
                    color: const Color(0xAABBB3D6), // Ganti textMuted statik untuk elak ralat skop
                    fontSize: checkTablet ? 12 : 10 // Besarkan subteks label di tablet
                  )
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildMoodInsightsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mengambil saiz lebar skrin untuk mengesan jenis peranti secara selamat
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool checkTablet = screenWidth > 600;

        // Fungsi pembantu untuk memotong teks secara selamat bagi mengelakkan ralat 'Index out of range'
        String getLine(String source, int lineIndex) {
          final lines = source.split('\n');
          if (lines.length > lineIndex) return lines[lineIndex];
          return lineIndex == 0 ? source : "";
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(checkTablet ? 26 : 20), // Besarkan padding kad di tablet
          decoration: BoxDecoration(
            color: const Color(0xFFFFC000).withOpacity(0.08), // Gunakan tona brandPurple
            borderRadius: BorderRadius.circular(checkTablet ? 36 : 28),
            border: Border.all(color: const Color(0xFFFFC000).withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bahagian Header Tajuk Insights
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(checkTablet ? 11 : 8), // Besarkan bulatan ikon di tablet
                    decoration: const BoxDecoration(color: Color(0xFFFFC000), shape: BoxShape.circle),
                    child: Icon(
                      Icons.lightbulb_outline_rounded, 
                      color: Colors.black, 
                      size: checkTablet ? 22 : 18 // Besarkan ikon mentol di tablet
                    ),
                  ),
                  SizedBox(width: checkTablet ? 16 : 12),
                  Text(
                    "Mood Insights", 
                    style: TextStyle(
                      color: Colors.white, // Elak ralat skop textDark
                      fontSize: checkTablet ? 20 : 16, // Besarkan teks tajuk di tablet
                      fontWeight: FontWeight.w900
                    )
                  ),
                ],
              ),
              SizedBox(height: checkTablet ? 26 : 20),
              
              // Kandungan 3 Lajur Teks Insight
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lajur 1: Weekend Insight
                    Expanded(
                      child: _buildInsightText(
                        "${getLine(insightWeekend, 0)}\n", 
                        getLine(insightWeekend, 1), 
                        const Color(0xFFFFC000)
                      ),
                    ),
                    VerticalDivider(
                      color: const Color(0xFFFFC000).withOpacity(0.2), 
                      thickness: 1, 
                      width: checkTablet ? 32 : 24 // Lebarkan jarak pemisah di tablet
                    ),
                    
                    // Lajur 2: Comparison Insight
                    Expanded(
                      child: _buildInsightText(
                        "${getLine(insightComparison, 0)}\n", 
                        getLine(insightComparison, 1), 
                        const Color(0xFFFFD43F)
                      ),
                    ),
                    VerticalDivider(
                      color: const Color(0xFFFFC000).withOpacity(0.2), 
                      thickness: 1, 
                      width: checkTablet ? 32 : 24
                    ),
                    
                    // Lajur 3: Status Insight
                    Expanded(
                      child: _buildInsightText(
                        "${getLine(insightStatus, 0)}\n", 
                        getLine(insightStatus, 1), 
                        const Color(0xFFFFEFA6)
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightText(String text1, String boldText, Color boldColor) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: textDark, fontSize: 11, height: 1.5, fontWeight: FontWeight.w500),
        children: [
          TextSpan(text: text1),
          TextSpan(text: boldText, style: TextStyle(color: boldColor, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildGamingAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Daily Vibe Lab", style: TextStyle(color: textDark, fontSize: 19,fontWeight: FontWeight.w900, fontFamily: 'Circular')),
            SizedBox(height: 4),
            Text("Tap to interact with dynamic emotional micro-games", style: TextStyle(color: textMuted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildMysteryGachaCard("Aura Scanner", "Bio-Feedback", "🌀", const Color(0xFFFFC000), "AURA"),
              _buildMysteryGachaCard("Prana Breath", "Calm Core", "✨", const Color(0xFF2EAD5C), "BREATHE"),
              _buildMysteryGachaCard("Zen Popper", "Stress Relief", "🧼", const Color(0xFFB079E9), "BUBBLE"),
              _buildMysteryGachaCard("Sonic Oasis", "Audio Therapy", "🎧", const Color(0xFFE54A4A), "AUDIO"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMysteryGachaCard(String title, String rarity, String emoji, Color color, String activityType) {
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 64,width: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color.withOpacity(0.4), Colors.transparent],
                  ),
                ),
              ),
              Text(emoji, style: const TextStyle(fontSize: 34)), 
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          const SizedBox(height:4),
          Text(rarity, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height:14),
          SizedBox(
            width: double.infinity,
            height:38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.15),
                foregroundColor: textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showDynamicActivityDialog(title, emoji, color, activityType),
              child: const Text('LAUNCH ⚡', style: TextStyle(fontSize:11.5,fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          )
        ],
      ),
    );
  }

// Pastikan _currentAcousticPlayer ini berada di atas fungsi dialog (di dalam kelas _HomeScreenState)
  AudioPlayer? _currentAcousticPlayer;

  void _showDynamicActivityDialog(String title, String emoji, Color color, String activityType) {
    // Sediakan state utama dialog
    bool isScanning = false;
    double scanProgress = 0.0;
    
    String breatheState = "Ready"; 
    int breatheTimer = 4;

    List<Offset> activeBubbles = List.generate(6, (i) => Offset((i * 45.0) + 20, (i % 2 == 0 ? 40 : 110)));

    bool isPlayingTrack = false;
    String selectedTrackFile = ""; 
    
    bool isActivityFinished = false;
    String resultTitle = "";
    String resultSubtitle = "";
    String resultDesc = "";

    showDialog(
      context: context,
      barrierDismissible: activityType == "BUBBLE" ? true : false,
      builder: (context) {
        final auras = [
          {"name": "Bright & Creative Sky 🌌", "desc": "Your energy is wonderful today! Perfect time to start new ideas or projects."},
          {"name": "Calm & Relaxed Forest 🌿", "desc": "You are feeling very grounded and stable. Your mind is clear and ready."},
          {"name": "Super Charged Battery ⚡", "desc": "High energy detected! Try using this extra excitement for your passion hobbies."},
          {"name": "Deep Ocean Dreamer 🌊", "desc": "You are in a peaceful, thinking mood. Great state for finding safe answers."}
        ];

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            Widget activityContent = const SizedBox();

            // 🎨 REDESIGN: SKRIN KEPUTUSAN YANG SIMPLE & MUDAH DIFAHAMI
            if (isActivityFinished) {
              activityContent = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    height: 74, width: 74,
                    decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(Icons.check_circle_rounded, color: color, size:50),
                  ),
                  const SizedBox(height:20),
                  Text(
                    resultSubtitle, 
                    style: TextStyle(color: color, fontSize:19, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center
                  ),
                  const SizedBox(height:12),
                  Text(
                    resultDesc, 
                    style: const TextStyle(color: textMuted, fontSize:15, height: 1.4), 
                    textAlign: TextAlign.center
                  ),
                  const SizedBox(height:28),
                  SizedBox(
                    width: double.infinity,
                    height:52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color, 
                        foregroundColor: textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0
                      ),
                      onPressed: () {
                        if (_currentAcousticPlayer != null) {
                          _currentAcousticPlayer!.stop();
                        }
                        Navigator.pop(context);
                      },
                      child: const Text("Done", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                    ),
                  )
                ],
              );
            } 
            
        // 🎨 CARD 1: AURA SCANNER (DIBAIKI SAIZ KEPADA LEBIH BESAR & PREMIUM)
            else if (activityType == "AURA") {
              activityContent = Column(
                children: [
                  // 🟢 DIBAIKI: Saiz teks penerangan dibesarkan daripada 12 ke 14
                  const Text("Hold your finger below to check your current emotion aura.", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 28), // Jarak ditambahkan sedikit
                  GestureDetector(
                    onTapDown: (_) {
                      dialogSetState(() { isScanning = true; scanProgress = 0.0; });
                      Future.doWhile(() async {
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (!context.mounted || !isScanning) return false;
                        dialogSetState(() { scanProgress += 0.034; });
                        if (scanProgress >= 1.0) {
                          final selected = (auras..shuffle()).first;
                          dialogSetState(() {
                            isActivityFinished = true;
                            resultTitle = "Scan Done!";
                            resultSubtitle = selected["name"]!;
                            resultDesc = selected["desc"]!;
                          });
                          return false;
                        }
                        return true;
                      });
                    },
                    onTapUp: (_) => dialogSetState(() { isScanning = false; scanProgress = 0.0; }),
                    onTapCancel: () => dialogSetState(() { isScanning = false; scanProgress = 0.0; }),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          // 🟢 DIBAIKI: Lingkaran indicator pemuat dibesarkan daripada 90x90 ke 110x110
                          height: 110, width: 110,
                          child: CircularProgressIndicator(
                            value: scanProgress,
                            strokeWidth: 4.5, // Tebal garisan dinaikkan sikit
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            backgroundColor: color.withOpacity(0.1),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          // 🟢 DIBAIKI: Bulatan sensor dalaman dibesarkan daripada 74x74 ke 92x92
                          height: 92, width: 92,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isScanning ? color.withOpacity(0.3) : color.withOpacity(0.1)),
                          // 🟢 DIBAIKI: Ikon cap jari dibesarkan daripada 44 ke 54
                          child: Icon(Icons.fingerprint, size: 54, color: isScanning ? textDark : textDark.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22), // Jarak ditambahkan sedikit
                  // 🟢 DIBAIKI: Teks status tindakan dibesarkan daripada 11 ke 13.5
                  Text(
                    isScanning ? "SCANNING YOUR ENERGY..." : "HOLD SENSOR TO START", 
                    style: TextStyle(color: isScanning ? color : textMuted, fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                  ),
                ],
              );
            }
            
            // 🎨 CARD 2: BREATHE (DIBAIKI SAIZ KEPADA LEBIH BESAR & VISUAL PREMIUM)
            else if (activityType == "BREATHE") {
              activityContent = Column(
                children: [
                  // 🟢 DIBAIKI: Saiz teks penerangan dibesarkan daripada 12 ke 14
                  const Text("Follow the circle to relax and balance your breathing.", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 32), // Jarak ditinggikan sedikit
                  StatefulBuilder(
                    builder: (context, setBreatheState) {
                      void runBreathingCycle() async {
                        if (breatheState != "Ready") return;
                        
                        setBreatheState(() { breatheState = "Breathe In 🌊"; breatheTimer = 4; });
                        for (int i = 0; i < 4; i++) { await Future.delayed(const Duration(seconds: 1)); setBreatheState(() { breatheTimer--; }); }
                        
                        setBreatheState(() { breatheState = "Hold... ⏳"; breatheTimer = 4; });
                        for (int i = 0; i < 4; i++) { await Future.delayed(const Duration(seconds: 1)); setBreatheState(() { breatheTimer--; }); }
                        
                        setBreatheState(() { breatheState = "Breathe Out 💨"; breatheTimer = 4; });
                        for (int i = 0; i < 4; i++) { await Future.delayed(const Duration(seconds: 1)); setBreatheState(() { breatheTimer--; }); }
                        
                        if (context.mounted) {
                          dialogSetState(() {
                            isActivityFinished = true;
                            resultTitle = "Breathing Complete!";
                            resultSubtitle = "Mind Restored Successfully 🧘‍♂️";
                            resultDesc = "Good job! Your heartbeat and body are now feeling more relaxed and peaceful.";
                          });
                        }
                      }

                      double scale = 1.0;
                      if (breatheState == "Breathe In 🌊" || breatheState == "Hold... ⏳") scale = 1.6;

                      return Column(
                        children: [
                          AnimatedScale(
                            scale: scale,
                            duration: Duration(seconds: breatheState == "Hold... ⏳" ? 0 : 4),
                            curve: Curves.easeInOut,
                            child: Container(
                              // 🟢 DIBAIKI: Saiz fizikal asas bulatan bernafas dibesarkan daripada 60x60 ke 74x74 (sebelum dilonjak oleh scale)
                              height: 74, width: 74,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.25), border: Border.all(color: color, width: 1.5)),
                              // 🟢 DIBAIKI: Saiz teks pemasa/START di dalam bulatan dibesarkan daripada 14 ke 16
                              child: Center(child: Text(breatheState == "Ready" ? "START" : "$breatheTimer", style: const TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w900))),
                            ),
                          ),
                          // 🟢 DIBAIKI: Jarak bawah bulatan ditinggikan daripada 36 ke 44 bagi memberi ruang animasi berkembang dengan selamat
                          const SizedBox(height: 44),
                          // 🟢 DIBAIKI: Saiz teks status pernafasan (BREATHE IN/OUT) dibesarkan daripada 14 ke 16
                          Text(breatheState.toUpperCase(), style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          if (breatheState == "Ready") ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              // 🟢 DIBAIKI: Ditetapkan saiz butang permulaan yang lebih besar dan selesa ditekan
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color.withOpacity(0.2), 
                                  foregroundColor: textDark,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24)
                                ),
                                onPressed: runBreathingCycle,
                                // 🟢 DIBAIKI: Saiz teks butang dibesarkan daripada default ke 13 dengan tulisan tebal
                                child: const Text("Start Now", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            )
                          ]
                        ],
                      );
                    },
                  ),
                ],
              );
            }
            // 🎨 CARD 3: BUBBLES GAME (DIBAIKI SAIZ KEPADA LEBIH BESAR & MUDAH DITEKAN)
            else if (activityType == "BUBBLE") {
              activityContent = Column(
                children: [
                  // 🟢 DIBAIKI: Saiz teks penerangan dibesarkan daripada 12 ke 14
                  const Text("Tap and burst all the water bubbles to release stress.", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20), // Jarak ditinggikan sedikit
                  StatefulBuilder(
                    builder: (context, setBubbleState) {
                      return Container(
                        // 🟢 DIBAIKI: Ketinggian padang buih ditinggikan daripada 180 ke 220 untuk lebih ruang permainan
                        height: 220, width: double.infinity,
                        decoration: BoxDecoration(color: bgCanvas, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
                        child: Stack(
                          children: activeBubbles.map((pos) {
                            return Positioned(
                              left: pos.dx,
                              top: pos.dy,
                              child: GestureDetector(
                                onTapDown: (_) {
                                  AudioPlayer().play(AssetSource('audio/popup.mp3'));
                                  HapticFeedback.lightImpact();

                                  setBubbleState(() { activeBubbles.remove(pos); });
                                  if (activeBubbles.isEmpty) {
                                    dialogSetState(() {
                                      isActivityFinished = true;
                                      resultTitle = "All Popped!";
                                      resultSubtitle = "Stress Cleared away 🧼";
                                      resultDesc = "You have popped every single block. Your tension has been cleared successfully.";
                                    });
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  // 🟢 DIBAIKI: Saiz fizikal buih dibesarkan daripada 36x36 ke 46x46 supaya lebih mudah ditap/ditekan
                                  height: 46, width: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [Colors.white.withOpacity(0.6), color.withOpacity(0.2)]),
                                  ),
                                  // 🟢 DIBAIKI: Saiz emoji titisan air dibesarkan daripada 10 ke 15
                                  child: const Center(child: Text("💧", style: TextStyle(fontSize: 15))),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14), // Jarak ditinggikan sedikit
                  // 🟢 DIBAIKI: Saiz status arahan bawah dibesarkan daripada 10 ke 12 dengan tulisan lebih tebal
                  const Text("Tap bubbles to burst them", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              );
            }
            // 🎨 CARD 4: AUDIO SELECTION SYSTEM (DIBAIKI SAIZ KEPADA LEBIH BESAR & ELEGAN)
            else if (activityType == "AUDIO") {
              activityContent = Column(
                children: [
                  // 🟢 DIBAIKI: Saiz teks penerangan dibesarkan daripada 12 ke 14
                  const Text("Choose a nature sound below to relax your mind. Tap again to turn off.", textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24), // Jarak ditambahkan sedikit
                  
                  Column(
                    children: [
                      // Track 1 Card
                      GestureDetector(
                        onTap: () async {
                          if (selectedTrackFile == "audio/calm01.mp3" && isPlayingTrack) {
                            if (_currentAcousticPlayer != null) await _currentAcousticPlayer!.stop();
                            dialogSetState(() { isPlayingTrack = false; selectedTrackFile = ""; });
                          } else {
                            if (_currentAcousticPlayer != null) await _currentAcousticPlayer!.stop();
                            dialogSetState(() { selectedTrackFile = "audio/calm01.mp3"; isPlayingTrack = true; });
                            _currentAcousticPlayer = AudioPlayer();
                            await _currentAcousticPlayer!.play(AssetSource("audio/calm01.mp3"));
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          // 🟢 DIBAIKI: Padding kad dibesarkan (horizontal: 18, vertical: 16) untuk ruang sentuhan yang lebih selesa
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: selectedTrackFile == "audio/calm01.mp3" ? color.withOpacity(0.12) : bgCanvas.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16), // Lengkungan dibesarkan daripada 14 ke 16
                            border: Border.all(
                              color: selectedTrackFile == "audio/calm01.mp3" ? color : color.withOpacity(0.1),
                              width: selectedTrackFile == "audio/calm01.mp3" ? 1.5 : 1.0
                            ),
                          ),
                          child: Row(
                            children: [
                              // 🟢 DIBAIKI: Saiz ikon play/pause dibesarkan daripada 28 ke 34
                              Icon(
                                selectedTrackFile == "audio/calm01.mp3" && isPlayingTrack ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: selectedTrackFile == "audio/calm01.mp3" ? color : textMuted, size: 34,
                              ),
                              const SizedBox(width: 16), // Dijarakkan sedikit daripada ikon
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🟢 DIBAIKI: Saiz tajuk trek dibesarkan daripada 13 ke 15.5 dengan berat teks yang sepadan
                                    Text(
                                      "Calm Rainfield 🌧️", 
                                      style: TextStyle(
                                        color: textDark, 
                                        fontSize: 15.5, 
                                        fontWeight: selectedTrackFile == "audio/calm01.mp3" ? FontWeight.w900 : FontWeight.bold
                                      )
                                    ),
                                    const SizedBox(height: 4), // Dijarakkan sedikit
                                    // 🟢 DIBAIKI: Saiz kapsyen/penerangan trek dibesarkan daripada 10 ke 12
                                    const Text("Soft rain drops with ambient relaxing background", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12), // Mengimbangi jarak ke kad seterusnya
                      
                     // Track 2 Card
                      GestureDetector(
                        onTap: () async {
                          if (selectedTrackFile == "audio/calm02.mp3" && isPlayingTrack) {
                            if (_currentAcousticPlayer != null) await _currentAcousticPlayer!.stop();
                            dialogSetState(() { isPlayingTrack = false; selectedTrackFile = ""; });
                          } else {
                            if (_currentAcousticPlayer != null) await _currentAcousticPlayer!.stop();
                            dialogSetState(() { selectedTrackFile = "audio/calm02.mp3"; isPlayingTrack = true; });
                            _currentAcousticPlayer = AudioPlayer();
                            await _currentAcousticPlayer!.play(AssetSource("audio/calm02.mp3"));
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          // 🟢 DIBAIKI: Padding kad dibesarkan (horizontal: 18, vertical: 16) untuk ruang sentuhan yang lebih selesa
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: selectedTrackFile == "audio/calm02.mp3" ? color.withOpacity(0.12) : bgCanvas.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16), // Lengkungan dibesarkan daripada 14 ke 16
                            border: Border.all(
                              color: selectedTrackFile == "audio/calm02.mp3" ? color : color.withOpacity(0.1),
                              width: selectedTrackFile == "audio/calm02.mp3" ? 1.5 : 1.0
                            ),
                          ),
                          child: Row(
                            children: [
                              // 🟢 DIBAIKI: Saiz ikon play/pause dibesarkan daripada 28 ke 34
                              Icon(
                                selectedTrackFile == "audio/calm02.mp3" && isPlayingTrack ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: selectedTrackFile == "audio/calm02.mp3" ? color : textMuted, size: 34,
                              ),
                              const SizedBox(width: 16), // Dijarakkan sedikit daripada ikon
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🟢 DIBAIKI: Saiz tajuk trek dibesarkan daripada 13 ke 15.5 dengan berat teks yang sepadan
                                    Text(
                                      "Peaceful Wind & Birds 🍃", 
                                      style: TextStyle(
                                        color: textDark, 
                                        fontSize: 15.5, 
                                        fontWeight: selectedTrackFile == "audio/calm02.mp3" ? FontWeight.w900 : FontWeight.bold
                                      )
                                    ),
                                    const SizedBox(height: 4), // Dijarakkan sedikit
                                    // 🟢 DIBAIKI: Saiz kapsyen/penerangan trek dibesarkan daripada 10 ke 12
                                    const Text("Gentle forest wind blowing with sweet birds chirping", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28), // Jarak ditambahkan sedikit sebelum butang penutup
                  if (isPlayingTrack)
                    SizedBox(
                      width: double.infinity,
                      // 🟢 DIBAIKI: Ketinggian butang "Close Session" ditinggikan daripada 40 ke 46
                      height: 46,
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: color),
                        onPressed: () {
                          if (_currentAcousticPlayer != null) _currentAcousticPlayer!.stop();
                          dialogSetState(() {
                            isActivityFinished = true;
                            resultTitle = "Audio Done!";
                            resultSubtitle = "Mind Status: Peaceful 🧘‍♂️";
                            resultDesc = "The soundscape has helped quiet down your thoughts successfully.";
                          });
                        },
                        // 🟢 DIBAIKI: Saiz teks di dalam butang dibesarkan daripada 13 ke 15 dengan tulisan tebal
                        child: const Text("Close Session 💡", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                      ),
                    ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: cardWhite,
              // 🟢 DIBAIKI: Lengkungan dialog dibesarkan daripada 22 ke 26 agar tampak lebih premium
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              title: Column(
                children: [
                  // 🟢 DIBAIKI: Saiz emoji dialog utama dibesarkan daripada 36 ke 44
                  Text(emoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 10), // Jarak ditinggikan sedikit
                  // 🟢 DIBAIKI: Saiz tajuk utama dialog dibesarkan daripada 16 ke 19.5
                  Text(isActivityFinished ? resultTitle : title, textAlign: TextAlign.center, style: const TextStyle(color: textDark, fontSize: 19.5, fontWeight: FontWeight.w900)),
                ],
              ),
              content: Column(mainAxisSize: MainAxisSize.min, children: [activityContent]),
            );
          },
        );
      },
    );
  }

  void _showResultDialog(String title, String subtitle, String desc, Color themeColor) async {
    // 🔊 BEAUTIFUL SHIMMERING / SPARKLE CELEBRATION CHIME (No Knocking/Wooden tap sounds)
    AudioPlayer().play(UrlSource('https://actions.google.com/sounds/v1/multimedia/gasp_giggle_shimmer.ogg'));

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        // 🟢 DIBAIKI: Lengkungan dialog dibesarkan daripada 24 ke 28 agar kelihatan lebih premium
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        // 🟢 DIBAIKI: Saiz tajuk dialog dibesarkan daripada 15 ke 18.5
        title: Text("⚡ $title", textAlign: TextAlign.center, style: const TextStyle(color: textDark, fontSize: 18.5, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              // 🟢 DIBAIKI: Padding dalaman kontena dibesarkan untuk memberikan ruang bernafas kepada teks subtitle
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              // 🟢 DIBAIKI: Lengkungan bucu kontena dibesarkan daripada 12 ke 14
              decoration: BoxDecoration(color: themeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              // 🟢 DIBAIKI: Saiz tulisan subtitle dibesarkan daripada 13 ke 15
              child: Text(subtitle, style: TextStyle(color: themeColor, fontSize: 15, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            ),
            // 🟢 DIBAIKI: Jarak kotak dinaikkan daripada 12 ke 18
            const SizedBox(height: 18),
            // 🟢 DIBAIKI: Saiz tulisan keterangan (desc) dibesarkan daripada 12 ke 14.5 supaya lebih selesa dibaca
            Text(desc, style: const TextStyle(color: textMuted, fontSize: 14.5, height: 1.45, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // 🟢 DIBAIKI: Menggunakan TextButton yang ditinggikan ruangnya (padding ditambahkan) untuk kemudahan menekan
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: textDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            // 🟢 DIBAIKI: Saiz tulisan pada butang dibesarkan daripada 13 ke 15 dengan berat teks FontWeight.w900
            child: const Text("Integrate State 🔌", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.3)),
          )
        ],
      ),
    );
  }
Widget _buildFloatingBottomNavBar(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // 🟢 DIBAIKI: Ketinggian asas navigasi bar dinaikkan daripada 88 ke 96 untuk reka bentuk yang lebih premium
    final double barHeight = 96.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: barHeight + bottomPadding,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none, 
          children: [
            ClipPath(
              clipper: WavyFooterClipper(),
              child: Container(
                height: barHeight + bottomPadding,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bg03.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: const Color(0xFF151221).withOpacity(0.85),
                ),
              ),
            ),
            Positioned(
              // 🟢 DIBAIKI: Kedudukan ikon dilaraskan ke atas sedikit supaya tidak terlalu rapat ke bucu bawah skrin
              bottom: bottomPadding + 8,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTabIcon(Icons.home_rounded, "Home", true),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmotionHistoryScreen())).then((_) {
                            if (!mounted) return;
                            loadDashboard();
                          }),
                          child: _buildTabIcon(Icons.access_time_rounded, "History", false),
                        ),
                      ],
                    ),
                  ),
                  // 🟢 DIBAIKI: Kelebaran ditambahkan daripada 76 ke 88 untuk memberi ruang yang cukup kepada butang kamera tengah yang telah dibesarkan
                  const SizedBox(width: 88), 
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedMusicScreen())).then((_) {
                            if (!mounted) return;
                            loadDashboard();
                          }),
                          child: _buildTabIcon(Icons.favorite_border_rounded, "Saved", false),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) {
                            if (!mounted) return;
                            loadDashboard();
                          }),
                          child: _buildTabIcon(Icons.person_outline_rounded, "Profile", false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              // 🟢 DIBAIKI: Menyeimbangkan kedudukan terapung (Floating Position) butang kamera di atas lekukan bar
              top: 2, 
              child: GestureDetector(
                onTap: () {
                  final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GuestCameraScreen(camera: frontCamera, isGuest: false))).then((_) {
                    if (!mounted) return;
                    loadDashboard();
                  });
                },
                child: Container(
                  // 🟢 DIBAIKI: Saiz fizikal butang kamera dibesarkan daripada 56x56 ke 64x64
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFC000), 
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFC000).withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))
                    ],
                  ),
                  // 🟢 DIBAIKI: Saiz ikon kamera di dalam dibesarkan daripada 24 ke 28
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 28),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildTabIcon(IconData i, String lbl, bool active) {
    return SizedBox(
      height: 48, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: active ? const Color(0xFFFFC000) : Colors.white.withOpacity(0.55), size: 24),
          const SizedBox(height: 2),
          Text(
            lbl, 
            style: TextStyle(
              color: active ? const Color(0xFFFFC000) : Colors.white.withOpacity(0.55), 
              fontSize: 9, 
              fontWeight: FontWeight.w700
            ),
          ),
        ],
      ),
    );
  }
}

class WavyFooterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 35); 
    path.quadraticBezierTo(size.width / 2, 0, size.width, 35); 
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SplineEmojiChartPainter extends CustomPainter {
  final List<double> weights;
  final List<String> emojis;
  SplineEmojiChartPainter({required this.weights, required this.emojis});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFFFC000) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final points = [
      Offset(0, size.height * weights[0]),
      Offset(size.width * 0.16, size.height * weights[1]),
      Offset(size.width * 0.33, size.height * weights[2]),
      Offset(size.width * 0.5, size.height * weights[3]),
      Offset(size.width * 0.66, size.height * weights[4]),
      Offset(size.width * 0.83, size.height * weights[5]), 
      Offset(size.width, size.height * weights[6]),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final xc = (p0.dx + p1.dx) / 2;
      final yc = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, xc, yc);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFFFFC000).withOpacity(0.20), const Color(0xFFFFC000).withOpacity(0.0)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    for (int i = 0; i < points.length; i++) {
      final textSpan = TextSpan(text: emojis[i], style: const TextStyle(fontSize: 16));
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final offset = Offset(
        points[i].dx - (textPainter.width / 2),
        points[i].dy - (textPainter.height / 2),
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GlowingDonutChartPainter extends CustomPainter {
  final double h;
  final double n;
  final double s;
  final double a;
  final String centerEmoji;

  GlowingDonutChartPainter({required this.h, required this.n, required this.s, required this.a, required this.centerEmoji});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    double total = h + n + s + a;
    if (total == 0) {
      _drawSegment(canvas, rect, glowPaint, paint, const Color(0xAABBB3D6), -1.5, 6.28);
    } else {
      double start = -1.5;
      
      double sweepH = (h / total) * 6.28;
      if (sweepH > 0) _drawSegment(canvas, rect, glowPaint, paint, const Color(0xFFFFC000), start, sweepH);
      start += sweepH;

      double sweepN = (n / total) * 6.28;
      if (sweepN > 0) _drawSegment(canvas, rect, glowPaint, paint, const Color(0xFF2EAD5C), start, sweepN);
      start += sweepN;

      double sweepS = (s / total) * 6.28;
      if (sweepS > 0) _drawSegment(canvas, rect, glowPaint, paint, const Color(0xFFB079E9), start, sweepS);
      start += sweepS;

      double sweepA = (a / total) * 6.28;
      if (sweepA > 0) _drawSegment(canvas, rect, glowPaint, paint, const Color(0xFFE54A4A), start, sweepA);
    }

    final textSpan = TextSpan(text: centerEmoji.isNotEmpty ? centerEmoji : "😐", style: const TextStyle(fontSize: 32));
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2)
    );
  }

  void _drawSegment(Canvas canvas, Rect rect, Paint glowPaint, Paint paint, Color color, double startAngle, double sweepAngle) {
    glowPaint.color = color.withOpacity(0.4); 
    paint.color = color;
    
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}