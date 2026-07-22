import 'package:drift/drift.dart';

/// A single key/value application setting (theme, units, GPS accuracy, ...).
///
/// Mirrors the `Settings` entity in `docs/database.md`. Stored as a flat
/// key/value pair rather than one column per setting so new settings don't
/// require schema migrations.
class Settings extends Table {
  TextColumn get settingKey => text().withLength(min: 1, max: 100)();

  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
}
