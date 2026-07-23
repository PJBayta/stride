import 'package:drift/drift.dart';

class Settings extends Table {
  TextColumn get settingKey => text().withLength(min: 1, max: 100)();

  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
}
