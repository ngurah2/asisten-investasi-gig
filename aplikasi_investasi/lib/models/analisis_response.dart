// lib/models/analisis_response.dart
class AnalisisResponse {
  final String status;
  final String? pesan;
  final int? pendapatanTerdeteksi;
  final int? kebutuhanHarian;
  final int? surplus;
  final String? rekomendasiInvestasi;

  AnalisisResponse({
    required this.status,
    this.pesan,
    this.pendapatanTerdeteksi,
    this.kebutuhanHarian,
    this.surplus,
    this.rekomendasiInvestasi,
  });

  factory AnalisisResponse.fromJson(Map<String, dynamic> json) {
    return AnalisisResponse(
      status: json['status'] ?? 'gagal',
      pesan: json['pesan'],
      pendapatanTerdeteksi: json['pendapatan_terdeteksi'],
      kebutuhanHarian: json['kebutuhan_harian'],
      surplus: json['surplus'],
      rekomendasiInvestasi: json['rekomendasi_investasi'],
    );
  }
}