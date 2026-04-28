import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/analisis_response.dart';
import '../services/api_service.dart';

class AnalisisViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AnalisisResponse? _hasilAnalisis;
  AnalisisResponse? get hasilAnalisis => _hasilAnalisis;

  XFile? _selectedImageFile;
  Uint8List? _webImageBytes;
  Uint8List? get webImageBytes => _webImageBytes;

  void setImage(XFile file, Uint8List bytes) {
    _selectedImageFile = file;
    _webImageBytes = bytes;
    _hasilAnalisis = null;
    notifyListeners();
  }

  Future<void> prosesAnalisis() async {
    // Jika salah satu kosong, jangan lanjut
    if (_selectedImageFile == null || _webImageBytes == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Gunakan tanda '!' untuk memberitahu Dart bahwa data ini PASTI ADA (tidak null)
      _hasilAnalisis = await _apiService.kirimGambar(
        _selectedImageFile!, 
        _webImageBytes!,
      );
    } catch (e) {
      _hasilAnalisis = AnalisisResponse(status: 'gagal', pesan: e.toString());
    }

    _isLoading = false;
    notifyListeners();
  }
}