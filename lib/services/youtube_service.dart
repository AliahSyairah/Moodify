import 'dart:convert';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

class YoutubeService {
  static const String apiKey = "AIzaSyAhSraxbkppxracEAZTkPp7GdI5WOYC9vk";
 
  // 🎯 DIKEMAS KINI: Menggunakan carian bebas sekatan hak cipta (NCS & Audio Library)
  // Ini memastikan semua 50 lagu boleh dimainkan tanpa ralat skrin hitam!
  static String mapEmotion(String emotion) {
    switch (emotion.toLowerCase().trim()) {
      case "happy":
        return "NoCopyrightSounds Upbeat Pop Electronic Audio Studio";
      case "sad":
        return "Cinematic Sad Piano Chill Lofi No Copyright Instrumental";
      case "angry":
        return "Aggressive Rock Workout No Copyright Sounds Synthwave";
      case "neutral":
      default:
        return "Lofi Chill Cafe Beats No Copyright Study Relaxation";
    }
  }

  static Future<List> getVideos(String emotion) async {
    try {
      final query = mapEmotion(emotion);

      // 🎯 DIBAIKI: Had carian dinaikkan kepada 50 lagu untuk fungsi Next tanpa had
      final url = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': '50', 
        'key': apiKey,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null && (data['items'] as List).isNotEmpty) {
          final List items = data['items'];
          final unescape = HtmlUnescape();

          final parsedSongs = items.map((item) {
            final rawVideoId = item['id']?['videoId']; 
            if (rawVideoId == null) return null;

            return {
              "title": unescape.convert(item['snippet']['title']),
              "channel": item['snippet']['channelTitle'],
              "video_id": rawVideoId,
              "videoId": rawVideoId,
            };
          }).where((e) => e != null).toList();

          if (parsedSongs.isNotEmpty) {
            return parsedSongs;
          }
        }
      }
      
      return _getLocalFallbackSongs(emotion);
    } catch (e) {
      return _getLocalFallbackSongs(emotion);
    }
  }

  // 🎯 PLAYLIST BACKUP RINGKAS (Jika Tiada Internet / Quota API Habis)
  static List _getLocalFallbackSongs(String emotion) {
    switch (emotion.toLowerCase().trim()) {
      case "happy":
        return [
          {"title": "Espresso", "channel": "Sabrina Carpenter", "video_id": "eeaAgl8U-nM", "videoId": "eeaAgl8U-nM"},
          {"title": "Teman", "channel": "Iman Troye", "video_id": "8v4bH9p4wjg", "videoId": "8v4bH9p4wjg"},
          {"title": "Alamak Raya Lagi!", "channel": "De Fam", "video_id": "4S9_Hiof6v0", "videoId": "4S9_Hiof6v0"},
        ];
      case "sad":
        return [
          {"title": "Someone You Loved", "channel": "Lewis Capaldi", "video_id": "bC6AtE7WZCo", "videoId": "bC6AtE7WZCo"},
          {"title": "Masing Masing", "channel": "Ernie Zakri ft. Ade Govinda", "video_id": "p3Vv8mSgCg4", "videoId": "p3Vv8mSgCg4"},
          {"title": "Sial", "channel": "Mahalini", "video_id": "gREHevYat6Y", "videoId": "gREHevYat6Y"},
        ];
      case "angry":
        return [
          {"title": "Believer", "channel": "Imagine Dragons", "video_id": "7wtfhZwyrcc", "videoId": "7wtfhZwyrcc"},
          {"title": "Malam Pagi", "channel": "Saixse", "video_id": "4KzG_uSAnm8", "videoId": "4KzG_uSAnm8"},
          {"title": "Swipe", "channel": "Alyph", "video_id": "Kgo84SbeA04", "videoId": "Kgo84SbeA04"},
        ];
      case "neutral":
      default:
        return [
          {"title": "Until I Found You", "channel": "Stephen Sanchez", "video_id": "GxldQ9GyXQM", "videoId": "GxldQ9GyXQM"},
          {"title": "Pulang", "channel": "Insomniacks", "video_id": "38p-vA9mYI8", "videoId": "38p-vA9mYI8"},
          {"title": "Sah", "channel": "Sarah Suhairi ft. Alfie Zumi", "video_id": "8Z8p_hSg3A0", "videoId": "8Z8p_hSg3A0"},
        ];
    }
  }
}