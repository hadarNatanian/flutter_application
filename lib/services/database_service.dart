import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post_model.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'bookmarks.db');
    return openDatabase(path, version: 1, onCreate: (db, _) {
      db.execute('''
        CREATE TABLE bookmarks(
          id TEXT PRIMARY KEY,
          userId TEXT,
          userName TEXT,
          title TEXT,
          content TEXT,
          imageUrl TEXT,
          location TEXT,
          createdAt TEXT
        )
      ''');
    });
  }

  static Future<void> insertBookmark(Post post) async {
    final db = await database;
    await db.insert('bookmarks', post.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteBookmark(String id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Post>> getBookmarks() async {
    final db = await database;
    final maps = await db.query('bookmarks');
    return maps.map((m) => Post.fromSqlite(m)).toList();
  }

  static Future<bool> isBookmarked(String id) async {
    final db = await database;
    final result =
        await db.query('bookmarks', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }
}
