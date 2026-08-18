import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Diperlukan untuk ImageFilter (Glassmorphism)

import '../../services/session_service.dart';

class SavedMusicScreen extends StatefulWidget {
  final bool isEmbedded; 
  const SavedMusicScreen({super.key, this.isEmbedded = true});

  @override
  State<SavedMusicScreen> createState() => _SavedMusicScreenState();
}

class _SavedMusicScreenState extends State<SavedMusicScreen> {
  List savedSongs = [];
  bool isLoading = true;

  // Tetapan Warna Tema Konsisten Premium
  static const Color brandYellow = Color(0xFFFFC000); 
  static const Color bgCanvas = Color(0xFF151221); 
  static const Color cardDark = Color(0xFF1E192E); 
  static const Color textDark = Colors.white; 
  static const Color textMuted = Color(0xAABBB3D6); 

  @override
  void initState() {
    super.initState();
    loadSavedMusic();
  }

  // 1. MEMBACA DATA: Membaca sub-collection secara auto
  Future<void> loadSavedMusic() async {
    try {
      final user = await SessionService.getUser();
      final String? userId = user != null ? (user["id"] ?? user["uid"])?.toString() : null;

      if (userId == null || userId.isEmpty) {
        setState(() { isLoading = false; });
        return;
      }

      // Membaca sub-collection 'saved_music' di bawah user doc secara terus
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("saved_music")
          .orderBy("created_at", descending: true)
          .get();

      List tempSongs = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        tempSongs.add({
          "id": doc.id,
          "title": data["title"] ?? "Unknown Track",
          "channel_name": data["channel_name"] ?? "Unknown Artist",
          "emotion": data["emotion"] ?? "neutral",
          "video_id": data["video_id"] ?? "",
        });
      }

      setState(() {
        savedSongs = tempSongs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("LOAD SAVED MUSIC ERROR: $e");
      setState(() { isLoading = false; });
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: bgCanvas,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: brandYellow))
         : Stack(
    children: [
      ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 105, 
          bottom: widget.isEmbedded ? 140 : 40,
          left: 22,
          right: 22,
        ),
              children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Your Collection",
                          style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.2), // 🟢 DIBAIKI: Saiz fon dibesarkan daripada 18 ke 20
                        ),
                        Text(
                          "${savedSongs.length} tracks",
                          style: const TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w700), // 🟢 DIBAIKI: Saiz teks pembilang koleksi dibesarkan daripada 12 ke 14
                        )
                      ],
                    ),
                    const SizedBox(height: 18), // 🟢 DIBAIKI: Jarak kotak dinaikkan daripada 14 ke 18

                    if (savedSongs.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20), // 🟢 DIBAIKI: Jarak margin luar dinaikkan daripada 16 ke 20
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 🟢 DIBAIKI: Padding dalaman petunjuk leret dibesarkan
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(16), // 🟢 DIBAIKI: Lengkungan dibesarkan daripada 14 ke 16
                          border: Border.all(color: brandYellow.withOpacity(0.15), width: 1),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.swap_horizontal_circle_outlined, color: brandYellow, size: 20), // 🟢 DIBAIKI: Saiz ikon petunjuk dibesarkan daripada 18 ke 20
                            SizedBox(width: 12), // 🟢 DIBAIKI: Jarak horizontal dibesarkan daripada 10 ke 12
                            Expanded(
                              child: Text(
                                "💡 Swipe LEFT on any track to remove it from library.",
                                style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w700), // 🟢 DIBAIKI: Saiz teks petunjuk dibesarkan daripada 11 ke 12
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 🟢 MASUKKAN SEMAKAN KOSONG DI SINI UNTUK SENARAI SAHAJA
                    savedSongs.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: _buildEmptyStateWidget(),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: savedSongs.length,
                            itemBuilder: (context, index) {
                              // ... (kekalkan semua kod di dalam itemBuilder / Dismissible sedia ada anda) ...
                            },
                          ),

                    ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: savedSongs.length,
  itemBuilder: (context, index) {
                              final song = savedSongs[index];
                              final String emotionStr = song["emotion"] ?? "neutral";
                              final Color emoColor = getEmotionColor(emotionStr);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15), // 🟢 DIBAIKI: Jarak bawah antara setiap kad dinaikkan daripada 12 ke 15
                                child: Dismissible(
                                  key: Key(song["id"].toString()),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: cardDark,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(26), // 🟢 DIBAIKI: Lengkungan dialog dibesarkan daripada 22 ke 26
                                            side: const BorderSide(color: Colors.white10, width: 1), 
                                          ),
                                          title: const Text(
                                            "Remove Music",
                                            style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w900), // 🟢 DIBAIKI: Saiz tajuk dialog dipadam dibesarkan
                                          ),
                                          alignment: Alignment.center,
                                          content: Text(
                                            "Are you sure you want to remove \"${song["title"]}\"?",
                                            style: const TextStyle(color: textMuted, fontSize: 15, height: 1.4), // 🟢 DIBAIKI: Teks kandungan dialog dibesarkan daripada 14 ke 15
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text("Cancel", style: TextStyle(color: textMuted, fontSize: 15, fontWeight: FontWeight.w700)), // 🟢 DIBAIKI: Teks dibesarkan ke 15
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFE54A4A),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // 🟢 DIBAIKI: Ditambah padding butang padam
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text("Remove", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)), // 🟢 DIBAIKI: Teks butang dibesarkan ke 15
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (direction) async {
  // 1. Simpan salinan data asal (back-up) sekiranya proses Firebase gagal
  final removedSong = savedSongs[index];
  final removedIndex = index;

  // 2. SEGERA buang daripada senarai lokal & kemas kini UI (supaya item terus hilang tanpa tersangkut)
  setState(() {
    savedSongs.removeAt(index);
  });

  try {
    final user = await SessionService.getUser();
    final String userId = (user["id"] ?? user["uid"] ?? "").toString().trim();

    // 3. Padam rekod daripada Cloud Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_music')
        .doc(removedSong["id"])
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2EAD5C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text("Track removed from playlist", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    debugPrint("❌ DELETE MUSIC FIREBASE ERROR: $e");
    // Jika ralat berlaku di Firebase, kembalikan semula item ke senarai asal
    if (mounted) {
      setState(() {
        savedSongs.insert(removedIndex, removedSong);
      });
    }
  }
},
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 26), // 🟢 DIBAIKI: Padding diselaraskan luas sedikit
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE54A4A),
                                      borderRadius: BorderRadius.circular(24), // 🟢 DIBAIKI: Mengikut lengkungan elemen utama yang baru
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Remove",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15.5), // 🟢 DIBAIKI: Teks slaid buang dibesarkan daripada 14 ke 15.5
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24), // 🟢 DIBAIKI: Saiz ikon dibesarkan daripada 22 ke 24
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(18), // 🟢 DIBAIKI: Padding dalaman kad dibesarkan daripada 14 ke 18 untuk memberi nafas
                                    decoration: BoxDecoration(
                                      color: cardDark,
                                      borderRadius: BorderRadius.circular(24), // 🟢 DIBAIKI: Lengkungan kad utama dibesarkan daripada 20 ke 24 supaya kelihatan lebih premium
                                      border: Border.all(color: Colors.white10, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 58, // 🟢 DIBAIKI: Saiz pembungkus ikon muzik dibesarkan daripada 52 ke 58
                                          width: 58,  // 🟢 DIBAIKI: Saiz pembungkus ikon muzik dibesarkan daripada 52 ke 58
                                          decoration: BoxDecoration(
                                            color: emoColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(18), // 🟢 DIBAIKI: Lengkungan kotak ikon dibesarkan sedikit
                                            border: Border.all(color: emoColor.withOpacity(0.2), width: 1.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(Icons.music_note_rounded, color: emoColor, size: 28), // 🟢 DIBAIKI: Ikon nota dibesarkan daripada 26 ke 28
                                        ),
                                        const SizedBox(width: 16), // 🟢 DIBAIKI: Jarak horizontal dibesarkan daripada 14 ke 16
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                song["title"] ?? "Unknown Track",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800), // 🟢 DIBAIKI: Saiz tajuk lagu dibesarkan daripada 14 ke 15 dengan tulisan tebal
                                              ),
                                              const SizedBox(height: 4), // 🟢 DIBAIKI: Jarak menegak dinaikkan daripada 3 ke 4
                                              Text(
                                                song["channel_name"] ?? "Unknown Artist",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600), // 🟢 DIBAIKI: Saiz nama artis dibesarkan daripada 12 ke 13
                                              ),
                                              const SizedBox(height: 10), // 🟢 DIBAIKI: Jarak menegak dinaikkan daripada 8 ke 10
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), // 🟢 DIBAIKI: Padding label emosi dibesarkan
                                                decoration: BoxDecoration(
                                                  color: emoColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  emotionStr.toUpperCase(),
                                                  style: TextStyle(color: emoColor, fontSize: 11, fontWeight: FontWeight.w900), // 🟢 DIBAIKI: Teks tag emosi dibesarkan daripada 10 ke 11
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.play_arrow_rounded, color: textMuted, size: 22), // 🟢 DIBAIKI: Saiz butang mainan dibesarkan daripada 20 ke 22
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
                _buildFixedTopAppBar(context),
              ],
            ),
    );
  }

  Widget _buildFixedTopAppBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: bgCanvas.withOpacity(0.4),
            padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 20, 22, 20), // 🟢 DIBAIKI: Padding atas dan bawah AppBar ditinggikan sedikit untuk elemen yang lebih besar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Saved Music",
                  style: TextStyle(color: textDark, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5), // 🟢 DIBAIKI: Saiz tajuk utama halaman dibesarkan daripada 26 ke 28
                ),
                Container(
                  padding: const EdgeInsets.all(10), // 🟢 DIBAIKI: Padding bekas ikon bulatan dibesarkan daripada 8 ke 10
                  decoration: BoxDecoration(color: cardDark.withOpacity(0.6), shape: BoxShape.circle),
                  child: const Icon(Icons.library_music_outlined, color: brandYellow, size: 22), // 🟢 DIBAIKI: Saiz ikon teras dilaraskan daripada 20 ke 22
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24), // 🟢 DIBAIKI: Padding paparan kosong dibesarkan
      decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(28)), // 🟢 DIBAIKI: Lengkungan kotak dibesarkan daripada 24 ke 28
      child: Column(
        children: const [
          Text("🎵", style: TextStyle(fontSize: 50)), // 🟢 DIBAIKI: Saiz emoji dibesarkan daripada 44 ke 50
          SizedBox(height: 18),
          Text("No saved music yet", style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w900)), // 🟢 DIBAIKI: Teks amaran dibesarkan daripada 15 ke 17
          SizedBox(height: 6),
          Text("Tracks you save from your mood scans will appear here.", style: TextStyle(color: textMuted, fontSize: 14, height: 1.4), textAlign: TextAlign.center), // 🟢 DIBAIKI: Keterangan kosong dibesarkan daripada 12 ke 14
        ],
      ),
    );
  }
} 