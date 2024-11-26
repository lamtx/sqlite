import "dart:io";

import 'package:sqlite/src/sqlite_config.dart';

import 'database.dart';

abstract base class SqliteOpenHelper {
  SqliteOpenHelper(String name,
      this.version, {
        SqliteConfig config = SqliteConfig.builtin,
      }) : _path = _joinPath(config.documentPath, name) {
    _initialize();
  }

  late Database _database;
  final int version;
  final String _path;

  Database get database => _database;

  void _initialize() {
    final file = File(_path);
    final existed = file.existsSync();
    _database = Database(_path);
    if (!existed) {
      onCreate(_database);
      _database.execute("PRAGMA user_version = $version");
    } else {
      final query = _database.query("PRAGMA user_version");
      int theirVersion;
      try {
        if (query.moveNext()) {
          theirVersion = query.current.readColumnByIndexAsInt(0) ?? 0;
        } else {
          theirVersion = 0;
        }
      } finally {
        query.close();
      }
      if (version != theirVersion) {
        if (version > theirVersion) {
          onUpgrade(_database, theirVersion, version);
        } else {
          onDowngrade(_database, theirVersion, version);
        }
        _database.execute("PRAGMA user_version = $version");
      }
    }
  }

  void onCreate(Database db);

  void onUpgrade(Database db, int oldVersion, int newVersion);

  void onDowngrade(Database db, int oldVersion, int newVersion) {
    throw UnsupportedError(
        "Unsupported downgrade database from $newVersion to $oldVersion");
  }

  void close() {
    _database.close();
  }

  Future<void> restore(File databaseFile) async {
    close();
    await databaseFile.copy(_path);
    _initialize();
  }

  File get databaseFile => File(_path);

  static String _joinPath(String? path, String fileName) {
    if (path == null || path.isEmpty) {
      return fileName;
    }
    if (path.endsWith("/")) {
      return path + fileName;
    } else {
      return path + "/" + fileName;
    }
  }
}
