
import 'package:path/path.dart';
import 'profile_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

class ProfileDbHelper {
  static final ProfileDbHelper _instance = ProfileDbHelper._internal();
  factory ProfileDbHelper() => _instance;
  ProfileDbHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'profile.db');

    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE profiles(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          phone TEXT,
          address TEXT,
          profilePic TEXT
        )
      ''');
    });
  }

  Future<void> insertProfile(FarmerProfile profile) async {
    final db = await database;
    await db.insert('profiles', profile.toMap());
  }

  Future<FarmerProfile?> getProfileByPhone(String phone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (maps.isNotEmpty) {
      return FarmerProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateProfile(FarmerProfile profile) async {
    final db = await database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }
}
