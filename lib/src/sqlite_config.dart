final class SqliteConfig {
  const SqliteConfig({this.documentPath});

  final String? documentPath;

  static const builtin = SqliteConfig();
}
