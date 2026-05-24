import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/camera_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'work_camera.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE camera_profiles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            colorIndex INTEGER DEFAULT 0,
            filenameTemplate TEXT DEFAULT '{相机名}_{日期}_{序号}',
            storagePath TEXT DEFAULT '',
            imageFormat TEXT DEFAULT 'jpg',
            compressionQuality INTEGER DEFAULT 95,
            maxWidth INTEGER DEFAULT 0,
            maxHeight INTEGER DEFAULT 0,
            isDeleted INTEGER DEFAULT 0,
            deletedAt INTEGER,
            photoCount INTEGER DEFAULT 0,
            wallpaperPath TEXT,
            dailyDate TEXT,
            dailyCount INTEGER DEFAULT 0,
            customText TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE camera_profiles ADD COLUMN wallpaperPath TEXT');
          await db.execute('ALTER TABLE camera_profiles ADD COLUMN dailyDate TEXT');
          await db.execute('ALTER TABLE camera_profiles ADD COLUMN dailyCount INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE camera_profiles ADD COLUMN customText TEXT');
        }
      },
    );
  }

  // --- active profiles ---

  Future<List<CameraProfile>> getActiveProfiles() async {
    final d = await db;
    final rows = await d.query(
      'camera_profiles',
      where: 'isDeleted = 0',
      orderBy: 'name',
    );
    return rows.map((r) => CameraProfile.fromMap(r)).toList();
  }

  Future<CameraProfile?> getProfile(String id) async {
    final d = await db;
    final rows = await d.query('camera_profiles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return CameraProfile.fromMap(rows.first);
  }

  Future<void> insertProfile(CameraProfile p) async {
    final d = await db;
    await d.insert('camera_profiles', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProfile(CameraProfile p) async {
    final d = await db;
    await d.update('camera_profiles', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> incrementPhotoCount(String id) async {
    final d = await db;
    await d.rawUpdate(
        'UPDATE camera_profiles SET photoCount = photoCount + 1 WHERE id = ?', [id]);
  }

  Future<String> incrementDailyCount(String id) async {
    final d = await db;
    final today = DateFormat('yyyyMMdd').format(DateTime.now());

    final rows = await d.query('camera_profiles',
        columns: ['dailyDate', 'dailyCount'],
        where: 'id = ?',
        whereArgs: [id]);

    if (rows.isEmpty) throw Exception('Profile not found');

    final oldDate = rows.first['dailyDate'] as String?;
    final oldCount = (rows.first['dailyCount'] as int?) ?? 0;

    final int newCount;
    if (oldDate != today) {
      newCount = 1;
    } else {
      newCount = oldCount + 1;
    }

    String seqStr;
    if (newCount <= 999) {
      seqStr = newCount.toString().padLeft(3, '0');
    } else {
      final suffixIndex = (newCount - 1) ~/ 999 - 1;
      final seqNum = (newCount - 1) % 999 + 1;
      final suffix = suffixIndex < 26 ? String.fromCharCode(65 + suffixIndex) : '';
      seqStr = '${seqNum.toString().padLeft(3, '0')}$suffix';
    }

    await d.update('camera_profiles', {
      'dailyDate': today,
      'dailyCount': newCount,
    }, where: 'id = ?', whereArgs: [id]);

    await d.rawUpdate(
        'UPDATE camera_profiles SET photoCount = photoCount + 1 WHERE id = ?', [id]);

    return seqStr;
  }

  // --- soft delete / recycle bin ---

  Future<void> softDelete(String id) async {
    final d = await db;
    await d.update('camera_profiles', {
      'isDeleted': 1,
      'deletedAt': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restore(String id) async {
    final d = await db;
    await d.update('camera_profiles', {
      'isDeleted': 0,
      'deletedAt': null,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CameraProfile>> getTrashProfiles() async {
    final d = await db;
    final rows = await d.query(
      'camera_profiles',
      where: 'isDeleted = 1',
      orderBy: 'deletedAt DESC',
    );
    return rows.map((r) => CameraProfile.fromMap(r)).toList();
  }

  Future<void> purgeExpired() async {
    final d = await db;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    await d.delete(
      'camera_profiles',
      where: 'isDeleted = 1 AND deletedAt < ?',
      whereArgs: [cutoff.millisecondsSinceEpoch],
    );
  }

  Future<void> permanentlyDelete(String id) async {
    final d = await db;
    await d.delete('camera_profiles', where: 'id = ?', whereArgs: [id]);
  }
}
