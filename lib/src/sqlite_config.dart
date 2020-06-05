class SqliteConfig {
  const SqliteConfig({this.documentPath});

  final String documentPath;

  static const SqliteConfig builtin = SqliteConfig(
    documentPath: null,
  );
}
