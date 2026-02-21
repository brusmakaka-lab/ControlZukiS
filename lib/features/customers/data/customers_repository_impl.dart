import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/write_access_service.dart';
import 'package:controlzukis/features/customers/domain/models/customer_input.dart';
import 'package:controlzukis/features/customers/domain/repositories/customers_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  CustomersRepositoryImpl({
    required AppDatabase db,
    required WriteAccessService writeAccess,
  }) : _db = db,
       _writeAccess = writeAccess;

  final AppDatabase _db;
  final WriteAccessService _writeAccess;
  final Uuid _uuid = const Uuid();

  Future<String> _tenantId() async {
    final meta = await _db.getAppMeta();
    final tenantId = meta?.currentTenantId;
    if (tenantId == null) throw StateError('Tenant no configurado');
    return tenantId;
  }

  @override
  Future<List<Customer>> list({
    required int limit,
    required int offset,
    String? search,
  }) async {
    final tenantId = await _tenantId();
    final q = _db.select(_db.customers)
      ..where((c) => c.tenantId.equals(tenantId));

    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      q.where((c) => c.fullName.like(term) | c.dniCuit.like(term));
    }

    q
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
      ..limit(limit, offset: offset);

    return q.get();
  }

  @override
  Future<int> count({String? search}) async {
    final tenantId = await _tenantId();
    final countExp = _db.customers.id.count();
    final q = _db.selectOnly(_db.customers)..addColumns([countExp]);
    q.where(_db.customers.tenantId.equals(tenantId));

    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      q.where(
        _db.customers.fullName.like(term) | _db.customers.dniCuit.like(term),
      );
    }

    final row = await q.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<void> create(CustomerInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final tenantId = await _tenantId();
    await _db
        .into(_db.customers)
        .insert(
          CustomersCompanion.insert(
            id: _uuid.v4(),
            tenantId: tenantId,
            fullName: input.fullName,
            dniCuit: Value(input.dniCuit),
            email: Value(input.email),
            phone: Value(input.phone),
            address: Value(input.address),
          ),
        );
  }

  @override
  Future<void> update(String customerId, CustomerInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    await (_db.update(
      _db.customers,
    )..where((c) => c.id.equals(customerId))).write(
      CustomersCompanion(
        fullName: Value(input.fullName),
        dniCuit: Value(input.dniCuit),
        email: Value(input.email),
        phone: Value(input.phone),
        address: Value(input.address),
      ),
    );
  }

  @override
  Future<void> delete(String customerId) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    await (_db.delete(
      _db.customers,
    )..where((c) => c.id.equals(customerId))).go();
  }
}
