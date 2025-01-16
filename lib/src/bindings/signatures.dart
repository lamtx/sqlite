// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";

import "package:ffi/ffi.dart";

import "types.dart";

typedef sqlite3_open_v2_native_t = Int32 Function(Pointer<Utf8> filename,
    Pointer<Pointer<Database>> ppDb, Int32 flags, Pointer<Utf8> vfs);

typedef sqlite3_close_v2_native_t = Int32 Function(Pointer<Database> database);

typedef sqlite3_prepare_v2_native_t = Int32 Function(
    Pointer<Database> database,
    Pointer<Utf8> query,
    Int32 nbytes,
    Pointer<Pointer<Statement>> statementOut,
    Pointer<Pointer<Utf8>> tail);

typedef sqlite3_step_native_t = Int32 Function(Pointer<Statement> statement);

typedef sqlite3_reset_native_t = Int32 Function(Pointer<Statement> statement);

typedef sqlite3_finalize_native_t = Int32 Function(
    Pointer<Statement> statement);

typedef sqlite3_errstr_native_t = Pointer<Utf8> Function(Int32 error);

typedef sqlite3_errmsg_native_t = Pointer<Utf8> Function(
    Pointer<Database> database);

typedef sqlite3_column_count_native_t = Int32 Function(
    Pointer<Statement> statement);

typedef sqlite3_column_name_native_t = Pointer<Utf8> Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_decltype_native_t = Pointer<Utf8> Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_type_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_value_native_t = Pointer<Value> Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_double_native_t = Double Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_int_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_int64_native_t = Int64 Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_text_native_t = Pointer<Utf8> Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_blob_native_t = Pointer<Uint8> Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_bind_int_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 argIndex, Int32 value);

typedef sqlite3_bind_int64_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 argIndex, Int64 value);

typedef sqlite3_bind_double_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 argIndex, Double value);

typedef sqlite3_bind_text_native_t = Int32 Function(
    Pointer<Statement> statement,
    Int32 argIndex,
    Pointer<Utf8> value,
    Int32 len,
    Pointer<Void>);

typedef sqlite3_bind_blob_native_t = Int32 Function(
    Pointer<Statement> statement,
    Int32 argIndex,
    Pointer<Uint8> value,
    Int32 len,
    Pointer<Void>);

typedef sqlite3_bind_null_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 argIndex);

typedef sqlite3_last_insert_rowid_native_t = Int64 Function(
    Pointer<Database> statement);

typedef sqlite3_clear_bindings_native_t = Int32 Function(
    Pointer<Statement> statement);

typedef sqlite3_column_bytes_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_exec_native_t = Int32 Function(
    Pointer<Database> sqlite3,
    Pointer<Utf8> sql,
    Pointer<Void> callback,
    Pointer<Void> argToCb,
    Pointer<Pointer<Utf8>> errmsg);
