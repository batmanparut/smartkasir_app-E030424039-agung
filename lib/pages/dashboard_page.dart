import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../helpers/database_helper.dart';
import '../models/produk.dart';
import 'form_produk_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Produk>> _produkFuture;

  int _kategoriTerpilih = 0;
  String _keywordPencarian = '';

  final List<String> _kategoriList = [
    'Semua',
    'Makanan',
    'Minuman',
    'Snack',
  ];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _muatDataProduk();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _muatDataProduk() {
    if (_keywordPencarian.trim().isNotEmpty) {
      _produkFuture = DatabaseHelper.instance.searchProduk(
        _keywordPencarian.trim(),
      );
    } else {
      _produkFuture = DatabaseHelper.instance.getProdukByKategori(
        _kategoriList[_kategoriTerpilih],
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _ubahKategori(int index) {
    setState(() {
      _kategoriTerpilih = index;
      _keywordPencarian = '';
      _searchController.clear();
    });

    _muatDataProduk();
  }

  Future<void> _tambahProduk() async {
    final hasil = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormProdukPage(),
      ),
    );

    if (hasil == true) {
      _muatDataProduk();
    }
  }

  Future<void> _editProduk(Produk produk) async {
    final hasil = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormProdukPage(produk: produk),
      ),
    );

    if (hasil == true) {
      _muatDataProduk();
    }
  }

  Future<void> _hapusProduk(Produk produk) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Produk'),
          content: Text(
            'Apakah Anda yakin ingin menghapus produk "${produk.nama}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true) {
      return;
    }

    try {
      await DatabaseHelper.instance.deleteProduk(produk.id!);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil dihapus'),
        ),
      );

      _muatDataProduk();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus produk: $e'),
        ),
      );
    }
  }

  String _formatHarga(double harga) {
    return _currencyFormat.format(harga);
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _keywordPencarian = value;
        });

        _muatDataProduk();
      },
      decoration: InputDecoration(
        hintText: 'Cari nama produk...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _keywordPencarian = '';
                  });

                  _muatDataProduk();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildKategoriFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kategoriList.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final kategori = _kategoriList[index];

          return ChoiceChip(
            label: Text(kategori),
            selected: _kategoriTerpilih == index,
            onSelected: (_) {
              _ubahKategori(index);
            },
          );
        },
      ),
    );
  }

  Widget _buildProdukCard(Produk produk) {
    final stokAman = produk.stok > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _editProduk(produk),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child:produk.gambarUrl.trim().isNotEmpty
                        ? Image.network(
                            produk.gambarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: stokAman
                            ? Colors.green.withValues(alpha: 0.9)
                            : Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Stok ${produk.stok}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                produk.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                produk.kategori,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatHarga(produk.hargaJual),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editProduk(produk);
                      } else if (value == 'delete') {
                        _hapusProduk(produk);
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline),
                              SizedBox(width: 8),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProdukList() {
    return FutureBuilder<List<Produk>>(
      future: _produkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Terjadi kesalahan saat memuat produk.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _muatDataProduk,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final produkList = snapshot.data ?? [];

        if (produkList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Produk tidak ditemukan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _keywordPencarian.isNotEmpty
                        ? 'Coba gunakan kata kunci pencarian yang lain.'
                        : 'Belum ada produk pada kategori ini.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisExtent: 220,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: produkList.length,
          itemBuilder: (context, index) {
            return _buildProdukCard(produkList[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartKasir',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _muatDataProduk,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahProduk,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 14),
              _buildKategoriFilter(),
              const SizedBox(height: 8),
              Expanded(
                child: _buildProdukList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}