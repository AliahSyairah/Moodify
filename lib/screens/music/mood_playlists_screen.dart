import '../../data/mood_music_data.dart';
import 'video_player_screen.dart';
import 'package:flutter/material.dart';

class MoodPlaylistsScreen extends StatelessWidget {
  final String emotion;

  const MoodPlaylistsScreen({super.key, required this.emotion});

  // Tetapan warna tema premium yang konsisten dengan HomeScreen anda
  static const Color bgCanvas = Color(0xFF151221);
  static const Color cardDark = Color(0xFF1E192E);
  static const Color textDark = Colors.white;
  static const Color textMuted = Color(0xAABBB3D6);

  @override
  Widget build(BuildContext context) {
    String normalizedMood = emotion.toLowerCase().trim();
    if (normalizedMood.isEmpty) normalizedMood = "neutral";

    // Ambil senarai playlist dari data mengikut mood semasa
    final allPlaylists = MoodMusicData.getPlaylistsByMood();
    final playlists = allPlaylists[normalizedMood] ?? allPlaylists["neutral"]!;

    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: bgCanvas,
        elevation: 0,
        title: Text(
          "${emotion.toUpperCase()} Playlists",
          style: const TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                // Navigasi ke VideoPlayerScreen sedia ada menggunakan struktur parameter asal anda
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      songs: [
                        {
                          "video_id": playlist.playlistId,
                          "title": playlist.title,
                          "thumbnail": playlist.coverUrl,
                        }
                      ],
                      currentIndex: 0,
                      emotion: normalizedMood,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        playlist.coverUrl,
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: playlist.themeColor, width: 85, height: 85),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.title,
                            style: const TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            playlist.description,
                            style: const TextStyle(color: textMuted, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.library_music_outlined, size: 14, color: playlist.themeColor),
                              const SizedBox(width: 4),
                              Text(
                                playlist.trackCount,
                                style: TextStyle(color: playlist.themeColor, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.play_circle_fill_rounded, size: 36, color: playlist.themeColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}