import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/produk.dart';
import '../helpers/database_helper.dart';

class FormProdukPage extends StatefulWidget {
  final Produk? produk;

  const FormProdukPage({
    super.key,
    this.produk,
  });

  @override
  State<FormProdukPage> createState() => _FormProdukPageState();
}

class _FormProdukPageState extends State<FormProdukPage> {
  final _formKey = GlobalKey<FormState>();

  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _stokController = TextEditingController();
  final _gambarController = TextEditingController();
  final _diskonController = TextEditingController(text: '0');

  String _kategoriTerpilih = 'Makanan';

  final List<String> _kategoriList = [
    'Makanan',
    'Minuman',
    'Snack',
    'Lainnya',
  ];

  bool _sedangMenyimpan = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool get _isEditMode => widget.produk != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final p = widget.produk!;

      _kodeController.text = p.kodeProduk;
      _namaController.text = p.nama;

      _kategoriTerpilih = _kategoriList.contains(p.kategori)
          ? p.kategori
          : 'Makanan';

      _hargaBeliController.text = p.hargaBeli.toInt().toString();
      _hargaJualController.text = p.hargaJual.toInt().toString();
      _stokController.text = p.stok.toString();
      _gambarController.text = p.gambarUrl;
      _diskonController.text = p.diskonPersen.toString();
    } else {
      // Kode otomatis untuk produk baru
      _kodeController.text =
          'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    _gambarController.dispose();
    _diskonController.dispose();

    super.dispose();
  }

  // ============================================================
  // SIMPAN / UPDATE PRODUK
  // ============================================================

  Future<void> _simpanKeDatabase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _sedangMenyimpan = true;
    });

    try {
      final produk = Produk(
        id: widget.produk?.id,
        kodeProduk: _kodeController.text.trim(),
        nama: _namaController.text.trim(),
        kategori: _kategoriTerpilih,
        hargaBeli: double.parse(_hargaBeliController.text),
        hargaJual: double.parse(_hargaJualController.text),
        stok: int.parse(_stokController.text),
        gambarUrl: _gambarController.text.trim(),
        diskonPersen: int.parse(
          _diskonController.text.isEmpty
              ? '0'
              : _diskonController.text,
        ),
      );

      if (_isEditMode) {
        await DatabaseHelper.instance.updateProduk(produk);
      } else {
        await DatabaseHelper.instance.insertProduk(produk);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Produk berhasil diperbarui.'
                : 'Produk berhasil ditambahkan.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan produk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sedangMenyimpan = false;
        });
      }
    }
  }

  // ============================================================
  // VALIDATOR
  // ============================================================

  String? _validatorWajib(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }

    return null;
  }

  String? _validatorAngka(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }

    if (int.tryParse(value) == null) {
      return 'Masukkan angka yang valid';
    }

    return null;
  }

  String? _validatorHargaJual(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga jual wajib diisi';
    }

    final hargaBeli = int.tryParse(_hargaBeliController.text) ?? 0;
    final hargaJual = int.tryParse(value) ?? 0;

    if (hargaJual <= hargaBeli) {
      return 'Harus > Modal';
    }

    return null;
  }

  String? _validatorDiskon(String? value) {
    final d = int.tryParse(value ?? '0') ?? 0;

    if (d < 0 || d > 50) {
      return 'Diskon maksimal 50%';
    }

    return null;
  }

  // ============================================================
  // FIELD INPUT
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(String value) {
    final angka = int.tryParse(value);

    if (angka == null) {
      return '';
    }

    return _currencyFormat.format(angka);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Produk' : 'Tambah Produk',
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // INFORMASI PRODUK
                // ==================================================

                const Text(
                  'Informasi Produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // KODE PRODUK
                _buildTextField(
                  controller: _kodeController,
                  label: 'Kode Produk',
                  icon: Icons.qr_code,
                  readOnly: _isEditMode,
                  validator: _validatorWajib,
                ),

                const SizedBox(height: 16),

                // NAMA PRODUK
                _buildTextField(
                  controller: _namaController,
                  label: 'Nama Produk',
                  icon: Icons.inventory_2_outlined,
                  hint: 'Masukkan nama produk',
                  validator: _validatorWajib,
                ),

                const SizedBox(height: 16),

                // KATEGORI
                DropdownButtonFormField<String>(
                  value: _kategoriTerpilih,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _kategoriList.map(
                    (kategori) {
                      return DropdownMenuItem<String>(
                        value: kategori,
                        child: Text(kategori),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _kategoriTerpilih = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kategori wajib dipilih';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ==================================================
                // HARGA & STOK
                // ==================================================

                const Text(
                  'Harga & Stok',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // HARGA BELI
                _buildTextField(
                  controller: _hargaBeliController,
                  label: 'Harga Modal / Beli',
                  icon: Icons.money_off,
                  hint: 'Contoh: 10000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: _validatorAngka,
                ),

                const SizedBox(height: 16),

                // HARGA JUAL
                _buildTextField(
                  controller: _hargaJualController,
                  label: 'Harga Jual',
                  icon: Icons.sell_outlined,
                  hint: 'Contoh: 15000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: _validatorHargaJual,
                ),

                const SizedBox(height: 8),

                if (_hargaBeliController.text.isNotEmpty &&
                    _hargaJualController.text.isNotEmpty)
                  Text(
                    'Harga jual: ${_formatRupiah(_hargaJualController.text)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                const SizedBox(height: 16),

                // STOK
                _buildTextField(
                  controller: _stokController,
                  label: 'Stok',
                  icon: Icons.inventory_outlined,
                  hint: 'Contoh: 50',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: _validatorAngka,
                ),

                const SizedBox(height: 16),

                // DISKON
                _buildTextField(
                  controller: _diskonController,
                  label: 'Diskon (%)',
                  icon: Icons.discount_outlined,
                  hint: '0 - 50',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: _validatorDiskon,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // GAMBAR
                // ==================================================

                const Text(
                  'Gambar Produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _gambarController,
                  label: 'URL Gambar',
                  icon: Icons.image_outlined,
                  hint: 'https://...',
                ),

                const SizedBox(height: 32),

                // ==================================================
                // TOMBOL SIMPAN
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        _sedangMenyimpan ? null : _simpanKeDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _sedangMenyimpan
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _isEditMode
                                ? Icons.check_circle_outline
                                : Icons.save_outlined,
                          ),
                    label: Text(
                      _isEditMode
                          ? 'PERBARUI DATA PRODUK'
                          : 'SIMPAN PRODUK KE DATABASE',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}