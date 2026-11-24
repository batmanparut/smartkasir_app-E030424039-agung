// Mengimpor pustaka dasar antarmuka Flutter Material 3
import 'package:flutter/material.dart';
// Mengimpor pustaka url_launcher untuk membuka rute navigasi aplikasi luar
import 'package:url_launcher/url_launcher.dart';
// Mengimpor model Pelanggan, helper basis data SQLite, dan form input
import '../models/pelanggan.dart';
import '../helpers/database_helper.dart';
import 'form_pelanggan_page.dart';

// Halaman Manajemen Master Pelanggan (CRM) dan Navigasi Pengantaran LBS
class KelolaPelangganPage extends StatefulWidget {
  const KelolaPelangganPage({super.key});

  @override
  State<KelolaPelangganPage> createState() => _KelolaPelangganPageState();
}

class _KelolaPelangganPageState extends State<KelolaPelangganPage> {
  // Kontroler kotak pencarian teks
  final TextEditingController _searchController = TextEditingController();
  // Daftar data pelanggan yang ditampilkan di antarmuka
  List<Pelanggan> _pelangganList = [];
  // Status indikator loading saat membaca SQLite
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatDataPelanggan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi membaca seluruh data pelanggan dari tabel SQLite
  Future<void> _muatDataPelanggan() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllPelanggan();
    setState(() {
      _pelangganList = data;
      _isLoading = false;
    });
  }

  // Fungsi pencarian cepat pelanggan berdasarkan nama, nomor telepon, atau kode
  Future<void> _cariPelanggan(String keyword) async {
    if (keyword.trim().isEmpty) {
      _muatDataPelanggan();
      return;
    }
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.searchPelanggan(keyword.trim());
    setState(() {
      _pelangganList = data;
      _isLoading = false;
    });
  }

  // Fungsi membuka rute navigasi pengantaran ke aplikasi Google Maps luar
  Future<void> _bukaRuteGoogleMaps(
    double latitude,
    double longitude,
    String namaPelanggan,
  ) async {
    // Membangun URL resmi Google Maps Directions API
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );
    try {
      // Memeriksa dan meluncurkan aplikasi peta eksternal
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback jika mode externalApplication gagal
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal meluncurkan Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dialog konfirmasi modal sebelum menghapus data pelanggan
  void _konfirmasiHapusPelanggan(Pelanggan pelanggan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Pelanggan?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data member '
          '"${pelanggan.namaPelanggan}" '
          '(${pelanggan.kodePelanggan})?\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.deletePelanggan(pelanggan.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pelanggan "${pelanggan.namaPelanggan}" berhasil dihapus.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              _muatDataPelanggan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pelanggan & CRM'),
        backgroundColor: const Color(0xFF1E3A8A), // Navy Utama
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Bilah Pencarian Realtime
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8FAFC),
            child: TextField(
              controller: _searchController,
              onChanged: _cariPelanggan,
              decoration: InputDecoration(
                hintText: 'Cari nama, nomor WA, atau kode member...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF1E3A8A),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _muatDataPelanggan();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

          // 2. Daftar Pelanggan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pelangganList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada data pelanggan.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Klik tombol (+) di bawah untuk menambah '
                              'member baru.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pelangganList.length,
                        itemBuilder: (context, index) {
                          final p = _pelangganList[index];
                          final hasGps = p.hasLocation;
                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Baris Header: Avatar, Nama, Badge Kode
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Lingkaran Inisial Nama
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(
                                          0xFF1E3A8A,
                                        ).withValues(alpha: 0.1),
                                        child: Text(
                                          p.namaPelanggan.isNotEmpty
                                              ? p.namaPelanggan[0]
                                                  .toUpperCase()
                                              : 'P',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Nama & Waktu Terdaftar
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.namaPelanggan,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Terdaftar: ${p.createdAt}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Badge Kode Member
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF0D9488),
                                          ),
                                        ),
                                        child: Text(
                                          p.kodePelanggan,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0D9488),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 18),

                                  // Baris Kontak WhatsApp
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        p.nomorWa,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Baris Alamat Domisili
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.place,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          p.alamat,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Baris Tombol Aksi & Navigasi GPS
                                  Row(
                                    children: [
                                      // Status Koordinat GPS & Tombol Rute
                                      if (hasGps)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _bukaRuteGoogleMaps(
                                              p.latitude!,
                                              p.longitude!,
                                              p.namaPelanggan,
                                            ),
                                            icon: const Icon(
                                              Icons.directions,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Rute Google Maps',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF0D9488),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.location_off,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'GPS Belum Terekam',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),

                                      // Tombol Edit
                                      IconButton.filledTonal(
                                        onPressed: () async {
                                          final refresh =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) =>
                                                  FormPelangganPage(
                                                pelanggan: p,
                                              ),
                                            ),
                                          );
                                          if (refresh == true) {
                                            _muatDataPelanggan();
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 18,
                                        ),
                                        tooltip: 'Edit Data Pelanggan',
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.blue.shade50,
                                          foregroundColor:
                                              const Color(0xFF1E3A8A),
                                        ),
                                      ),

                                      // Tombol Hapus
                                      IconButton.filledTonal(
                                        onPressed: () =>
                                            _konfirmasiHapusPelanggan(p),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        tooltip: 'Hapus Pelanggan',
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.red.shade50,
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

      // Tombol Mengambang: Tambah Pelanggan Baru (+)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => const FormPelangganPage(),
            ),
          );
          if (refresh == true) {
            _muatDataPelanggan();
          }
        },
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Member'),
      ),
    );
  }
}
