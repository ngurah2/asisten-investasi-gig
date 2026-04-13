import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late Future<List<dynamic>> _futureRiwayat;

  @override
  void initState() {
    super.initState();
    _futureRiwayat = ApiService.ambilRiwayat();
  }

  String formatRp(int angka) {
    return angka.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal[700]), 
        title: Text('Buku Besar GIM', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada riwayat.'));

          List<dynamic> riwayatList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: riwayatList.length,
            itemBuilder: (context, index) {
              var item = riwayatList[index];
              int surplus = item['surplus'];
              
              // --- LOGIKA 3 WARNA UNTUK RIWAYAT ---
              Color avatarBgColor;
              Color iconColor;
              IconData statusIcon;

              if (surplus > 0) {
                avatarBgColor = Colors.teal.withOpacity(0.1);
                iconColor = Colors.teal[700]!;
                statusIcon = Icons.trending_up;
              } else if (surplus == 0) {
                avatarBgColor = Colors.grey.withOpacity(0.1);
                iconColor = Colors.grey[700]!;
                statusIcon = Icons.trending_flat; // Ikon lurus untuk 0
              } else {
                avatarBgColor = Colors.red.withOpacity(0.1);
                iconColor = Colors.red;
                statusIcon = Icons.trending_down;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: avatarBgColor, 
                    child: Icon(statusIcon, color: iconColor)
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Rp ${formatRp(item['pendapatan'])}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Surplus: Rp ${formatRp(surplus)}', style: TextStyle(color: iconColor)),
                    const Divider(),
                    Text('💡 ${item['rekomendasi']}', style: TextStyle(color: iconColor, fontSize: 13)),
                  ])),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}