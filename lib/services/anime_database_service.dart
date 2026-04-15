import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:anime_list/models/anime_item.dart';

/// SQLite 收藏資料庫服務
///
/// 生命週期完全交由 [animeDatabaseServiceProvider]（keepAlive: true）管理，
/// 不再自行維護靜態 Singleton，方便測試時注入 mock 實例。
class AnimeDatabaseService {
  // 使用 Future 快取模式確保 openDatabase 只被呼叫一次。
  // 即使多個協程同時呼叫 _getDatabase()，第一個呼叫會建立 Future 並賦值給
  // _dbFuture，後續呼叫只是 await 同一個 Future，不會重複開啟資料庫。
  Future<Database>? _dbFuture;

  static const String _dbName = 'anime_database.db';

  // v1 → 原始 schema（9 個欄位）
  // v2 → 新增 pv TEXT 欄位
  static const int _dbVersion = 2;
  static const String _tableName = 'anime_items';

  static const String name = 'name'; // TEXT PRIMARY KEY
  static const String date = 'date'; // TEXT
  static const String time = 'time'; // TEXT
  static const String carrier = 'carrier'; // TEXT
  static const String season = 'season'; // TEXT
  static const String originalName = 'originalName'; // TEXT
  static const String img = 'img'; // TEXT
  static const String description = 'description'; // TEXT
  static const String official = 'official'; // TEXT
  static const String pv = 'pv'; // TEXT NULLABLE

  /// 取得資料庫實例，如果不存在則開啟並建表。
  ///
  /// 透過快取 [_dbFuture] 確保 [openDatabase] 只被呼叫一次。
  /// 即使多個非同步呼叫同時進入此方法，也只有第一個呼叫會觸發 openDatabase，
  /// 其餘呼叫等待同一個 Future 完成，不會產生重複初始化的競態條件。
  Future<Database> _getDatabase() {
    _dbFuture ??= _openDatabase();
    return _dbFuture!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 首次安裝時建表（包含全部欄位）
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $name TEXT PRIMARY KEY,
        $date TEXT,
        $time TEXT,
        $carrier TEXT,
        $season TEXT,
        $originalName TEXT,
        $img TEXT,
        $description TEXT,
        $official TEXT,
        $pv TEXT
      )
    ''');
  }

  /// 資料庫升版遷移
  ///
  /// v1 → v2：新增 pv 欄位（nullable，預設 NULL）
  /// 舊手機升級 App 後會走此路徑，不影響既有收藏資料。
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_tableName ADD COLUMN $pv TEXT');
    }
  }

  Future<int> insertAnimeItem(AnimeItem item) async {
    final db = await _getDatabase();
    return await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<AnimeItem?> getAnimeItemByName(String animeName) async {
    // 參數名稱改為 animeName 避免與欄位常數混淆
    final db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$name = ?', // 使用 name 常數
      whereArgs: [animeName], // 使用傳入的參數
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AnimeItem.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<AnimeItem>> getAllAnimeItems() async {
    final db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return AnimeItem.fromMap(maps[i]);
    });
  }

  Future<List<AnimeItem>> searchAnimeItemsByName(String query) async {
    // <--- 方法名稱、參數名和回傳型別已修改
    final db = await _getDatabase();

    // 查詢表格，使用 LIKE 進行模糊查詢
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$name LIKE ?', // <--- 使用 LIKE 進行模糊比對
      whereArgs: ['%$query%'], // <--- 查詢參數，前後加上 % 符號表示匹配任意位置的字元
      // 移除 limit: 1，以查詢多筆結果
    );

    // 將查詢結果 (List<Map>) 轉換為 List<AnimeItem>
    // List.generate 在 maps 為空時會自動回傳空列表
    return List.generate(maps.length, (i) {
      return AnimeItem.fromMap(maps[i]); // <--- 使用 fromMap()
    });
  }

  Future<int> deleteAnimeItemByName(String animeName) async {
    // 參數名稱改為 animeName
    final db = await _getDatabase();
    return await db.delete(
      _tableName,
      where: '$name = ?', // 使用 name 常數
      whereArgs: [animeName], // 使用傳入的參數
    );
  }

  Future<int> clearAllAnimeItems() async {
    final db = await _getDatabase();
    final int rowsAffected = await db.delete(_tableName);

    return rowsAffected;
  }

  Future<void> close() async {
    if (_dbFuture == null) return;
    final db = await _dbFuture!;
    if (db.isOpen) {
      await db.close();
    }
    _dbFuture = null;
  }
}
