import 'dart:io';
import 'package:flutter/foundation.dart';
import '/core/constant/app_strings.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
// Only needed for desktop:
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    // ✅ Init FFI for desktop only
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppStrings.databaseName);

    return await openDatabase(
      path,
      version: AppStrings.databaseVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migration example
        // if (oldVersion < 2) {
        //   await db.execute("ALTER TABLE weapons ADD COLUMN synced INTEGER DEFAULT 0");
        // }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE weapons(
        weaponId TEXT PRIMARY KEY,
        userId TEXT,
        firearm TEXT,
        notes TEXT,
        createdAt TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions(
        recordId TEXT PRIMARY KEY,
        userId TEXT,
        weaponId TEXT,
        targetPaper TEXT,
        distance TEXT,
        caliber TEXT,
        imagePath TEXT,
        finalShotResult TEXT,
        synced INTEGER DEFAULT 0,
        createdAt TEXT,
        FOREIGN KEY (weaponId) REFERENCES weapons(weaponId)
      )
    ''');

    await db.execute('''
      CREATE TABLE firearms(
        brand TEXT,
        caliber TEXT,
        firing_mechanism TEXT,
        generation TEXT,
        make TEXT,
        model TEXT,
        type TEXT,
        caliber_diameter REAL
      )
    ''');

    await db.execute('''
  CREATE TABLE userFirearms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    brand TEXT,
    caliber TEXT,
    firing_mechanism TEXT,
    generation TEXT,
    make TEXT,
    model TEXT,
    type TEXT,
    caliber_diameter REAL
  )
''');
  }
}
