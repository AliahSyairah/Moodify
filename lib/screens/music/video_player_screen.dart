import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:math' as math;

import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../data/mood_music_data.dart'; 

class VideoPlayerScreen extends StatefulWidget {
  final List songs;
  final int currentIndex;
  final String emotion;

  const VideoPlayerScreen({
    super.key,
    required this.songs,
    required this.currentIndex,
    required this.emotion,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  
  late AnimationController _beatController;
  late int currentIndex;
  late String currentEmotion;
  late List currentSongsList;

  Duration position = Duration.zero;
  Duration duration = const Duration(seconds: 1);
  bool isSaved = false;
  bool isSearching = false; 

  int loopMode = 0; 
  bool isShuffleOn = false;
  List<int> shuffledIndices = [];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
    currentEmotion = widget.emotion;
    
    // Pastikan data dimuatkan dalam format Map yang betul dari MoodMusicData
    final Map<String, List<MoodPlaylistModel>> allData = MoodMusicData.getPlaylistsByMood();
    final List<MoodPlaylistModel> rawVideos = allData[currentEmotion.toLowerCase().trim()] ?? [];
    if (rawVideos.isNotEmpty) {
      currentSongsList = rawVideos.map((song) => song.toMap()).toList();
    } else {
      currentSongsList = widget.songs;
    }

    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    loadVideo();
  }

  void loadVideo() {
    if (currentSongsList.isEmpty || currentIndex >= currentSongsList.length) return;

    final videoId = currentSongsList[currentIndex]['video_id'] ?? currentSongsList[currentIndex]['videoId'];

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "0tN6_1dJveM",
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
      ),
    );

