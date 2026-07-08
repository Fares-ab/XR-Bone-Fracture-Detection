import 'dart:io'; 
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDB('xrbone.db'); 
    return _database!;
  }

Future<Database> _initDB(String filePath) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, filePath);

  print('DB PATH => $path'); // optional, just to see actual path

  return await openDatabase(
    path,
    version: 6, // bumped to 6 for age in requests
    onCreate: _createDB,
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE requests ADD COLUMN result_summary TEXT;'
        );
        await db.execute(
          'ALTER TABLE requests ADD COLUMN annotated_image_b64 TEXT;'
        );
      }
      if (oldVersion < 3) {
        await db.execute(
          'ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT \'Patient\';'
        );
      }
      if (oldVersion < 4) {
        await db.execute('ALTER TABLE requests ADD COLUMN patient_id INTEGER;');
        await db.execute('ALTER TABLE requests ADD COLUMN doctor_id INTEGER;');
        await db.execute('ALTER TABLE requests ADD COLUMN doctor_notes TEXT;');
      }
      if (oldVersion < 5) {
        await db.execute('ALTER TABLE users ADD COLUMN age INTEGER;');
        await db.execute('ALTER TABLE requests ADD COLUMN height REAL;');
        await db.execute('ALTER TABLE requests ADD COLUMN weight REAL;');
      }
      if (oldVersion < 6) {
        await db.execute('ALTER TABLE requests ADD COLUMN age INTEGER;');
      }
    },
  );
}

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT NOT NULL,
      age INTEGER,
      profile_pic_index INTEGER NOT NULL,
      role TEXT NOT NULL DEFAULT 'Patient'
    )
    ''');
    
await db.execute('''
  CREATE TABLE requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER,
    doctor_id INTEGER,
    patient_name TEXT NOT NULL,
    body_part TEXT NOT NULL,
    date TEXT NOT NULL,
    status TEXT NOT NULL,
    result_summary TEXT,
    annotated_image_b64 TEXT,
    doctor_notes TEXT,
    height REAL,
    weight REAL,
    age INTEGER
  )
''');
  }

  // --- User Management ---
  Future<int> registerUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user);
  }

  Future<bool> isUsernameTaken(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    
    if (result.isNotEmpty) {
      return result.first; 
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> fetchUserById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
  
  // --- Request History Management ---
  Future<int> insertRequest(Map<String, dynamic> request) async {
    final db = await instance.database;
    return await db.insert('requests', request);
  }

  Future<List<Map<String, dynamic>>> fetchRequests(int userId, String role) async {
    final db = await instance.database;
    if (role == 'Doctor') {
      return await db.query('requests', where: 'doctor_id = ?', whereArgs: [userId], orderBy: 'id DESC');
    } else {
      return await db.query('requests', where: 'patient_id = ?', whereArgs: [userId], orderBy: 'id DESC');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRequestsByPatientId(int patientId) async {
    final db = await instance.database;
    return await db.query('requests', where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'id DESC');
  }

  /// Returns {reports, patients, fractures} counts for a doctor.
  Future<Map<String, int>> fetchDoctorStats(int doctorId) async {
    final db = await instance.database;

    final reportsResult = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM requests WHERE doctor_id = ?', [doctorId]);
    final reports = (reportsResult.first['cnt'] as int?) ?? 0;

    final patientsResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT patient_id) AS cnt FROM requests WHERE doctor_id = ?', [doctorId]);
    final patients = (patientsResult.first['cnt'] as int?) ?? 0;

    final fracturesResult = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM requests WHERE doctor_id = ? AND result_summary LIKE '%⚠ Fracture DETECTED%'", [doctorId]);
    final fractures = (fracturesResult.first['cnt'] as int?) ?? 0;

    return {'reports': reports, 'patients': patients, 'fractures': fractures};
  }

  /// Returns {reports, completed} counts for a patient.
  Future<Map<String, int>> fetchPatientStats(int patientId) async {
    final db = await instance.database;

    final reportsResult = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM requests WHERE patient_id = ?', [patientId]);
    final reports = (reportsResult.first['cnt'] as int?) ?? 0;

    final completedResult = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM requests WHERE patient_id = ? AND status = 'Completed'", [patientId]);
    final completed = (completedResult.first['cnt'] as int?) ?? 0;

    return {'reports': reports, 'completed': completed};
  }
}