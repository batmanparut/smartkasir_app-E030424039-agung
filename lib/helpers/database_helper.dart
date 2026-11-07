import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/produk.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('smartkasir.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Khusus Flutter Web / Chrome
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;

      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    }

    // Android / iOS / platform non-web
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // ============================================================
  // CREATE TABLE + SEED DATA AWAL
  // ============================================================

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Seed 6 produk awal dari model Produk
    for (final produk in produkAwalSQLite) {
      await db.insert(
        'produk',
        produk.toMap(),
      );
    }
  }

  // ============================================================
  // CREATE / INSERT
  // ============================================================

  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;

    return await db.insert(
      'produk',
      produk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============================================================
  // READ / GET ALL
  // ============================================================

  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      orderBy: 'id DESC',
    );

    return result
        .map((json) => Produk.fromMap(json))
        .toList();
  }

  // ============================================================
  // READ / FILTER KATEGORI
  // ============================================================

  Future<List<Produk>> getProdukByKategori(
    String kategori,
  ) async {
    final db = await instance.database;

    // Jika memilih "Semua", ambil seluruh produk
    if (kategori == 'Semua') {
      return await getAllProduk();
    }

    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'id DESC',
    );

    return result
        .map((json) => Produk.fromMap(json))
        .toList();
  }

  // ============================================================
  // SEARCH / SQL LIKE
  // ============================================================

  Future<List<Produk>> searchProduk(
    String keyword,
  ) async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      where: 'nama_produk LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'id DESC',
    );

    return result
        .map((json) => Produk.fromMap(json))
        .toList();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;

    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<int> deleteProduk(int id) async {
    final db = await instance.database;

    return await db.delete(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}