    _setupControllerListener();
  }

  void _setupControllerListener() {
    _controller.addListener(() {
      if (!mounted) return;
      position = _controller.value.position;
      duration = _controller.metadata.duration;

      if (_controller.value.isPlaying) {
        if (!_beatController.isAnimating) _beatController.repeat();
      } else {
        if (_beatController.isAnimating) _beatController.stop();
      }

      if (_controller.value.playerState == PlayerState.ended) {
        handleSongEnded();
      }
      setState(() {});
    });
  }

  void handleSongEnded() {
    if (loopMode == 2) {
      _playCurrentIndex();
    } else {
      if (currentIndex >= currentSongsList.length - 1 && loopMode == 1) {
        currentIndex = 0;
        isSaved = false;
        _playCurrentIndex();
      } else {
        nextSong();
      }
    }
  }

  void nextSong() {
    if (isShuffleOn && shuffledIndices.isNotEmpty) {
      int currentShufflePos = shuffledIndices.indexOf(currentIndex);
      if (currentShufflePos < shuffledIndices.length - 1) {
        currentIndex = shuffledIndices[currentShufflePos + 1];
      } else if (loopMode == 1) {
        currentIndex = shuffledIndices[0]; 
      } else {
        return; 
      }
      isSaved = false;
      _playCurrentIndex();
    } else {
      if (currentIndex < currentSongsList.length - 1) {
        currentIndex++;
        isSaved = false;
        _playCurrentIndex();
      } else if (loopMode == 1) {
        currentIndex = 0; 
        isSaved = false;
        _playCurrentIndex();
      }
    }
  }

  void previousSong() {
    if (isShuffleOn && shuffledIndices.isNotEmpty) {
      int currentShufflePos = shuffledIndices.indexOf(currentIndex);
      if (currentShufflePos > 0) {
        currentIndex = shuffledIndices[currentShufflePos - 1];
        isSaved = false;
        _playCurrentIndex();
      }
    } else {
      if (currentIndex > 0) {
        currentIndex--;
        isSaved = false;
        _playCurrentIndex();
      }
    }
  }

  void _playCurrentIndex() {
    if (currentSongsList.isEmpty || currentIndex >= currentSongsList.length) return;
    
    final videoId = currentSongsList[currentIndex]['video_id'] ?? currentSongsList[currentIndex]['videoId'];
    if (videoId != null && videoId.toString().trim().isNotEmpty) {
      final cleanId = videoId.toString().trim();
      _controller.cue(cleanId);
      
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _controller.load(cleanId);
          _controller.play(); 
          _beatController.repeat();
          setState(() {});
        }
      });
    }
    setState(() {});
  }

  void playPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _beatController.stop();
    } else {
      _controller.play();
      _beatController.repeat();
    }
    setState(() {});
  }

  void toggleRepeatMode() {
    setState(() {
      loopMode = (loopMode + 1) % 3; 
      if (loopMode > 0) {
        isShuffleOn = false;
        shuffledIndices.clear();
      }
    });
  }

  void toggleShuffle() {
    setState(() {
      isShuffleOn = !isShuffleOn;
      if (isShuffleOn) {
        loopMode = 0;
        shuffledIndices = List.generate(currentSongsList.length, (index) => index);
        shuffledIndices.shuffle();
      } else {
        shuffledIndices.clear();
      }
    });
  }

  void switchMood(String newEmotion) async {
    String normalizedMood = newEmotion.toLowerCase().trim();
    if (normalizedMood == currentEmotion.toLowerCase().trim() || isSearching) return;

    setState(() {
      currentEmotion = normalizedMood; 
      isSearching = true;
    });

    try {
      final Map<String, List<MoodPlaylistModel>> allData = MoodMusicData.getPlaylistsByMood();
      final List<MoodPlaylistModel> rawVideos = allData[normalizedMood] ?? [];

      if (rawVideos.isNotEmpty) {
        setState(() {
          currentSongsList = rawVideos.map((song) => song.toMap()).toList();
          currentIndex = 0; 
          isSaved = false;
          if (isShuffleOn) {
            shuffledIndices = List.generate(currentSongsList.length, (index) => index);
            shuffledIndices.shuffle();
          }
        });

        final nextVideoId = currentSongsList[currentIndex]['video_id'] ?? currentSongsList[currentIndex]['videoId'];
        if (nextVideoId != null && nextVideoId.toString().trim().isNotEmpty) {
          final cleanId = nextVideoId.toString().trim();
          
          // 🌟 PERBAIKAN: Terus panggil .load() tanpa .cue() & tanpa delay supaya tiada isu "race-condition" atau lag
          if (mounted) {
            _controller.load(cleanId);
            _controller.play();
            _beatController.repeat();
            setState(() {});
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal tukar mood lagu: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }
 
  Future<void> saveMusic() async {
    // 🛑 1. AMBIL SESI USER & SEKAT GUEST
    final user = await SessionService.getUser();
    final String userId = user["id"]?.toString() ?? "";

    if (userId.isEmpty || userId.toLowerCase() == "guest") {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).clearSnackBars();
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final Color brightColor = getBrightAccentColor();
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Login Required", style: TextStyle(color: brightColor, fontWeight: FontWeight.w900)),
            content: const Text("Please login or create an account first to save your favorite tracks."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      return; 
    }

    // =================================================================
    // 🛑 2. UNTUK USER YANG LOGIN (SEMAK DUPLIKASI DATA)
    // =================================================================
    if (currentSongsList.isEmpty || currentIndex >= currentSongsList.length) return;

    final currentSong = currentSongsList[currentIndex];
    final String title = currentSong['title']?.toString() ?? "Unknown Track";
    final String videoId = (currentSong['video_id'] ?? currentSong['videoId'] ?? "").toString();
    final String channelName = (currentSong['channel'] ?? currentSong['channelTitle'] ?? "Unknown Artist").toString();

    // 🌟 SEKATAN BARU: Jika status `isSaved` memang sudah `true` (iaitu lagu ini dipaparkan sebagai sudah disave)
    // Kita terus halang dan keluar SnackBar atau Alert Dialog amaran!
    if (isSaved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ℹ You have already saved '$title' to your favorites!"),
          backgroundColor: Colors.orange[800], // Warna oren sebagai amaran info
          duration: const Duration(seconds: 2),
        ),
      );
      return; // Berhenti di sini, kod di bawah tidak akan berjalan, database selamat!
    }

    // Simpan status asal untuk fallback jika API error
    final bool oldSavedStatus = isSaved;

    // Tukar warna ikon heart jadi merah secara instant di screen
    setState(() {
      isSaved = true; 
    });

    try {
      // Panggil API untuk save ke database Firestore/Backend
      await ApiService.saveMusic(
        userId: userId,
        videoId: videoId,
        title: title,
        channelName: channelName,
        emotion: currentEmotion,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✓ '$title' has been successfully saved! 🎉"),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Jika database error, patah balik warna ikon asal
      if (mounted) {
        setState(() {
          isSaved = oldSavedStatus; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✕ Failed to save music. Please try again."),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }
  
  List<Color> getStunningMoodGradients() {
    switch (currentEmotion.toLowerCase().trim()) {
      case "happy": return [const Color(0xFFFFF9E6), const Color(0xFFFFD966)]; 
      case "sad": return [const Color(0xFFE6F0FA), const Color(0xFF6BA4FF)]; 
      case "angry": return [const Color(0xFFFFE6E6), const Color(0xFFFF4D4D)]; 
      case "neutral":
      default: return [const Color(0xFFF8F9FA), const Color(0xFFBDC3C7)]; 
    }
  }

  Color getBrightAccentColor() {
    switch (currentEmotion.toLowerCase().trim()) {
      case "happy": return const Color(0xFFE69500); 
      case "sad": return const Color(0xFF0052CC);   
      case "angry": return const Color(0xFFCC0000); 
      case "neutral":
      default: return const Color(0xFF2C3E50);     
    }
  }

  String getExactMoodAssetImage() {
    switch (currentEmotion.toLowerCase().trim()) {
      case "happy": return "assets/images/happymoji.jpg";
      case "sad": return "assets/images/sadmoji.jpg";
      case "angry": return "assets/images/angrymoji.jpg";
      case "neutral":
      default: return "assets/images/neutralmoji.jpg";
    }
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _beatController.dispose();

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> bgGradients = getStunningMoodGradients();
    final Color brightColor = getBrightAccentColor();

    double progressPercent = 0.0;
    if (duration.inSeconds > 0) {
      progressPercent = position.inSeconds.toDouble() / duration.inSeconds.toDouble();
      if (progressPercent > 1.0) progressPercent = 1.0;
    }

    final hasSongs = currentSongsList.isNotEmpty && currentIndex < currentSongsList.length;
    final currentSong = hasSongs ? currentSongsList[currentIndex] : null;

    // ====================================================================
    // POTONG DARI SINI (REPLACE KOD SCAFFOLD LAMA ANDA DENGAN BLOK INI)
    // ====================================================================
    return Scaffold(
      body: Stack(
        children: [
         // 1. Latar belakang kecerunan warna (Gradient) tablet anda - DIBAIKI UNTUK KELANCARAN GIF
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15), // 🟢 Sangat nipis & gelap, GIF latar belakang akan terus menyala terang tanpa kabur
            ),
          ),
          // 🌟 2. ANIMASI PARTIKEL YANG BERGERAK IKUT EMOSI (KOD BARU KITA SELIT DI SINI)
          EmotionAnimationBackground(
            emotion: currentEmotion, 
            baseColor: brightColor,   
          ),

          // 3. Hidden YouTube Player Engine
          SizedBox(
            width: 1, 
            height: 1, 
            child: YoutubePlayer(
              controller: _controller, 
              showVideoProgressIndicator: false
            )
          ),
    // ====================================================================
    // BERHENTI GANTI DI SINI. 
    // Sambungan di bawah adalah kod "// 🌟 3. ANTARAMUKA UTAMA PLAYER" yang kita dah besarkan sebelum ini.
    // ====================================================================

         // 🌟 3. ANTARAMUKA UTAMA PLAYER (DIBAIKI: Dioptimumkan saiz elemen untuk skrin Tablet)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0, // Memberi ruang kosong di bawah skrin untuk pengesan seretan jari
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0), // Lebarkan padding untuk tablet
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPremiumRoundButton(
                          icon: Icons.arrow_back_ios_new,
                          color: brightColor,
                          onTap: () {
                            _controller.pause();
                            Navigator.pop(context);
                          },
                        ),
                        Text(
                          "CURRENT TRACK",
                          style: TextStyle(color: brightColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3.0),
                        ),
                        AnimatedScale(
                          scale: isSaved ? 1.18 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: _buildPremiumRoundButton(
                            icon: isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.redAccent : brightColor,
                            onTap: saveMusic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHorizontalMoodItem(emoji: "😀", moodName: "happy"),
                          const SizedBox(width: 6),
                          _buildHorizontalMoodItem(emoji: "😭", moodName: "sad"),
                          const SizedBox(width: 6),
                          _buildHorizontalMoodItem(emoji: "😡", moodName: "angry"),
                          const SizedBox(width: 6),
                          _buildHorizontalMoodItem(emoji: "😐", moodName: "neutral"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: LinearProgressIndicator(backgroundColor: Colors.transparent),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatTime(position), style: TextStyle(color: brightColor, fontSize: 15, fontWeight: FontWeight.w800)),
                            Text("  /  ", style: TextStyle(color: brightColor.withOpacity(0.4), fontSize: 15)),
                            Text(formatTime(duration), style: TextStyle(color: brightColor.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                    const Spacer(),
                    
                    // 💿 BAHAGIAN BULATAN PLAYER & IMEJ (DIURUSKAN SEMULA UNTUK TABLET)
                    Center(
                      child: AnimatedBuilder(
                        animation: _beatController,
                        builder: (context, child) {
                          // Skala denyutan dikecilkan sikit impak dia sebab saiz dah besar (supaya tak pecah susun atur)
                          double wave1 = 1.0 + (_beatController.value * 0.15);
                          double wave2 = 1.0 + (_beatController.value * 0.08);
                          double opacity = 1.0 - _beatController.value;

                          bool isPlaying = _controller.value.isPlaying;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Gelombang Luar (Dibesarkan ke 380)
                              Transform.scale(
                                scale: isPlaying ? wave1 : 1.0,
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: brightColor.withOpacity(isPlaying ? opacity * 0.4 : 0.1), width: 4),
                                  ),
                                ),
                              ),
                              // Gelombang Dalam (Dibesarkan ke 380)
                              Transform.scale(
                                scale: isPlaying ? wave2 : 1.0,
                                child: Container(
                                  width: 260,
                                  height: 260,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: brightColor.withOpacity(isPlaying ? opacity * 0.7 : 0.2), width: 2),
                                  ),
                                ),
                              ),
                              // Garis Progress CustomPaint (Dibesarkan ke 405 supaya muat-muat luar bulatan)
                              CustomPaint(
                                size: const Size(260, 260),
                                painter: StrikingTimelineProgressPainter(progress: progressPercent, color: brightColor),
                              ),
                              // Bekas Imej Album Utama (Dibesarkan ke 350)
                              // Bekas Imej Album Utama (Dibesarkan ke 350)
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 6), // Garis putih tebal sikit untuk tablet
                                  boxShadow: [
                                    BoxShadow(color: brightColor.withOpacity(0.3), blurRadius: 35, spreadRadius: 6),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(110), // Had setengah daripada saiz 350
                                  
                                  // 🌟 REWRITE & GANTI DI SINI:
                                  child: Image.asset(
                                    currentEmotion.toLowerCase() == 'happy' 
                                        ? 'assets/images/happymoji.jpg'
                                        : currentEmotion.toLowerCase() == 'sad'
                                            ? 'assets/images/sadmoji.jpg'
                                            : currentEmotion.toLowerCase() == 'angry'
                                                ? 'assets/images/angrymoji.jpg'
                                                : 'assets/images/neutralmoji.jpg',
                                    key: ValueKey<String>(currentEmotion), 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.white, 
                                        child: Icon(Icons.music_note, color: brightColor, size: 70)
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const Spacer(),
                    
                    // 📝 FONT TAJUK & ARTIS (DIBESARKAN UNTUK SKRIN TABLET)
                    Text(
                      currentSong != null ? (currentSong['title'] ?? "Unknown Track") : "Loading Tracks...",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: brightColor,
                        fontSize: 20, // Dibesarkan dari 20
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [Shadow(color: Colors.white.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, 2))]
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentSong != null ? (currentSong['channel'] ?? currentSong['channelTitle'] ?? "Unknown Artist") : "Please wait",
                      style: TextStyle(color: brightColor.withOpacity(0.75), fontSize: 17, fontWeight: FontWeight.w700), // Dibesarkan dari 13
                    ),

                    const SizedBox(height: 12),
                    
                    // 🎛️ PANEL KAWALAN ALBUM
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            loopMode == 2 ? Icons.repeat_one : Icons.repeat, 
                            color: loopMode > 0 ? brightColor : brightColor.withOpacity(0.35), 
                            size: 24 // Dibesarkan sedikit
                          ),
                          onPressed: toggleRepeatMode,
                        ),
                        IconButton(icon: Icon(Icons.skip_previous_rounded, color: brightColor, size: 48), onPressed: previousSong), // Dibesarkan dari 36
                        GestureDetector(
                          onTap: playPause,
                          child: Container(
                            width: 64, // Dibesarkan dari 64
                            height: 64,
                            decoration: BoxDecoration(
                              color: brightColor,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: brightColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
                            ),
                            child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40), // Dibesarkan dari 34
                          ),
                        ),
                        IconButton(icon: Icon(Icons.skip_next_rounded, color: brightColor, size: 48), onPressed: nextSong), // Dibesarkan dari 36
                        IconButton(
                          icon: Icon(
                            Icons.shuffle, 
                            color: isShuffleOn ? brightColor : brightColor.withOpacity(0.35), 
                            size: 24 // Dibesarkan sedikit
                          ),
                          onPressed: toggleShuffle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 65),
                  ],
                ),
              ),
            ),
          ),

          // 🌟 4. DRAGGABLE PLAYLIST PANEL (DIBAIKI: Dioptimumkan saiz elemen untuk skrin Tablet)
          DraggableScrollableSheet(
            initialChildSize: 0.08, // Dinaikkan sikit daripada 0.10 supaya lebih fit pada tablet
            minChildSize: 0.08,     
            maxChildSize: 0.85,     
            snap: true,             
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.98),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32), // Bulatan bucu dibesarkan sikit
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brightColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 6,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView.builder(
                  controller: scrollController, 
                  padding: const EdgeInsets.only(bottom: 24), // Lebarkan padding bawah
                  itemCount: currentSongsList.length + 1,
                  itemBuilder: (context, index) {
                    // ==========================================
                    // BAHAGIAN HEADER (Index 0): Boleh ditarik!
                    // ==========================================
                    if (index == 0) {
                      return Container(
                        color: Colors.transparent, 
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle Bar kelabu (Dibesarkan sikit untuk tablet)
                            Container(
                              width: 60,
                              height: 6,
                              decoration: BoxDecoration(
                                color: brightColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "UP NEXT • ${currentEmotion.toUpperCase()} PLAYLIST",
                              style: TextStyle(
                                color: brightColor,
                                fontSize: 13, // Dibesarkan dari 11
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0, // Jarakkan sikit
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, thickness: 0.6),
                          ],
                        ),
                      );
                    }
                    // ==========================================
                    // BAHAGIAN SENARAI LAGU (Index > 0)
                    // ==========================================
                    final songIndex = index - 1;
                    final song = currentSongsList[songIndex];
                    final bool isCurrent = songIndex == currentIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0), // Lebarkan padding senarai
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bucu tile lebih bulat
                        tileColor: isCurrent ? brightColor.withOpacity(0.08) : Colors.transparent,
                        leading: Container(
                          width: 52, // Dibesarkan dari 44
                          height: 52,
                          decoration: BoxDecoration(
                            color: isCurrent ? brightColor.withOpacity(0.15) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isCurrent ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                            color: isCurrent ? brightColor : Colors.grey[400],
                            size: 26, // Dibesarkan dari 20
                          ),
                        ),
                        title: Text(
                          song['title'] ?? 'Unknown Track',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18, // Dibesarkan dari 15
                            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          song['channel'] ?? song['channelTitle'] ?? 'Unknown Artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14, // Dibesarkan dari 12
                            fontWeight: FontWeight.w600,
                            color: isCurrent ? brightColor.withOpacity(0.8) : Colors.grey[500],
                          ),
                        ),
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: brightColor, borderRadius: BorderRadius.circular(10)),
                                child: const Text(
                                  "PLAYING",
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              )
                            : Icon(Icons.play_arrow_rounded, color: Colors.grey[400], size: 28),
                        onTap: () {
                          setState(() {
                            currentIndex = songIndex; 
                            isSaved = false;
                            _playCurrentIndex();
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔘 BUTANG BULAT ATAS (DIBESARKAN UNTUK TABLET)
  Widget _buildPremiumRoundButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54, // Dibesarkan dari 44
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: Colors.white.withOpacity(0.6),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
          ]
        ),
        child: Icon(icon, color: color, size: 24), // Dibesarkan dari 20
      ),
    );
  }

  // 🏷️ PILIHAN MOOD HORIZONTAL (DIBESARKAN UNTUK TABLET)
  Widget _buildHorizontalMoodItem({required String emoji, required String moodName}) {
    bool isActive = currentEmotion.toLowerCase() == moodName.toLowerCase();
    Color activeColor = getBrightAccentColor();

    return GestureDetector(
      onTap: () => switchMood(moodName), 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Lebarkan ruang dalaman button
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive ? activeColor : Colors.white.withOpacity(0.2),
          boxShadow: isActive ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)), // Dibesarkan dari 16
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                moodName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12, // Dibesarkan dari 10
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class StrikingTimelineProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  StrikingTimelineProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    final trackPaint = Paint()..color = color.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 3.0; // Tebalkan sikit
    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()..color = color..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 5.0; // Tebalkan sikit
    double startAngle = -math.pi / 2; 
    double sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, activePaint);

    final currentAngle = startAngle + sweepAngle;
    final knobOffset = Offset(center.dx + radius * math.cos(currentAngle), center.dy + radius * math.sin(currentAngle));
    canvas.drawCircle(knobOffset, 7.0, Paint()..color = Colors.white);
    canvas.drawCircle(knobOffset, 7.0, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant StrikingTimelineProgressPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}


