import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // --- FUNGSI LOGIN & REGISTER ---
  static Future<Map<String, dynamic>> loginUser(String username, String password) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/login/'),
        body: {"username": username, "password": password},
      );
      return json.decode(response.body);
    } catch (e) {
      return {"status": "gagal", "pesan": "Gagal terhubung ke server."};
    }
  }

  static Future<Map<String, dynamic>> registerUser(String nama, String username, String email, String password) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/register/'),
        body: {"nama": nama, "username": username, "email": email, "password": password},
      );
      return json.decode(response.body);
    } catch (e) {
      return {"status": "gagal", "pesan": "Gagal terhubung ke server."};
    }
  }

  // --- FUNGSI ANALISIS & RIWAYAT ---
  static Future<Map<String, dynamic>> kirimStrukKeAI(
      int userId, List<int> imageBytes, String fileName, int kebutuhanDinamis, String rincian, String tipePendapatan, String lamaWaktu) async {
    try {
      var uri = Uri.parse('$baseUrl/analisis-pendapatan/');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));
      
      request.fields['user_id'] = userId.toString();
      request.fields['kebutuhan_dinamis'] = kebutuhanDinamis.toString();
      request.fields['rincian'] = rincian;
      request.fields['tipe_pendapatan'] = tipePendapatan; 
      request.fields['lama_waktu'] = lamaWaktu;
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) return json.decode(responseData);
      return {"status": "gagal", "pesan": "Server error: ${response.statusCode}"};
    } catch (e) {
      return {"status": "gagal", "pesan": "Gagal terhubung ke backend: $e"};
    }
  }

  static Future<List<dynamic>> ambilRiwayat(int userId) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/riwayat/?user_id=$userId'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'sukses') return data['data']; 
      }
      return []; 
    } catch (e) {
      return [];
    }
  }

  // --- FUNGSI IHSG REAL-TIME ---
  static Future<Map<String, dynamic>> fetchIHSG() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/ihsg/'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"status": "gagal", "pesan": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": "gagal", "pesan": "Gagal terhubung ke backend: $e"};
    }
  }

  // --- FUNGSI TARGET KEUANGAN ---
  static Future<Map<String, dynamic>> tambahTarget(int userId, String nama, int nominal, String deadline) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/target/tambah/'),
        body: {"user_id": userId.toString(), "nama": nama, "nominal": nominal.toString(), "deadline": deadline},
      );
      return json.decode(response.body);
    } catch (e) {
      return {"status": "gagal", "pesan": "Gagal terhubung ke server."};
    }
  }

  static Future<List<dynamic>> listTarget(int userId) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/target/list/?user_id=$userId'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'sukses') return data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> topUpTarget(int targetId, int nominal) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/target/topup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'target_id': targetId, 'nominal': nominal}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'gagal', 'pesan': 'Gagal terhubung ke server'};
    } catch (e) {
      return {'status': 'gagal', 'pesan': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> fetchTargetTerdekat(int userId) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/target/list/?user_id=$userId'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body)['data'] as List;
        if (data.isNotEmpty) {
          return data.first; 
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // FITUR BARU: Tarik Riwayat per Target
  static Future<List<dynamic>> riwayatTarget(int targetId) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/target/history/?target_id=$targetId'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'sukses') return data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}