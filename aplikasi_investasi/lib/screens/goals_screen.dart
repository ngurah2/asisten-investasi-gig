import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Wajib untuk TextInputFormatter
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Wajib untuk DateFormat & NumberFormat
import '../services/api_service.dart';

// Class untuk format Rupiah otomatis saat mengetik
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    final value = int.tryParse(newValue.text.replaceAll('.', '')) ?? 0;
    final formatter = NumberFormat("#,###");
    String newText = formatter.format(value).replaceAll(',', '.');
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<dynamic> _goals = [];
  bool _isLoading = false;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? 0;

    if (userId != 0) {
      var data = await ApiService.listTarget(userId);
      setState(() {
        _goals = data;
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk buka kalender
  Future<void> _pilihTanggal(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  String _formatRupiah(int angka) {
    final formatter = NumberFormat("#,###");
    return formatter.format(angka).replaceAll(',', '.');
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Impian Baru 🚀', 
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Target (Contoh: Beli Laptop)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
              decoration: const InputDecoration(labelText: 'Target Nominal (Rp)', prefixText: 'Rp '),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _deadlineController,
              readOnly: true,
              onTap: () => _pilihTanggal(context),
              decoration: const InputDecoration(
                labelText: 'Deadline (Klik untuk pilih)',
                suffixIcon: Icon(Icons.calendar_today, color: Colors.teal),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              int userId = prefs.getInt('userId') ?? 0;
              
              // Hapus titik sebelum kirim ke backend
              int nominalRaw = int.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;
              
              var res = await ApiService.tambahTarget(
                userId,
                _namaController.text,
                nominalRaw,
                _deadlineController.text,
              );

              if (res['status'] == 'sukses') {
                _namaController.clear();
                _nominalController.clear();
                _deadlineController.clear();
                Navigator.pop(context);
                _loadGoals();
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Keuangan', 
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      var goal = _goals[index];
                      double target = (goal['target_nominal'] as num).toDouble();
                      double terkumpul = (goal['terkumpul'] as num).toDouble();
                      double persen = target > 0 ? (terkumpul / target) : 0.0;
                      
                      return _buildGoalCard(goal, persen);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch_outlined, size: 80, color: Colors.teal.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Belum ada target? Yuk buat sekarang!', 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(var goal, double persen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal['nama_target'], 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${(persen * 100).toStringAsFixed(0)}%', 
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: persen.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rp ${_formatRupiah(goal['terkumpul'] ?? 0)}', 
                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                Text('Target: Rp ${_formatRupiah(goal['target_nominal'])}', 
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Deadline: ${goal['deadline']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}