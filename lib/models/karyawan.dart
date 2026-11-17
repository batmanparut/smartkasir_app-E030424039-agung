
// Model data representasi entitas Karyawan pada SmartKasir
class Karyawan {
  // 1. ATRIBUT ENTITAS KARYAWAN
  final int? id;
  final String namaKaryawan;
  final String pin;
  final String peran;

  // 2. KONSTRUKTOR MODEL KARYAWAN
  const Karyawan({
    this.id,
    required this.namaKaryawan,
    required this.pin,
    required this.peran,
  });

  // 3. METODE SERIALISASI (Dart Object -> Map<String, dynamic>)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_karyawan': namaKaryawan,
      'pin': pin,
      'peran': peran,
    };
  }

  // 4. METODE DESERIALISASI (Map<String, dynamic> -> Dart Object)
  factory Karyawan.fromMap(Map<String, dynamic> map) {
    return Karyawan(
      id: map['id'] as int?,
      namaKaryawan: map['nama_karyawan'] as String,
      pin: map['pin'] as String,
      peran: map['peran'] as String,
    );
  }
}
