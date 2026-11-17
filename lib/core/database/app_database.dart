
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rebs_hrms.db');

    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createAttendanceTables(db);
        await _createLeaveTables(db);
        await _createEmployeeTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createLeaveTables(db);
        }

        if (oldVersion < 3) {
          await _createEmployeeTable(db);
        }
      },
    );

    return _database!;
  }

  // ---------------- ATTENDANCE TABLES ----------------

  Future<void> _createAttendanceTables(Database db) async {
    await db.execute('''
      CREATE TABLE attendance_events (
        eventId TEXT PRIMARY KEY,
        eventType TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        syncStatus TEXT NOT NULL,
        errorMessage TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_cache (
        date TEXT PRIMARY KEY,
        checkIn TEXT,
        checkOut TEXT,
        status TEXT NOT NULL
      )
    ''');
  }

  // ---------------- LEAVE TABLES ----------------

  Future<void> _createLeaveTables(Database db) async {
    await db.execute('''
      CREATE TABLE leave_balance_cache (
        id INTEGER PRIMARY KEY,
        casualBalance INTEGER NOT NULL,
        sickBalance INTEGER NOT NULL,
        cachedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE leave_requests_cache (
        requestId TEXT PRIMARY KEY,
        leaveType TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        reason TEXT NOT NULL,
        totalDays INTEGER NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT
      )
    ''');
  }

  // ---------------- EMPLOYEE TABLE ----------------

  Future<void> _createEmployeeTable(Database db) async {
    await db.execute('''
      CREATE TABLE employee_cache (
        id INTEGER PRIMARY KEY,
        employeeName TEXT NOT NULL,
        employeeId TEXT NOT NULL,
        department TEXT NOT NULL,
        leaveBalance INTEGER NOT NULL
      )
    ''');
  }

  // ---------------- EMPLOYEE CACHE METHODS ----------------

  Future<void> cacheEmployee(Map<String, dynamic> employee) async {
    final db = await database;

    await db.insert(
      'employee_cache',
      {
        'id': 1,
        'employeeName': employee['employeeName'],
        'employeeId': employee['employeeId'],
        'department': employee['department'],
        'leaveBalance': employee['leaveBalance'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedEmployee() async {
    final db = await database;

    final result = await db.query(
      'employee_cache',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  // ---------------- ATTENDANCE METHODS ----------------

  Future<void> insertPendingEvent(Map<String, dynamic> event) async {
    final db = await database;

    await db.insert(
      'attendance_events',
      {
        ...event,
        'syncStatus': 'PENDING',
        'errorMessage': null,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    final db = await database;

    return db.query(
      'attendance_events',
      where: 'syncStatus = ?',
      whereArgs: ['PENDING'],
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> updateEventStatus({
    required String eventId,
    required String status,
    String? errorMessage,
  }) async {
    final db = await database;

    await db.update(
      'attendance_events',
      {
        'syncStatus': status,
        'errorMessage': errorMessage,
      },
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final db = await database;

    return db.query(
      'attendance_events',
      orderBy: 'createdAt DESC',
    );
  }

  Future<void> cacheAttendance(
    List<Map<String, dynamic>> records,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (final record in records) {
      batch.insert(
        'attendance_cache',
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedAttendance() async {
    final db = await database;

    return db.query(
      'attendance_cache',
      orderBy: 'date DESC',
    );
  }

  // ---------------- LEAVE BALANCE METHODS ----------------

  Future<void> cacheLeaveBalance({
    required int casualBalance,
    required int sickBalance,
  }) async {
    final db = await database;

    await db.insert(
      'leave_balance_cache',
      {
        'id': 1,
        'casualBalance': casualBalance,
        'sickBalance': sickBalance,
        'cachedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedLeaveBalance() async {
    final db = await database;

    final result = await db.query(
      'leave_balance_cache',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  // ---------------- LEAVE REQUEST METHODS ----------------

  Future<void> cacheLeaveRequests(
    List<Map<String, dynamic>> requests,
  ) async {
    final db = await database;
    final batch = db.batch();

    batch.delete('leave_requests_cache');

    for (final request in requests) {
      batch.insert(
        'leave_requests_cache',
        request,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedLeaveRequests() async {
    final db = await database;

    return db.query(
      'leave_requests_cache',
      orderBy: 'createdAt DESC',
    );
  }
}
