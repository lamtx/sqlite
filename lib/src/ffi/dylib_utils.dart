// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io' show Platform;

/// Open the embedded library which is provided by
/// [this dependency](https://github.com/lamtx/sqlite3_lib)
DynamicLibrary dlopenPlatformSpecific() {
  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }
  final String name;
  if (Platform.isAndroid) {
    name = "libsqliteX.so";
  } else if (Platform.isWindows) {
    name = "sqlite.dll";
  } else if (Platform.isMacOS) {
    name = "libsqlite.dylib";
  } else if (Platform.isLinux) {
    name = "libsqlite3.so";
  } else {
    throw UnsupportedError(
        "SQLite is not available on ${Platform.operatingSystem}");
  }
  return DynamicLibrary.open(name);
}
