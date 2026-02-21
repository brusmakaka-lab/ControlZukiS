import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/write_access_service.dart';
import 'package:controlzukis/features/categories/domain/models/category_input.dart';
import 'package:controlzukis/features/categories/domain/repositories/categories_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  CategoriesRepositoryImpl({
    required AppDatabase db,
    required WriteAccessService writeAccess,
  }) : _db = db,
       _writeAccess = writeAccess;

  final AppDatabase _db;
  final WriteAccessService _writeAccess;
  final Uuid _uuid = const Uuid();

  Future<(String tenantId, String businessType)> _ctx() async {
    final meta = await _db.getAppMeta();
    final tenantId = meta?.currentTenantId;
    final businessType = meta?.businessType;
    if (tenantId == null || businessType == null) {
      throw StateError('Contexto de tenant/rubro incompleto');
    }
    return (tenantId, businessType);
  }

  @override
  Future<List<Category>> list({
    required int limit,
    required int offset,
    String? search,
  }) async {
    final (tenantId, businessType) = await _ctx();
    final q = _db.select(_db.categories)
      ..where(
        (c) =>
            c.tenantId.equals(tenantId) &
            c.businessType.equals(businessType) &
            c.isActive.equals(true),
      );
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      q.where((c) => c.name.like(term));
    }
    q
      ..orderBy([
        (c) => OrderingTerm.asc(c.sortOrder),
        (c) => OrderingTerm.asc(c.name),
      ])
      ..limit(limit, offset: offset);
    return q.get();
  }

  @override
  Future<int> count({String? search}) async {
    final (tenantId, businessType) = await _ctx();
    final countExp = _db.categories.id.count();
    final q = _db.selectOnly(_db.categories)..addColumns([countExp]);
    q.where(
      _db.categories.tenantId.equals(tenantId) &
          _db.categories.businessType.equals(businessType) &
          _db.categories.isActive.equals(true),
    );
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      q.where(_db.categories.name.like(term));
    }
    final row = await q.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> _ensureUniqueName(
    String tenantId,
    String businessType,
    String name, {
    String? excludingId,
  }) async {
    final normalized = name.trim().toLowerCase();
    final existing =
        await (_db.select(_db.categories)
              ..where(
                (c) =>
                    c.tenantId.equals(tenantId) &
                    c.businessType.equals(businessType) &
                    c.name.lower().equals(normalized) &
                    c.isActive.equals(true),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing != null && existing.id != excludingId) {
      throw StateError('Ya existe una categoría con ese nombre');
    }
  }

  @override
  Future<void> create(CategoryInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final (tenantId, businessType) = await _ctx();
    await _ensureUniqueName(tenantId, businessType, input.name);

    final maxOrder = _db.categories.sortOrder.max();
    final q = _db.selectOnly(_db.categories)
      ..addColumns([maxOrder])
      ..where(
        _db.categories.tenantId.equals(tenantId) &
            _db.categories.businessType.equals(businessType),
      );
    final row = await q.getSingle();
    final nextOrder = (row.read(maxOrder) ?? -1) + 1;

    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: _uuid.v4(),
            tenantId: tenantId,
            name: input.name.trim(),
            businessType: businessType,
            sortOrder: Value(nextOrder),
          ),
        );
  }

  @override
  Future<void> update(String id, CategoryInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final (tenantId, businessType) = await _ctx();
    await _ensureUniqueName(
      tenantId,
      businessType,
      input.name,
      excludingId: id,
    );

    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(name: Value(input.name.trim())),
    );
  }

  @override
  Future<void> delete(String id) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final inUse =
        await (_db.select(_db.products)
              ..where((p) => p.categoryId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    if (inUse != null) {
      throw StateError('No se puede borrar: categoría en uso por productos');
    }

    await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }
}
