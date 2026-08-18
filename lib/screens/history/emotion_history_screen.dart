import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Diperlukan untuk ImageFilter (Glassmorphism)

import '../../services/session_service.dart';

class EmotionHistoryScreen extends StatefulWidget {
  final bool isEmbedded; 
  const EmotionHistoryScreen({super.key, this.isEmbedded = false});

  @override
  State<EmotionHistoryScreen> createState() => _EmotionHistoryScreenState();
}

class _EmotionHistoryScreenState extends State<EmotionHistoryScreen> {
  List<Map<String, dynamic>> history = []; 
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
    loadHistory();
  }

  // 1. MEMBACA DATA: Diubah suai untuk membaca int64 epoch millisecond & 'musicTitle'
  Future<void> loadHistory() async {
    try {
      final user = await SessionService.getUser();
      final String userId = (user["id"] ?? user["uid"] ?? "").toString().trim();

      if (userId.isEmpty || userId == "null") {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotion_history');

      // Mengambil dan menyusun mengikut susunan masa terkini
      final snapshot = await ref.orderBy('created_at', descending: true).get();
      List<Map<String, dynamic>> temp = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data();
        String emotion = data["emotion"] ?? "neutral";
        
        // DIBAIKI: Menggunakan 'musicTitle' tepat mengikut rekod di Firebase anda
        String music = data["musicTitle"] ?? data["music_title"] ?? "Unknown Track";
        String dateStr = "Unknown Date";

        // DIBAIKI: Membaca format timestamp berasaskan integer millisecond epoch
        if (data["created_at"] != null) {
          try {
            int dynamicTime = int.parse(data["created_at"].toString());
            DateTime dt = DateTime.fromMillisecondsSinceEpoch(dynamicTime);
            dateStr = "${dt.day}/${dt.month}/${dt.year}";
          } catch (e) {
            // Jika ada data lama dalam format Timestamp Firebase, ia tidak akan crash
            if (data["created_at"] is Timestamp) {
              DateTime dt = (data["created_at"] as Timestamp).toDate();
              dateStr = "${dt.day}/${dt.month}/${dt.year}";
            }
          }
        }

        temp.add({
          "id": doc.id, 
          "emotion": emotion,
          "music_title": music,
          "date": dateStr,
        });
      }

      setState(() {
        history = temp;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ LOAD HISTORY ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case "happy": return "😊";
      case "sad": return "😢";
      case "angry": return "😡";
      case "neutral": return "😐";
      default: return "🎵";
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
                // 🌟 REPAIR UTAMA: Semak status kosong di luar ListView induk
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
                                "Your Journey",
                                style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.2), 
                              ),
                              Text(
                                "${history.length} records",
                                style: const TextStyle(color: textMuted, fontSize: 13.5, fontWeight: FontWeight.w700), 
                              )
                            ],
                          ),
                          const SizedBox(height: 18), 

                          // Petunjuk leret sentiasa selamat dipaparkan di sini
                          Container(
                            margin: const EdgeInsets.only(bottom: 20), 
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
                            decoration: BoxDecoration(
                              color: cardDark,
                              borderRadius: BorderRadius.circular(16), 
                              border: Border.all(color: brandYellow.withOpacity(0.15), width: 1),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.swap_horizontal_circle_outlined, color: brandYellow, size: 20), 
                                SizedBox(width: 12), 
                                Expanded(
                                  child: Text(
                                    "💡 Swipe LEFT on any card to remove it from history.",
                                    style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w700), 
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 🟢 LETAK SEMAKAN KOSONG DI SINI SECARA KHUSUS UNTUK SENARAI SAHAJA
history.isEmpty
    ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: _buildEmptyStateWidget(),
      )
    : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        itemBuilder: (context, index) {
          // ... (kekalkan kandungan itemBuilder / Dismissible sedia ada anda di sini) ...
        },
      ),

                          // Terus panggil builder tanpa semakan bersyarat bercabang di dalam children
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final item = history[index];
                              final String emotionStr = item["emotion"] ?? "neutral";
                              final String musicTitle = item["music_title"] ?? "Unknown Track";
                              final String dateStr = item["date"] ?? "Unknown Date";
                              final Color emoColor = getEmotionColor(emotionStr);

                              return Container(
                                key: ValueKey(item["id"]), // Menggunakan ValueKey untuk keselamatan state widget semasa padam
                                margin: const EdgeInsets.only(bottom: 15), 
                                child: Dismissible(
                                  key: Key(item["id"].toString()),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: cardDark,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(26), 
                                            side: const BorderSide(color: Colors.white10, width: 1), 
                                          ),
                                          title: const Text(
                                            "Remove History",
                                            style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w900), 
                                          ),
                                          content: Text(
                                            "Are you sure you want to delete this ${emotionStr.toUpperCase()} record from your history?",
                                            style: const TextStyle(color: textMuted, fontSize: 15, height: 1.4), 
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text("Cancel", style: TextStyle(color: textMuted, fontSize: 15, fontWeight: FontWeight.w700)), 
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFE54A4A),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text("Remove", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)), 
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    final removedItem = history[index];
                                    setState(() {
                                      history.removeAt(index);
                                    });

                                    try {
                                      final user = await SessionService.getUser();
                                      final String userId = (user["id"] ?? user["uid"] ?? "").toString().trim();

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId)
                                          .collection('emotion_history')
                                          .doc(removedItem["id"])
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
                                                Text("Record deleted successfully", style: TextStyle(fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint("❌ DELETE HISTORY FIREBASE ERROR: $e");
                                      if (mounted) {
                                        setState(() {
                                          history.insert(index, removedItem);
                                        });
                                      }
                                    }
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 26), 
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE54A4A),
                                      borderRadius: BorderRadius.circular(24), 
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Remove",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15.5), 
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24), 
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(18), 
                                    decoration: BoxDecoration(
                                      color: cardDark,
                                      borderRadius: BorderRadius.circular(24), 
                                      border: Border.all(color: Colors.white10, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 58, 
                                          width: 58,  
                                          decoration: BoxDecoration(
                                            color: emoColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(18), 
                                            border: Border.all(color: emoColor.withOpacity(0.2), width: 1.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(getEmotionEmoji(emotionStr), style: const TextStyle(fontSize: 28)), 
                                        ),
                                        const SizedBox(width: 16), 
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), 
                                                    decoration: BoxDecoration(
                                                      color: emoColor.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      emotionStr.toUpperCase(),
                                                      style: TextStyle(
                                                        color: emoColor,
                                                        fontSize: 11, 
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.6,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    dateStr,
                                                    style: const TextStyle(color: textMuted, fontSize: 12.5, fontWeight: FontWeight.w600), 
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10), 
                                              Row(
                                                children: [
                                                  const Icon(Icons.music_note_rounded, color: brandYellow, size: 16), 
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      musicTitle,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800), 
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                
                // Kekalkan AppBar komponen atas
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
                  "Emotion History",
                  style: TextStyle(color: textDark, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5), // 🟢 DIBAIKI: Saiz tajuk utama halaman dibesarkan daripada 26 ke 28
                ),
                Container(
                  padding: const EdgeInsets.all(10), // 🟢 DIBAIKI: Padding bekas ikon bulatan dibesarkan daripada 8 ke 10
                  decoration: BoxDecoration(color: cardDark.withOpacity(0.6), shape: BoxShape.circle),
                  child: const Icon(Icons.history_rounded, color: brandYellow, size: 22), // 🟢 DIBAIKI: Saiz ikon teras dilaraskan daripada 20 ke 22
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
          Text("📊", style: TextStyle(fontSize: 50)), // 🟢 DIBAIKI: Saiz emoji dibesarkan daripada 44 ke 50
          SizedBox(height: 18),
          Text("No scanned history yet", style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w900)), // 🟢 DIBAIKI: Teks amaran dibesarkan daripada 15 ke 17
          SizedBox(height: 6),
          Text("Your scanned emotions and journeys will show up here.", style: TextStyle(color: textMuted, fontSize: 13.5, height: 1.4), textAlign: TextAlign.center), // 🟢 DIBAIKI: Keterangan kosong dibesarkan daripada 12 ke 13.5
        ],
      ),
    );
  }
}