class EmotionAnimationBackground extends StatefulWidget {
  final String emotion;
  final Color baseColor;

  const EmotionAnimationBackground({
    Key? key,
    required this.emotion,
    required this.baseColor,
  }) : super(key: key);

  @override
  State<EmotionAnimationBackground> createState() => _EmotionAnimationBackgroundState();
}

class _EmotionAnimationBackgroundState extends State<EmotionAnimationBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<_MoodParticle> particles = [];
  final math.Random random = math.Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initParticles());
  }

  @override
  void didUpdateWidget(covariant EmotionAnimationBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _initParticles(); // Reset partikel kalau emosi bertukar
    }
  }

  void _initParticles() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    particles = List.generate(40, (index) => _MoodParticle.generate(widget.emotion, size, random));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final String mood = widget.emotion.toLowerCase();

    return Stack(
      children: [
        // ==========================================
        // 1. LAPISAN GRADIENT LATAR BELAKANG (Sama macam design)
        // ==========================================
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getMoodGradients(mood),
            ),
          ),
        ),

       // ==========================================
        // 2. LAPISAN ANIMASI BERGERAK (IKUT EMOSI)
        // ==========================================
        if (mood == 'happy')
          Positioned.fill(
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/happy_confetti_texture.gif', 
                fit: BoxFit.cover,
              ),
            ),
          )
        else if (mood == 'sad')
          Positioned.fill(
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                'assets/images/sad_rain_texture.gif', 
                fit: BoxFit.cover,
                color: const Color.fromARGB(255, 132, 156, 213).withOpacity(0.9),
                colorBlendMode: BlendMode.screen, // 🌟 MAGIK: Buang background hitam fail GIF hujan
              ),
            ),
          )
        else if (mood == 'angry')
          Positioned.fill(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
               'assets/images/angry_fire_texture.gif', 
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.screen, // 🌟 MAGIK: Menyadikan percikan api dengan gradient merah
              ),
            ),
          )
        else
          // NEUTRAL
          Positioned.fill(
            child: Opacity(
              opacity:0.6,
              child: Image.asset(
                'assets/images/neutral_mist.gif', 
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.screen, // 🌟 MAGIK: Kabus putih menyatu dengan skrin kelabu
              ),
            ),
          ),
      ],
    );
  }

  // Fungsi untuk set warna background gradient tepat seperti imej design
  List<Color> _getMoodGradients(String mood) {
    switch (mood) {
      case 'happy':
        return [const Color(0xFFEEDAA2), const Color(0xFFB1E3D4)]; // Hijau-kuning pastel
      case 'sad':
        return [const Color(0xFF1E355E), const Color(0xFF3F3B6C)]; // Biru-ungu gelap suram
      case 'angry':
        return [const Color(0xFF2A0808), const Color(0xFF631212)]; // Merah-hitam kencang
      case 'neutral':
      default:
        return [const Color(0xFFE5E4E2), const Color(0xFFC0C0C0)]; // Kelabu premium tenang
    }
  }
}

