
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/produk.dart';
import '../models/karyawan.dart';

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

  // ============================================================
  // INISIALISASI DATABASE
  // ============================================================

  Future<Database> _initDB(String filePath) async {
    // Khusus Flutter Web / Chrome
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;

      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createDB,
          onUpgrade: _onUpgradeDB,
        ),
      );
    }

    // Android / iOS / platform non-web
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  // ============================================================
  // CREATE TABLE + SEED DATA AWAL
  // ============================================================

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    // Membuat tabel produk
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

    // Memasukkan 6 produk awal
    for (final produk in produkAwalSQLite) {
      await db.insert(
        'produk',
        produk.toMap(),
      );
    }

    // Membuat tabel karyawan
    await db.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    // Memasukkan data karyawan awal
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Ahmad Kasir', '1234', 'Kasir')
    ''');

    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Siti Supervisor', '8888', 'Manajer')
    ''');
  }

  // ============================================================
  // DATABASE MIGRATION: VERSI 1 KE VERSI 2
  // ============================================================

  Future<void> _onUpgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS karyawan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_karyawan TEXT NOT NULL,
          pin TEXT NOT NULL,
          peran TEXT NOT NULL
        )
      ''');

      await db.rawInsert('''
        INSERT INTO karyawan (nama_karyawan, pin, peran)
        VALUES ('Ahmad Kasir', '1234', 'Kasir')
      ''');
    }
  }

  // ============================================================
  // CRUD PRODUK
  // ============================================================

  // CREATE / INSERT PRODUK
  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;

    return await db.insert(
      'produk',
      produk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ / GET ALL PRODUK
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

  // READ / FILTER KATEGORI
  Future<List<Produk>> getProdukByKategori(
    String kategori,
  ) async {
    final db = await instance.database;

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

  // SEARCH / SQL LIKE
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

  // UPDATE PRODUK
  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;

    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // DELETE PRODUK
  Future<int> deleteProduk(int id) async {
    final db = await instance.database;

    return await db.delete(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // CRUD KARYAWAN
  // ============================================================

  // CREATE / INSERT KARYAWAN
  Future<int> insertKaryawan(Karyawan karyawan) async {
    final db = await instance.database;

    return await db.insert(
      'karyawan',
      karyawan.toMap(),
    );
  }

  // READ / GET ALL KARYAWAN
  Future<List<Karyawan>> getAllKaryawan() async {
    final db = await instance.database;

    final result = await db.query(
      'karyawan',
      orderBy: 'id ASC',
    );

    return result
        .map((json) => Karyawan.fromMap(json))
        .toList();
  }

  // UPDATE KARYAWAN
  Future<int> updateKaryawan(Karyawan karyawan) async {
    final db = await instance.database;

    return await db.update(
      'karyawan',
      karyawan.toMap(),
      where: 'id = ?',
      whereArgs: [karyawan.id],
    );
  }

  // DELETE KARYAWAN
  Future<int> deleteKaryawan(int id) async {
    final db = await instance.database;

    return await db.delete(
      'karyawan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
