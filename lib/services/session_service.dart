import 'package:shared_preferences/shared_preferences.dart';

class SessionService {

  // ================= SAVE USER =================
  static Future<void> saveUser(
    String id,
    String username,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("user_id", id);
    await prefs.setString("username", username);
    await prefs.setString("email", email);
  }

  // ================= GET USER =================
  static Future<Map<String, String?>> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "id": prefs.getString("user_id"),
      "username": prefs.getString("username"),
      "email": prefs.getString("email"),
      "profile_image": prefs.getString("profile_image"),
    };
  }

  // ================= SAVE PROFILE IMAGE =================
  static Future<void> saveProfileImage(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("profile_image", path);
}
  // ================= GET PROFILE IMAGE =================
  static Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("profile_image");
  }

  // ================= SAVE USERNAME =================
  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
  }

  // ================= CHECK LOGIN =================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_id") != null;
  }

  // ================= CLEAR SESSION =================
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  static String normalizeImage(String path) {
  if (path.isEmpty) return "";

  return path.startsWith("http")
      ? path
      : "http://10.223.102.154/moodify_api/${path.replaceFirst("/", "")}";
}
// ================= SAVE GUEST (TAMBAH INI DI PALING BAWAH CLASS) =================
  static Future<void> saveGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_id", "guest");
    await prefs.setString("username", "Guest User");
    await prefs.setString("email", "guest@moodify.com");
  }
}