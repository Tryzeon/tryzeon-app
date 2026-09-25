import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/services/local_database.dart';

class LocalDatabaseImpl implements LocalDatabase {
  LocalDatabaseImpl(this._isarService);
  final IsarService _isarService;

  @override
  Future<void> clear() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
