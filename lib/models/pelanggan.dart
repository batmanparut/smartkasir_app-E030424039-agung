// Model data representasi entitas Pelanggan / Member pada aplikasi SmartKasir
class Pelanggan {
 // Kunci primer unik auto-increment basis data SQLite
 final int? id;
 // Kode unik identitas member pelanggan (Contoh: CUST-001)
 final String kodePelanggan;
 // Nama lengkap pelanggan atau nama usaha binaan
 final String namaPelanggan;
 // Nomor kontak aktif WhatsApp pelanggan untuk pengiriman nota / komunikasi
 final String nomorWa;
 // Alamat domisili fisik pelanggan atau titik pengantaran barang
 final String alamat;
 // Titik koordinat garis lintang GPS rumah/toko pelanggan (nullable jika belum diset)
 final double? latitude;
 // Titik koordinat garis bujur GPS rumah/toko pelanggan (nullable jika belum diset)
 final double? longitude;
 // Catatan waktu pendaftaran pelanggan ke dalam sistem kasir
 final String createdAt;
 // Konstruktor utama kelas Pelanggan
 Pelanggan({
 this.id,
 required this.kodePelanggan,
 required this.namaPelanggan,
 required this.nomorWa,
 required this.alamat,
 this.latitude,
 this.longitude,
 required this.createdAt,
 });
 // Mengonversi objek Pelanggan menjadi Map (Dictionary) untuk operasi simpan ke SQLite
 Map<String, dynamic> toMap() {
 return {
 'id': id,
 'kode_pelanggan': kodePelanggan,
 'nama_pelanggan': namaPelanggan,
 'nomor_wa': nomorWa,
 'alamat': alamat,
 'latitude': latitude,
 'longitude': longitude,
 'created_at': createdAt,
 };
 }
 // Mengonversi baris data Map dari tabel SQLite kembali menjadi objek Pelanggan
 factory Pelanggan.fromMap(Map<String, dynamic> map) {
 return Pelanggan(
 id: map['id'] as int?,
 kodePelanggan: map['kode_pelanggan'] as String? ?? '',
 namaPelanggan: map['nama_pelanggan'] as String? ?? '',
 nomorWa: map['nomor_wa'] as String? ?? '',
 alamat: map['alamat'] as String? ?? '',
 latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
 longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
 createdAt: map['created_at'] as String? ?? '',
 );
 }
 // Helper untuk mengecek apakah pelanggan sudah memiliki titik koordinat GPS
 bool get hasLocation => latitude != null && longitude != null;
 // Helper untuk mendapatkan koordinat dalam format teks ringkas
 String get coordinateText {
 if (hasLocation) {
 return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
 }
 return 'Belum terekam';
 }
}