// ============================================================================
// LOGIK FIZIK PERGERAKAN PARTIKEL (HAPPY & ANGRY)
// ============================================================================
class _MoodParticle {
  late double x, y, speed, size, opacity;

  _MoodParticle.generate(String emotion, Size sizeX, math.Random r) {
    x = r.nextDouble() * sizeX.width;
    y = r.nextDouble() * sizeX.height;
    opacity = r.nextDouble() * 0.4 + 0.1;
    this.size = emotion == 'happy' ? r.nextDouble() * 12 + 6 : r.nextDouble() * 20 + 8;
    speed = emotion == 'happy' ? r.nextDouble() * 1.5 + 0.5 : r.nextDouble() * 3 + 2;
  }

  void update(String emotion, Size sizeX) {
    if (emotion == 'happy') {
      // Happy: Terapung perlahan ke atas (Confetti/Music Note effect)
      y -= speed;
      if (y < -size) {
        y = sizeX.height + size;
        x = math.Random().nextDouble() * sizeX.width;
      }
    } else if (emotion == 'angry') {
      // Angry: Meletus naik ke atas dengan laju (Spark/Fire effect)
      y -= speed;
      x += (math.Random().nextDouble() - 0.5) * 2; // Ada getaran kiri kanan
      if (y < -size) {
        y = sizeX.height + size;
        x = math.Random().nextDouble() * sizeX.width;
      }
    }
  }
}

// ============================================================================
// PELUKIS BENTUK GEOMETRI (KOD UNTUK LUKIS BINTANG / API)
// ============================================================================
class _MoodPainter extends CustomPainter {
  final List<_MoodParticle> particles;
  final String emotion;
  final Color color;

  _MoodPainter({required this.particles, required this.emotion, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = emotion == 'angry' ? Colors.orangeAccent.withOpacity(p.opacity) : color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      if (emotion == 'happy') {
        // Lukis Bintang Kecil / Kelopak untuk Happy
        canvas.drawCircle(Offset(p.x, p.y), p.size / 2, paint);
      } else if (emotion == 'angry') {
        // Lukis Segi Tiga Tajam (Spark Api) untuk Angry
        final path = Path();
        path.moveTo(p.x, p.y - p.size / 2);
        path.lineTo(p.x + p.size / 3, p.y + p.size / 2);
        path.lineTo(p.x - p.size / 3, p.y + p.size / 2);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MoodPainter oldDelegate) => true;
}