import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../services/cloudinary_service.dart';

class ApiService {

  // =====================================================
  // FLASK API
  // =====================================================
  static String baseUrl = "https://syaispace-moodify.hf.space";

  // =====================================================
  // PHP API
  // =====================================================
  static String phpBaseUrl =
      "https://jeanie-uncensorable-nonconsolingly.ngrok-free.dev/moodify_api";

  // =====================================================
  // DETECT EMOTION
  // =====================================================
  static Future<Map<String, dynamic>> detectEmotion(File imageFile) async {
    try {
      print("START DETECTION");
      final start = DateTime.now();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/predict-emotion"),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      print("IMAGE ADDED");

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      print("STREAM RESPONSE RECEIVED");

      var response = await http.Response.fromStream(streamedResponse);
      final end = DateTime.now();

      print("ANALYZE TIME: ${end.difference(start).inMilliseconds} ms");
      print("STATUS CODE: ${response.statusCode}");
      print("RAW RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("SERVER ERROR ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      print("DECODED DATA: $data");

      return {
        "emotion": data["emotion"] ?? "neutral", // Ditukar default kepada neutral jika unknown
        "confidence": (data["confidence"] ?? 0).toDouble(),
      };

    } catch (e) {
      print("❌ DETECT ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // LOGIN (PHP)
  // =====================================================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$phpBaseUrl/login.php"),
        body: {"email": email, "password": password},
      );
      print("LOGIN RESPONSE: ${response.body}");
      return jsonDecode(response.body);
    } catch (e) {
      print("LOGIN ERROR: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // =====================================================
  // SIGNUP (PHP)
  // =====================================================
  static Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$phpBaseUrl/signup.php"),
        body: {"username": username, "email": email, "password": password},
      );
      print("SIGNUP RESPONSE: ${response.body}");
      return jsonDecode(response.body);
    } catch (e) {
      print("SIGNUP ERROR: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // =====================================================
  // SAVE MUSIC (FIRESTORE SUB-COLLECTION)
  // =====================================================
  static Future<bool> saveMusic({
    required String userId,
    required String videoId,
    required String title,
    required String channelName,
    required String emotion,
  }) async {
    try {
      if (userId.isEmpty || userId == "null") return false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_music')
          .add({
        'video_id': videoId,
        'title': title,
        'channel_name': channelName,
        'emotion': emotion,
        'created_at': FieldValue.serverTimestamp(),
      });

      print("✅ SUCCESS: Saved music added under user's sub-collection.");
      return true;
    } catch (e) {
      print("SAVE MUSIC ERROR: $e");
      return false;
    }
  }
  

  // =====================================================
  // GET SAVED MUSIC (FIRESTORE)
  // =====================================================
  static Future<List<dynamic>> getSavedMusic(String userId) async {
    try {
      if (userId.isEmpty || userId == "null") return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_music')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "video_id": data["video_id"] ?? "",
          "videoId": data["video_id"] ?? "", // Menyokong format video_player_screen
          "title": data["title"] ?? "",
          "channel_name": data["channel_name"] ?? "",
          "channel": data["channel_name"] ?? "", // Menyokong format video_player_screen
          "emotion": data["emotion"] ?? "",
        };
      }).toList();
    } catch (e) {
      print("GET SAVED MUSIC ERROR: $e");
      return [];
    }
  }
// =====================================================
  // CHECK IF SONG IS ALREADY SAVED (FIRESTORE) - TAMBAH INI
  // =====================================================
  static Future<bool> isSongSaved({
    required String userId,
    required String videoId,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_music')
          .where('video_id', isEqualTo: videoId)
          .get();

      return snapshot.docs.isNotEmpty; // Pulangkan true jika lagu sudah ada dalam DB
    } catch (e) {
      print("❌ Error checking saved song: $e");
      return false;
    }
  }
  // =====================================================
  // DELETE SAVED MUSIC (DIBAIKI: SEKARANG MEMADAM DARI FIRESTORE)
  // =====================================================
  static Future<bool> deleteSavedMusic(String userId, String musicId) async {
    try {
      if (userId.isEmpty || musicId.isEmpty) return false;

      // Memadam terus dari sub-collection Firestore berdasarkan ID dokumen
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_music')
          .doc(musicId)
          .delete();

      print("🗑️ SUCCESS: Saved music deleted from Firestore.");
      return true;
    } catch (e) {
      print("DELETE MUSIC FIREBASE ERROR: $e");
      return false;
    }
  }

  // =====================================================
  // SAVE EMOTION HISTORY (FIRESTORE)
  // =====================================================
  static Future<bool> saveEmotionHistory({
    required String userId,
    required String emotion,
    required String musicTitle,
  }) async {
    try {
      if (userId.isEmpty || userId == "null") return false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotion_history')
          .add({
        'emotion': emotion,
        'musicTitle': musicTitle,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print("SAVE HISTORY FIREBASE ERROR: $e");
      return false;
    }
  }

  // =====================================================
  // GET EMOTION HISTORY (FIRESTORE)
  // =====================================================
  static Future<List<Map<String, dynamic>>> getEmotionHistory(String userId) async {
    try {
      if (userId.isEmpty || userId == "null") return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotion_history')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        String dateStr = "Recent";
        if (data["created_at"] != null) {
          try {
            int dynamicTime = int.parse(data["created_at"].toString());
            DateTime dt = DateTime.fromMillisecondsSinceEpoch(dynamicTime);
            dateStr = "${dt.day}/${dt.month}/${dt.year}";
          } catch (_) {}
        }

        return {
          "id": doc.id,
          "emotion": data["emotion"] ?? "neutral",
          "music_title": data["musicTitle"] ?? data["music_title"] ?? "Unknown Track",
          "date": dateStr,
          "created_at": data["created_at"] ?? 0,
        };
      }).toList();
    } catch (e) {
      print("❌ GET EMOTION HISTORY ERROR: $e");
      return [];
    }
  }

  // =====================================================
  // GET RECENT ACTIVITIES (FIRESTORE)
  // =====================================================
  static Future<List<Map<String, dynamic>>> getRecentActivities(String userId) async {
    try {
      if (userId.isEmpty || userId == "null") return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotion_history')
          .orderBy('created_at', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "emotion": data["emotion"] ?? "",
          "created_at": data["created_at"] ?? 0,
        };
      }).toList();
    } catch (e) {
      print("RECENT ACTIVITY ERROR: $e");
      return [];
    }
  }

  // =====================================================
  // DELETE EMOTION HISTORY (FIRESTORE)
  // =====================================================
  static Future<bool> deleteEmotionHistory(String userId, String historyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotion_history')
          .doc(historyId)
          .delete();
      return true;
    } catch (e) {
      print("DELETE HISTORY FIREBASE ERROR: $e");
      return false;
    }
  }

  // =====================================================
  // GET DASHBOARD (FIRESTORE)
  // =====================================================
  static Future<Map<String, dynamic>> getDashboard(String userId) async {
    try {
      if (userId.isEmpty || userId == "null") return _emptyDashboard();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotion_history')
          .get();

      final docs = snapshot.docs;
      final now = DateTime.now();

      int currentWeekPositive = 0;
      int previousWeekPositive = 0;

      print("DASHBOARD DOCS: ${docs.length}");

      if (docs.isEmpty) return _emptyDashboard();

      int positive = 0;
      int neutral = 0;
      int negative = 0;

      Map<String, int> emotionCount = {};

      for (var doc in docs) {
        final emotion = (doc.data()['emotion'] ?? "").toString().toLowerCase().trim();
        final createdAt = doc.data()['created_at'] ?? 0;

        final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
        final daysAgo = now.difference(date).inDays;

        final isPositive = emotion == "happy" || emotion == "relaxed" || emotion == "surprise";

        if (isPositive) {
          if (daysAgo <= 7) {
            currentWeekPositive++;
          } else if (daysAgo > 7 && daysAgo <= 14) {
            previousWeekPositive++;
          }
        }

        emotionCount[emotion] = (emotionCount[emotion] ?? 0) + 1;

        if (emotion == "happy" || emotion == "relaxed" || emotion == "surprise") {
          positive++;
        } else if (emotion == "sad" || emotion == "angry" || emotion == "fear" || emotion == "disgust") {
          negative++;
        } else {
          neutral++;
        }
      }

      final totalScans = docs.length;
      double trend = 0;

      if (previousWeekPositive > 0) {
        trend = ((currentWeekPositive - previousWeekPositive) / previousWeekPositive) * 100;
      } else if (currentWeekPositive > 0) {
        trend = 100;
      }

      String topEmotion = "No Data";
      int highestCount = 0;

      emotionCount.forEach((emotion, count) {
        if (count > highestCount) {
          highestCount = count;
          topEmotion = emotion;
        }
      });

      return {
        "success": true,
        "trend": trend.round(),
        "overall": {
          "positive": ((positive / totalScans) * 100).round(),
          "neutral": ((neutral / totalScans) * 100).round(),
          "negative": ((negative / totalScans) * 100).round(),
        },
        "top_emotion": topEmotion,
        "total_scans": totalScans,
      };

    } catch (e) {
      print("DASHBOARD FIREBASE ERROR: $e");
      return _emptyDashboard();
    }
  }

  static Map<String, dynamic> _emptyDashboard() {
    return {
      "success": false,
      "overall": {"positive": 0, "neutral": 0, "negative": 0},
      "top_emotion": "No Data",
      "total_scans": 0,
    };
  }

  // =====================================================
  // UPDATE PROFILE (FIRESTORE)
  // =====================================================
  static Future<bool> updateProfile({
    required String userId,
    required String username,
    required String profileImage,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'username': username,
        'profile_image': profileImage,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print("UPDATE PROFILE FIREBASE ERROR: $e");
      return false;
    }
  }

  // =====================================================
  // UPLOAD PROFILE IMAGE (CLOUDINARY + PHP)
  // =====================================================
  static Future<String?> uploadProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    print("🔥 STEP 1: ENTER uploadProfileImage");
    try {
      print("🔥 STEP 2: imagePath = $imagePath");
      final file = File(imagePath);

      print("🔥 STEP 3: file exists = ${file.existsSync()}");
      print("🔥 STEP 4: BEFORE CLOUDINARY CALL");

      final url = await CloudinaryService.uploadImage(file);
      print("🔥 STEP 5: AFTER CLOUDINARY CALL: $url");

      if (url == null) {
        print("❌ CLOUDINARY RETURNED NULL");
        return null;
      }

      print("🔥 STEP 6: SENDING TO BACKEND");
      final response = await http.post(
        Uri.parse("$phpBaseUrl/upload_profile.php"),
        body: {
          "user_id": userId,
          "profile_image": url,
        },
      );

      print("🔥 STEP 7: BACKEND RESPONSE: ${response.body}");
      final data = jsonDecode(response.body);

      return data["success"] == true ? url : null;
    } catch (e) {
      print("❌ FULL ERROR: $e");
      return null;
    }
  }

  static String getImageUrl(String path) {
    if (path.startsWith("http")) return path;
    return "$phpBaseUrl/$path";
  }

  // =====================================================
  // GET MUSIC BY EMOTION (FIRESTORE)
  // =====================================================
  static Future<List<dynamic>> getMusicByEmotion(String emotion) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .where('emotion', isEqualTo: emotion.toLowerCase().trim())
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "videoId": data["video_id"] ?? data["videoId"] ?? "",
          "video_id": data["video_id"] ?? data["videoId"] ?? "",
          "title": data["title"] ?? "",
          "channel": data["channel_name"] ?? data["channel"] ?? "",
          "channel_name": data["channel_name"] ?? data["channel"] ?? "",
          "emotion": data["emotion"] ?? "",
        };
      }).toList();
    } catch (e) {
      print("❌ GET MUSIC BY EMOTION FIREBASE ERROR: $e");
      return [];
    }
  }
}