import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<Map<String, dynamic>> kirimStrukKeAI(
      List<int> imageBytes, String fileName, int kebutuhanDinamis, String rincian, String tipePendapatan, int lamaWaktu) async {
    try {
      var uri = Uri.parse('$baseUrl/analisis-pendapatan/');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));
      request.fields['kebutuhan_dinamis'] = kebutuhanDinamis.toString();
      request.fields['rincian'] = rincian;
      request.fields['tipe_pendapatan'] = tipePendapatan; // Kirim tipe
      request.fields['lama_waktu'] = lamaWaktu.toString(); // Kirim lama waktu

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        return {"status": "gagal", "pesan": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": "gagal", "pesan": "Gagal terhubung ke backend: $e"};
    }
  }

  static Future<List<dynamic>> ambilRiwayat() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/riwayat/'));
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