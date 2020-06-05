import "dart:io";

import 'package:sqlite/src/sqlite_config.dart';

import 'database.dart';

abstract class SqliteOpenHelper {
  SqliteOpenHelper(
    String name,
    this.version, {
    SqliteConfig config = SqliteConfig.builtin,
  }) {
    final path = _joinPath(config.documentPath, name);
    final file = File(path);
    final existed = file.existsSync();
    _database = Database(path);
    if (!existed) {
      onCreate(_database);
      _database.execute("PRAGMA user_version = $version");
    } else {
      final query = _database.query("PRAGMA user_version");
      int theirVersion;
      try {
        if (query.moveNext()) {
          theirVersion = query.current.readColumnByIndexAsInt(0);
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

  Database _database;
  final int version;

  Database get database => _database;

  void onCreate(Database db);

  void onUpgrade(Database db, int oldVersion, int newVersion);

  void onDowngrade(Database db, int oldVersion, int newVersion) {
    throw UnsupportedError(
        "Unsupported downgrade database from $newVersion to $oldVersion");
  }

  static String _joinPath(String path, String fileName) {
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
