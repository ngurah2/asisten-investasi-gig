import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Alamat server Python Anda (Karena Anda menjalankan Flutter di Chrome, pakai 127.0.0.1)
  static const String baseUrl = "http://127.0.0.1:8000";

  // Fungsi untuk mengirim gambar dan data kebutuhan ke Python
  static Future<Map<String, dynamic>> kirimStrukKeAI(
      List<int> imageBytes, String fileName, int kebutuhanDinamis) async {
    
    try {
      var uri = Uri.parse('$baseUrl/analisis-pendapatan/');
      var request = http.MultipartRequest('POST', uri);

      // 1. Memasukkan gambar ke dalam paket kiriman
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));

      // 2. Memasukkan data draf pengeluaran (kebutuhan) ke dalam paket
      request.fields['kebutuhan_dinamis'] = kebutuhanDinamis.toString();

      // 3. Kurir berangkat mengirim data!
      var response = await request.send();
      
      // 4. Kurir menerima balasan dari Python
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Jika sukses, ubah teks JSON dari Python menjadi format yang dimengerti Flutter
        return json.decode(responseData);
      } else {
        return {
          "status": "gagal", 
          "pesan": "Server menolak. Kode Error: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "status": "gagal", 
        "pesan": "Gagal terhubung ke server Python. Pastikan uvicorn menyala! Detail: $e"
      };
    }
  }
}