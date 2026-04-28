import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/analisis_response.dart';

class ApiService {
  // Pakai localhost agar lebih bersahabat dengan Chrome
  static const String baseUrl = "http://localhost:8000";

  Future<AnalisisResponse> kirimGambar(XFile file, Uint8List bytes) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analisis'));
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes,
        filename: file.name,
        contentType: MediaType('image', 'jpeg'),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return AnalisisResponse.fromJson(json.decode(response.body));
      } else {
        return AnalisisResponse(status: 'gagal', pesan: 'Server Error: ${response.statusCode}');
      }
    } catch (e) {
      return AnalisisResponse(status: 'gagal', pesan: 'Koneksi Gagal: $e');
    }
  }
}