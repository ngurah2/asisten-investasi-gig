import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // --- FUNGSI LOGIN & REGISTER BARU (UPDATE FITUR C: USERNAME) ---
  static Future<Map<String, dynamic>> loginUser(String username, String password) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/login/'),
        // Menggunakan 'username' alih-alih 'email'
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
        // Menambahkan pengiriman data 'username' ke backend
        body: {"nama": nama, "username": username, "email": email, "password": password},
      );
      return json.decode(response.body);
    } catch (e) {
      return {"status": "gagal", "pesan": "Gagal terhubung ke server."};
    }
  }

  // --- FUNGSI ANALISIS & RIWAYAT (DIPERBARUI DENGAN USER ID) ---
  static Future<Map<String, dynamic>> kirimStrukKeAI(
      int userId, List<int> imageBytes, String fileName, int kebutuhanDinamis, String rincian, String tipePendapatan, String lamaWaktu) async {
    try {
      var uri = Uri.parse('$baseUrl/analisis-pendapatan/');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));
      
      // TAMBAHAN: Mengirim user_id
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
      // TAMBAHAN: Memanggil API dengan query user_id
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
}