// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";
import 'dart:typed_data';

import "package:ffi/ffi.dart";

import "bindings/bindings.dart";
import "bindings/constants.dart";
import "bindings/types.dart" as types;
import "bindings/types.dart" hide Database;

/// [Database] represents an open connection to a SQLite database.
///
/// All functions against a database may throw [SQLiteError].
///
/// This database interacts with SQLite synchonously.
final class Database {
  late Pointer<types.Database> _database;
  bool _open = false;

  /// Open a database located at the file [path].
  Database(String path,
      [int flags = Flags.SQLITE_OPEN_READWRITE | Flags.SQLITE_OPEN_CREATE]) {
    Pointer<Pointer<types.Database>> dbOut = calloc();
    final pathC = path.toNativeUtf8();
    final int resultCode =
        bindings.sqlite3_open_v2(pathC, dbOut, flags, nullptr);
    _database = dbOut.value;
    calloc.free(dbOut);
    calloc.free(pathC);

    if (resultCode == Errors.SQLITE_OK) {
      _open = true;
    } else {
      // Even if "open" fails, sqlite3 will still create a database object. We
      // can just destroy it.
      SQLiteException exception = _loadError(resultCode);
      bindings.sqlite3_close_v2(_database);
      throw exception;
    }
  }

  /// Close the database.
  ///
  /// This should only be called once on a database unless an exception is
  /// thrown. It should be called at least once to finalize the database and
  /// avoid resource leaks.
  void close() {
    assert(_open);
    final int resultCode = bindings.sqlite3_close_v2(_database);
    if (resultCode == Errors.SQLITE_OK) {
      _open = false;
    } else {
      throw _loadError(resultCode);
    }
  }

  Pointer<Statement> prepare(String statement) {
    Pointer<Pointer<Statement>> statementOut = calloc();
    Pointer<Utf8> queryC = statement.toNativeUtf8();
    int resultCode = bindings.sqlite3_prepare_v2(
        _database, queryC, -1, statementOut, nullptr);
    calloc.free(queryC);

    if (resultCode != Errors.SQLITE_OK) {
      final e = _loadError(resultCode);
      calloc.free(statementOut);
      calloc.free(queryC);
      throw e;
    }
    return statementOut.value;
  }

  void freeStatement(Pointer<Statement> statement) {
    bindings.sqlite3_finalize(statement);
    calloc.free(statement);
  }

  int executeStatement(Pointer<Statement> statement,
      [List<Object?>? args, bool returnsRowId = false]) {
    final allocatedObjects = args == null ? null : _bindArgs(statement, args);

    int resultCode;
    do {
      resultCode = bindings.sqlite3_step(statement);
    } while (resultCode == Errors.SQLITE_ROW || resultCode == Errors.SQLITE_OK);

    final insertedRowId =
        returnsRowId ? bindings.sqlite3_last_insert_rowid(_database) : 0;

    if (allocatedObjects != null) {
      _freeArgs(statement, allocatedObjects);
    }

    if (resultCode != Errors.SQLITE_DONE) {
      throw _loadError(resultCode);
    }
    return insertedRowId;
  }

  /// Execute a query, discarding any returned rows.
  int execute(String query, [List<Object?>? args, bool returnsRowId = false]) {
    final statement = prepare(query);
    final allocatedObjects = args == null ? null : _bindArgs(statement, args);

    int resultCode;
    do {
      resultCode = bindings.sqlite3_step(statement);
    } while (resultCode == Errors.SQLITE_ROW || resultCode == Errors.SQLITE_OK);

    final insertedRowId =
        returnsRowId ? bindings.sqlite3_last_insert_rowid(_database) : 0;

    if (allocatedObjects != null) {
      _freeArgs(statement, allocatedObjects);
    }
    freeStatement(statement);

    if (resultCode != Errors.SQLITE_DONE) {
      throw _loadError(resultCode);
    }
    return insertedRowId;
  }

  List<Pointer<NativeType>> _bindArgs(
    Pointer<types.Statement> statement,
    List<Object?> args,
  ) {
    final allocatedObjects = <Pointer>[];
    var i = 0;
    for (final arg in args) {
      i += 1;
      if (arg == null) {
        bindings.sqlite3_bind_null(statement, i);
      } else if (arg is int) {
        bindings.sqlite3_bind_int64(statement, i, arg);
      } else if (arg is double) {
        bindings.sqlite3_bind_double(statement, i, arg);
      } else if (arg is String) {
        final s = arg.toNativeUtf8();
        allocatedObjects.add(s);
        bindings.sqlite3_bind_text(statement, i, s, -1, nullptr);
      } else if (arg is Uint8List) {
        Pointer<Uint8> str = calloc.allocate<Uint8>(arg.length);
        final Uint8List nativeString = str.asTypedList(arg.length);
        nativeString.setAll(0, arg);
        allocatedObjects.add(str);
        bindings.sqlite3_bind_blob(statement, i, str, arg.length, nullptr);
      } else {
        throw UnsupportedError(
            "Unsupported type ${arg.runtimeType} to insert to Sqlite");
      }
    }
    return allocatedObjects;
  }

  void _freeArgs(Pointer<Statement> statement, List<Pointer<NativeType>> args) {
    if (args.isNotEmpty) {
      bindings.sqlite3_clear_bindings(statement);
    }
    for (final object in args) {
      calloc.free(object);
    }
  }

