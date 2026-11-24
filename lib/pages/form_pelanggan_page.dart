// Mengimpor pustaka antarmuka Flutter Material 3
import 'package:flutter/material.dart';
// Mengimpor pustaka geolocator untuk mengakses sensor GPS hardware
import 'package:geolocator/geolocator.dart';
// Mengimpor format waktu internasional
import 'package:intl/intl.dart';
// Mengimpor model data Pelanggan dan pembantu database SQLite
import '../models/pelanggan.dart';
import '../helpers/database_helper.dart';

// Halaman formulir dwifungsi: Tambah Pelanggan Baru & Edit Data Pelanggan
class FormPelangganPage extends StatefulWidget {
  // Parameter opsional: jika null maka mode Tambah, jika berisi data maka mode Edit
  final Pelanggan? pelanggan;
  const FormPelangganPage({super.key, this.pelanggan});

  @override
  State<FormPelangganPage> createState() => _FormPelangganPageState();
}

class _FormPelangganPageState extends State<FormPelangganPage> {
  // Kunci form global untuk validasi input pengguna
  final _formKey = GlobalKey<FormState>();
  // Kontroler teks untuk setiap field input
  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  late TextEditingController _nomorWaController;
  late TextEditingController _alamatController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  // Status loading saat mengambil titik koordinat satelit GPS
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    // Mendeteksi apakah form dalam mode edit atau tambah baru
    final isEdit = widget.pelanggan != null;
    // Menghasilkan kode member otomatis jika tambah baru (Contoh: CUST-8492)
    final autoKode =
        'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _kodeController = TextEditingController(
      text: isEdit ? widget.pelanggan!.kodePelanggan : autoKode,
    );
    _namaController = TextEditingController(
      text: isEdit ? widget.pelanggan!.namaPelanggan : '',
    );
    _nomorWaController = TextEditingController(
      text: isEdit ? widget.pelanggan!.nomorWa : '',
    );
    _alamatController = TextEditingController(
      text: isEdit ? widget.pelanggan!.alamat : '',
    );
    _latitudeController = TextEditingController(
      text: isEdit && widget.pelanggan!.latitude != null
          ? widget.pelanggan!.latitude.toString()
          : '',
    );
    _longitudeController = TextEditingController(
      text: isEdit && widget.pelanggan!.longitude != null
          ? widget.pelanggan!.longitude.toString()
          : '',
    );
  }

  @override
  void dispose() {
    // Membersihkan seluruh memori kontroler saat halaman ditutup
    _kodeController.dispose();
    _namaController.dispose();
    _nomorWaController.dispose();
    _alamatController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // Fungsi utama untuk merekam titik koordinat satelit GPS menggunakan geolocator
  Future<void> _ambilKoordinatGps() async {
    setState(() {
      _isLoadingGps = true;
    });
    try {
      // 1. Memeriksa apakah fitur lokasi pada smartphone/perangkat aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Layanan GPS perangkat belum aktif. Silakan aktifkan GPS Anda.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoadingGps = false);
        return;
      }
      // 2. Memeriksa izin runtime (Runtime Permission) akses lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Meminta izin kepada pengguna
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin akses lokasi ditolak oleh pengguna.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoadingGps = false);
          return;
        }
      }
      // 3. Menangani penolakan permanen
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoadingGps = false);
        return;
      }
      // 4. Mengunci titik koordinat posisi saat ini dengan akurasi tinggi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // 5. Mengisi field teks koordinat secara otomatis
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _isLoadingGps = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Titik GPS berhasil dikunci: '
              '(${position.latitude.toStringAsFixed(6)}, '
              '${position.longitude.toStringAsFixed(6)})',
            ),
            backgroundColor: const Color(0xFF0D9488), // Warna Teal sukses
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingGps = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil koordinat GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi simpan data pelanggan ke basis data SQLite
  Future<void> _simpanPelanggan() async {
    // Memastikan seluruh isian form lolos validasi
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.pelanggan != null;
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    // Mengurai nilai koordinat (boleh null jika pelanggan menolak direkam lokasinya)
    final double? lat = double.tryParse(_latitudeController.text.trim());
    final double? lng = double.tryParse(_longitudeController.text.trim());
    // Membangun objek Pelanggan
    final pelangganBaru = Pelanggan(
      id: isEdit ? widget.pelanggan!.id : null,
      kodePelanggan: _kodeController.text.trim(),
      namaPelanggan: _namaController.text.trim(),
      nomorWa: _nomorWaController.text.trim(),
      alamat: _alamatController.text.trim(),
      latitude: lat,
      longitude: lng,
      createdAt: isEdit ? widget.pelanggan!.createdAt : now,
    );
    try {
      if (isEdit) {
        // Operasi UPDATE ke tabel SQLite
        await DatabaseHelper.instance.updatePelanggan(pelangganBaru);
      } else {
        // Operasi INSERT ke tabel SQLite
        await DatabaseHelper.instance.insertPelanggan(pelangganBaru);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Data pelanggan berhasil diperbarui!'
                  : 'Pelanggan baru berhasil ditambahkan!',
            ),
            backgroundColor: const Color(0xFF1E3A8A), // Navy Profesional
          ),
        );
        // Kembali ke halaman sebelumnya dan memberi tanda refresh data
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pelanggan != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Data Pelanggan' : 'Tambah Pelanggan Baru'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Panduan Edukatif
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rekam nomor WhatsApp untuk pengiriman nota digital '
                        'dan simpan titik koordinat GPS untuk rute '
                        'pengantaran pesanan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Input Kode Pelanggan / ID Member
              TextFormField(
                controller: _kodeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Member / ID Pelanggan *',
                  hintText: 'Contoh: CUST-001',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kode pelanggan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Input Nama Lengkap Pelanggan
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Pelanggan / Mitra Usaha *',
                  hintText: 'Contoh: Warung Berkah Ibu Rini',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama pelanggan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 3. Input Nomor WhatsApp
              TextFormField(
                controller: _nomorWaController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Kontak WhatsApp *',
                  hintText: 'Contoh: 081234567890 atau 628...',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor WhatsApp wajib diisi';
                  }
                  if (value.length < 9) {
                    return 'Nomor telepon tidak valid (terlalu pendek)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 4. Input Alamat Domisili / Lokasi Toko
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat Domisili / Pengantaran Barang *',
                  hintText:
                      'Contoh: Jl. Kayu Tangi 1 Jalur 2 No. 15, Banjarmasin',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat pelanggan wajib diisi untuk logistik';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Bagian Perekaman Titik Koordinat GPS (LBS Feature)
              Card(
                elevation: 1,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF0D9488)),
                          SizedBox(width: 8),
                          Text(
                            'Titik Lokasi Pengantaran (GPS Satelit)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ambil posisi saat ini jika Anda berada di lokasi '
                        'fisik rumah/toko pelanggan:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tombol Eksekusi GPS Geolocator
                      ElevatedButton.icon(
                        onPressed: _isLoadingGps ? null : _ambilKoordinatGps,
                        icon: _isLoadingGps
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          _isLoadingGps
                              ? 'Mengunci Koordinat Satelit GPS...'
                              : 'Ambil Koordinat GPS Saat Ini',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF0D9488), // Teal Aksen
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Baris Input Latitude & Longitude (Tampil Otomatis)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                hintText: '-3.298280',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                hintText: '114.588820',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan Form Pelanggan
              ElevatedButton(
                onPressed: _simpanPelanggan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A), // Navy Utama
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEdit ? 'Perbarui Data Pelanggan' : 'Simpan Pelanggan Baru',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
