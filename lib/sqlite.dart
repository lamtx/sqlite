// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A synchronous SQLite wrapper.
///
/// Written using dart:ffi.
library sqlite;

export 'src/bindings/constants.dart';
export "src/database.dart" show Database, SQLiteException, Result, Row;
export 'src/ffi/open_dynamic_library.dart';
export 'src/sqlite_config.dart';
export 'src/sqlite_open_helper.dart';
