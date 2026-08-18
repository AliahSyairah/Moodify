import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/mood_music_data.dart'; // Import untuk menarik data playlist mengikut mood baharu

class MoodVideoPlayerScreen extends StatefulWidget {
  final String playlistId;
  final String playlistTitle;
  final String emotion; // Tambah parameter ini untuk tahu mood permulaan

  const MoodVideoPlayerScreen({
    super.key,
    required this.playlistId,
    required this.playlistTitle,
    required this.emotion,
  });

  @override
  State<MoodVideoPlayerScreen> createState() => _MoodVideoPlayerScreenState();
}

class _MoodVideoPlayerScreenState extends State<MoodVideoPlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // Simpan state dinamik di sini supaya lagu & tema boleh diubah dari dalam skrin ini
  late String currentPlaylistId;
  late String currentPlaylistTitle;
  late String currentEmotion;

  @override
  void initState() {
    super.initState();
    
    // Inisialisasi state awal daripada parameter widget
    currentPlaylistId = widget.playlistId;
    currentPlaylistTitle = widget.playlistTitle;
    currentEmotion = widget.emotion;

    // Membina url YouTube embedded playlist player rasmi menggunakan state dinamik
    final String embedUrl = "https://www.youtube.com/embed/videoseries?list=$currentPlaylistId&autoplay=1&modestbranding=1&rel=0";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF151221))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }

  // FUNGSI UTAMA: Menukar lagu dalam WebView dan mengubah warna tema/emosi serta-merta
  void switchMood(String newEmotion) {
    String normalizedMood = newEmotion.toLowerCase().trim();
    if (normalizedMood == currentEmotion.toLowerCase().trim()) return;

    // 1. Ambil data playlist baharu daripada MoodMusicData berdasarkan mood yang dipilih
    final allPlaylists = MoodMusicData.getPlaylistsByMood();
    final playlists = allPlaylists[normalizedMood] ?? allPlaylists["neutral"]!;

    if (playlists.isNotEmpty) {
      // Kita ambil playlist pertama yang sepadan dengan mood tersebut
      final newPlaylist = playlists.first;

      setState(() {
        _isLoading = true; // Tunjukkan loading indicator semula semasa lagu bertukar
        currentEmotion = normalizedMood;
        currentPlaylistId = newPlaylist.playlistId;
        currentPlaylistTitle = newPlaylist.title;
      });

      // 2. Paksa WebView untuk muatkan (load) senarai playlist YouTube yang baharu
      final String newEmbedUrl = "https://www.youtube.com/embed/videoseries?list=$currentPlaylistId&autoplay=1&modestbranding=1&rel=0";
      _controller.loadRequest(Uri.parse(newEmbedUrl));

      // Tampilkan mesej pemberitahuan ringkas kepada user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vibe bertukar ke ${newEmotion.toUpperCase()}! 🎵"),
          duration: const Duration(milliseconds: 1000),
          backgroundColor: getBrightAccentColor(),
        ),
      );
    }
  }

  // Helper warna aksen butang/teks mengikut mood dinamik semasa
  Color getBrightAccentColor() {
    switch (currentEmotion.toLowerCase().trim()) {
      case "happy": return const Color(0xFFFFC000); 
      case "sad": return const Color(0xFF9B5DE5);   
      case "angry": return const Color(0xFFE54A4A); 
      case "neutral":
      default: return const Color(0xFFFFD43F);     
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color brightColor = getBrightAccentColor();

    return Scaffold(
      backgroundColor: const Color(0xFF151221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151221),
        elevation: 0,
        title: Text(
          currentPlaylistTitle, // Guna state dinamik, tajuk akan bertukar automatik
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Bahagian Pemain Video YouTube (Nisbah Aspek Skrin Lebar Muzik 16:9)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Container(
                        color: const Color(0xFF1E192E),
                        child: Center(
                          child: CircularProgressIndicator(color: brightColor),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Bahagian Info Tambahan Bawah Pemain
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E192E),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: brightColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "YouTube Live Playlist (${currentEmotion.toUpperCase()})",
                              style: TextStyle(color: brightColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.shuffle_rounded, color: Color(0xAABBB3D6), size: 20),
                          const SizedBox(width: 16),
                          const Icon(Icons.repeat_rounded, color: Color(0xAABBB3D6), size: 20),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentPlaylistTitle, // Guna state dinamik
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enjoy seamless background-ready track streaming. You can use YouTube's native player controls on the screen above to skip tracks or control volume levels.",
                        style: TextStyle(color: Color(0xAABBB3D6), fontSize: 13, height: 1.5),
                      ),
                      const Spacer(),
                      // Butang Tutup / Kembali yang kemas
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brightColor, // Warna butang ikut tema mood semasa
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Minimize Player",
                            style: TextStyle(color: Color(0xFF151221), fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // INTERACTIVE SIDEBAR MOOD PANEL (Butang Tepi Untuk Tukar Mood + Lagu Serta-merta)
          Positioned(
            right: 12,
            top: MediaQuery.of(context).size.height * 0.30, 
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSidebarMoodItem(emoji: "🥰", moodName: "happy"),
                  const SizedBox(height: 14),
                  _buildSidebarMoodItem(emoji: "😢", moodName: "sad"),
                  const SizedBox(height: 14),
                  _buildSidebarMoodItem(emoji: "😡", moodName: "angry"),
                  const SizedBox(height: 14),
                  _buildSidebarMoodItem(emoji: "😐", moodName: "neutral"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget butang emoji di bahagian tepi kanan skrin player
  Widget _buildSidebarMoodItem({required String emoji, required String moodName}) {
    bool isActive = currentEmotion.toLowerCase() == moodName.toLowerCase();
    Color activeColor = getBrightAccentColor();

    return GestureDetector(
      onTap: () => switchMood(moodName), 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? activeColor : Colors.white.withOpacity(0.08),
        ),
        child: AnimatedScale(
          scale: isActive ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}