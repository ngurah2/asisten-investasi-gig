// lib/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:image_picker/image_picker.dart';
import '../view_models/analisis_view_model.dart';
import 'widgets/result_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnalisisViewModel _viewModel = AnalisisViewModel();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Ambil byte gambar (wajib untuk Web)
      final bytes = await pickedFile.readAsBytes();
      _viewModel.setImage(pickedFile, bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Asisten Investasi Gig')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              color: Colors.grey.shade200,
              // Tampilkan gambar dengan aman untuk Web
              child: _viewModel.webImageBytes != null
                  ? Image.memory(_viewModel.webImageBytes!, fit: BoxFit.contain)
                  : Center(child: Text('Belum ada gambar dipilih')),
            ),
            SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text('Pilih Foto'),
                ),
                ElevatedButton.icon(
                  // Perbaikan logika tombol null
                  onPressed: (_viewModel.webImageBytes == null || _viewModel.isLoading)
                      ? null 
                      : () => _viewModel.prosesAnalisis(),
                  icon: _viewModel.isLoading 
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.analytics),
                  label: Text('Analisis AI'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            Text('Hasil Analisis:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            
            if (_viewModel.isLoading)
               Center(child: CircularProgressIndicator())
            else if (_viewModel.hasilAnalisis != null)
               ResultCard(hasil: _viewModel.hasilAnalisis!)
            else
               Text('Silakan pilih gambar dan tekan Analisis.'),
          ],
        ),
      ),
    );
  }
}