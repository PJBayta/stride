import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row =
        await (select(settings)..where((t) => t.settingKey.equals(key)))
            .getSingleOrNull();
    return row?.settingValue;
  }

  Future<void> setValue(String key, String value) {
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(settingKey: key, settingValue: value),
    );
  }

  Stream<String?> watchValue(String key) {
    return (select(settings)..where((t) => t.settingKey.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.settingValue);
  }
}
