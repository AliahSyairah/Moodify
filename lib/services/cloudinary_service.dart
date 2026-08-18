import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {

  static const cloudName = "dtqur8vox";
  static const uploadPreset = "moodify_profile";

  static Future<String?> uploadImage(File file) async {
  try {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/dtqur8vox/image/upload",
    );

    final request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final response = await request.send();
    final res = await response.stream.bytesToString();

    print("STATUS CODE: ${response.statusCode}");
    print("RAW RESPONSE: $res");

    // 🔥 ADD THIS CHECK
    if (response.statusCode != 200) {
  print("❌ CLOUDINARY FAILED");
  print("STATUS: ${response.statusCode}");
  print("RESPONSE: $res");
  return null;
}

    final data = jsonDecode(res);

    return data['secure_url'];
  } catch (e) {
    print("UPLOAD ERROR: $e");
    return null;
  }
}
}