// lib/services/anime_database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/anime_item.dart'; // 引入 AnimeItem 模型，請確認路徑正確

// *** 警告：此服務為開發用途，會在資料庫建立時刪除現有表格及其所有資料！ ***
// *** 不適用於需要保留使用者資料的生產環境。 ***

class AnimeDatabaseService {
  // 單例模式
  static final AnimeDatabaseService _instance = AnimeDatabaseService._internal();
  factory AnimeDatabaseService() => _instance;
  AnimeDatabaseService._internal(); // 私有建構子

  static Database? _database;

  static const String _dbName = 'anime_database.db';
  // 在開發階段，如果使用 DROP/CREATE 策略，版本號可以保持固定
  static const int _dbVersion = 1; // 版本號可以保持固定
  static const String _tableName = 'anime_items';

  // **欄位名稱常數，與 AnimeItem 屬性名稱一致**
  // 變數名稱就是屬性名稱，值是資料庫實際欄位名稱的字串
  static const String name = 'name'; // TEXT PRIMARY KEY
  static const String year = 'year'; // INTEGER
  static const String date = 'date'; // TEXT
  static const String time = 'time'; // TEXT
  static const String carrier = 'carrier'; // TEXT
  static const String season = 'season'; // TEXT
  static const String originalName = 'originalName'; // TEXT
  static const String img = 'img'; // TEXT
  static const String description = 'description'; // TEXT
  static const String official = 'official'; // TEXT


  // 取得資料庫實例，如果不存在則開啟並建表 (會執行 DROP TABLE)
  Future<Database> _getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName); // 使用 path 套件的 join

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate, // 首次建立時會呼叫 _onCreate (包含 DROP 語句)
      // 不提供 onUpgrade 和 onDowngrade，因為我們不使用標準的版本遷移
    );

    return _database!;
  }

  // 資料庫建表方法 (包含刪除現有表格的邏輯)
  Future<void> _onCreate(Database db, int version) async {
    // *** 警告：這行會刪除現有的 anime_items 表格及其所有資料！ ***
    await db.execute('DROP TABLE IF EXISTS $_tableName'); // <--- 在建立前刪除表格

    // 建立新的表格 (使用新的常數名稱)
    await db.execute('''
      CREATE TABLE $_tableName (
        $name TEXT PRIMARY KEY, -- 使用 name 常數
        $year INTEGER, -- 使用 year 常數
        $date TEXT, -- 使用 date 常數
        $time TEXT, -- 使用 time 常數
        $carrier TEXT, -- 使用 carrier 常數
        $season TEXT, -- 使用 season 常數
        $originalName TEXT, -- 使用 originalName 常數
        $img TEXT, -- 使用 img 常數
        $description TEXT, -- 使用 description 常數
        $official TEXT -- 使用 official 常數
      )
    ''');
  }

  Future<int> insertAnimeItem(AnimeItem item) async {
    final db = await _getDatabase();
    return await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<AnimeItem?> getAnimeItemByName(String animeName) async { // 參數名稱改為 animeName 避免與欄位常數混淆
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

  Future<List<AnimeItem>> searchAnimeItemsByName(String query) async { // <--- 方法名稱、參數名和回傳型別已修改
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

  Future<int> deleteAnimeItemByName(String animeName) async { // 參數名稱改為 animeName
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
    final db = await _getDatabase();
    if (db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}