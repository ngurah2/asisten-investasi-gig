// lib/views/widgets/result_card.dart
import 'package:flutter/material.dart';
import '../../models/analisis_response.dart';

class ResultCard extends StatelessWidget {
  final AnalisisResponse hasil;

  const ResultCard({Key? key, required this.hasil}) : super(key: key);

  Color _getSurplusColor(int? surplus) {
    if (surplus == null) return Colors.grey;
    if (surplus > 0) return Colors.green;
    if (surplus == 0) return Colors.grey;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (hasil.status == 'gagal') {
      return Card(
        color: Colors.red.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(hasil.pesan ?? 'Terjadi kesalahan.', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pendapatan: Rp ${hasil.pendapatanTerdeteksi ?? 0}'),
            Text('Kebutuhan Harian: Rp ${hasil.kebutuhanHarian ?? 0}'),
            Divider(),
            Text(
              'Surplus: Rp ${hasil.surplus ?? 0}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getSurplusColor(hasil.surplus),
              ),
            ),
            SizedBox(height: 10),
            Text('Rekomendasi Investasi:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              hasil.rekomendasiInvestasi ?? '-',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}