  /// Evaluate a query and return the resulting rows as an iterable.
  Result query(String query, [List<Object?>? args]) {
    final statement = prepare(query);

    final allocatedObjects = args == null ? null : _bindArgs(statement, args);

    freeStatement(statement);

    Map<String, int> columnIndices = {};
    int columnCount = bindings.sqlite3_column_count(statement);
    for (int i = 0; i < columnCount; i++) {
      String columnName =
          bindings.sqlite3_column_name(statement, i).toDartString();
      columnIndices[columnName] = i;
    }

    return Result._(statement, columnIndices, allocatedObjects);
  }

  SQLiteException _loadError([int? errorCode]) {
    String errorMessage = bindings.sqlite3_errmsg(_database).toDartString();
    if (errorCode == null) {
      return SQLiteException(errorMessage);
    }
    String errorCodeExplanation =
        bindings.sqlite3_errstr(errorCode).toDartString();
    return SQLiteException(
        "$errorMessage (Code $errorCode: $errorCodeExplanation)");
  }
}

/// [Result] represents a [Database.query]'s result and provides an [Iterable]
/// interface for the results to be consumed.
///
/// Please note that this iterator should be [close]d manually if not all [Row]s
/// are consumed.
final class Result {
  final _ResultIterator _iterator;

  Result._(Pointer<Statement> _statement, Map<String, int> _columnIndices,
      List<Pointer<NativeType>>? boundArgs)
      : _iterator = _ResultIterator(_statement, _columnIndices, boundArgs) {}

  void close() => _iterator.close();

  bool moveNext() => _iterator.moveNext();

  Row get current => _iterator.current;
}

final class _ResultIterator {
  final Pointer<Statement> _statement;
  final Map<String, int> _columnIndices;
  final List<Pointer<NativeType>>? _boundArgs;
  Row? _currentRow = null;
  bool _closed = false;

  _ResultIterator(this._statement, this._columnIndices, this._boundArgs) {}

  bool moveNext() {
    if (_closed) {
      throw SQLiteException("The result has already been closed.");
    }
    _currentRow?._setNotCurrent();
    int stepResult = bindings.sqlite3_step(_statement);
    if (stepResult == Errors.SQLITE_ROW) {
      _currentRow = Row._(_statement, _columnIndices);
      return true;
    } else {
      return false;
    }
  }

  Row get current {
    if (_closed) {
      throw SQLiteException("The result has already been closed.");
    }
    return _currentRow ?? (throw StateError("No elements"));
  }

  void close() {
    _currentRow?._setNotCurrent();
    _closed = true;
    bindings.sqlite3_finalize(_statement);
    if (_boundArgs != null) {
      for (final arg in _boundArgs) {
        calloc.free(arg);
      }
    }
  }
}

final class Row {
  final Pointer<Statement> _statement;
  final Map<String, int> _columnIndices;

  bool _isCurrentRow = true;

  Row._(this._statement, this._columnIndices) {}

  /// Get column index by name
  int? getColumnIndex(String columnName) => _columnIndices[columnName];

  /// Reads column [columnIndex] and converts to [Type.Integer] if not an
  /// integer.
  int? readColumnByIndexAsInt(int columnIndex) {
    _checkIsCurrentRow();
    final value = bindings.sqlite3_column_int64(_statement, columnIndex);
    if (value == 0 && _checkIsNull(columnIndex)) {
      return null;
    }
    return value;
  }

  /// Reads column [columnIndex] and converts to [Type.Float] if not an
  /// integer.
  double? readColumnByIndexAsDouble(int columnIndex) {
    _checkIsCurrentRow();
    final value = bindings.sqlite3_column_double(_statement, columnIndex);
    if (value == 0.0 && _checkIsNull(columnIndex)) {
      return null;
    }
    return value;
  }

  /// Reads column [columnIndex] and converts to [Type.Text] if not text.
  String? readColumnByIndexAsText(int columnIndex) {
    _checkIsCurrentRow();
    final str = bindings.sqlite3_column_text(_statement, columnIndex);
    if (str == nullptr) {
      return null;
    }
    return str.toDartString();
  }

  /// Reads column [columnIndex] and converts to [Type.Text] if not text.
  Uint8List? readColumnByIndexAsBlob(int columnIndex) {
    _checkIsCurrentRow();
    final pointer = bindings.sqlite3_column_blob(_statement, columnIndex);
    if (pointer == nullptr) {
      return null;
    }
    final len = bindings.sqlite3_column_bytes(_statement, columnIndex);
    final result = pointer.asTypedList(len);
    return Uint8List.fromList(result);
  }

  void _checkIsCurrentRow() {
    if (!_isCurrentRow) {
      throw SQLiteException(
          "This row is not the current row, reading data from the non-current"
          " row is not supported by sqlite.");
    }
  }

  void _setNotCurrent() {
    _isCurrentRow = false;
  }

  bool _checkIsNull(int columnIndex) {
    return bindings.sqlite3_column_type(_statement, columnIndex) == Type.Null;
  }
}

abstract final class Type {
  static const Integer = 1;
  static const Float = 2;
  static const Text = 3;
  static const Blob = 4;
  static const Null = 5;
}

enum Convert { DynamicType, StaticType }

final class SQLiteException implements Exception {
  final String message;

  SQLiteException(this.message);

  String toString() => message;
}

final class PreparedStatement {}
