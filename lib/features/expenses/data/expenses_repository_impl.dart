import 'dart:convert';

import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/write_access_service.dart';
import 'package:controlzukis/features/expenses/domain/models/expense_input.dart';
import 'package:controlzukis/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  ExpensesRepositoryImpl({
    required AppDatabase db,
    required WriteAccessService writeAccess,
  }) : _db = db,
       _writeAccess = writeAccess;

  final AppDatabase _db;
  final WriteAccessService _writeAccess;
  final Uuid _uuid = const Uuid();

  Future<(String tenantId, String branchId, String userId)> _ctx() async {
    final meta = await _db.getAppMeta();
    final tenantId = meta?.currentTenantId;
    final branchId = meta?.currentBranchId;
    final userId = meta?.currentUserId;
    if (tenantId == null || branchId == null || userId == null) {
      throw StateError('Contexto operativo incompleto');
    }
    return (tenantId, branchId, userId);
  }

  @override
  Future<List<Expense>> list({required int limit, required int offset}) async {
    final (tenantId, branchId, _) = await _ctx();
    return (_db.select(_db.expenses)
          ..where(
            (e) => e.tenantId.equals(tenantId) & e.branchId.equals(branchId),
          )
          ..orderBy([(e) => OrderingTerm.desc(e.date)])
          ..limit(limit, offset: offset))
        .get();
  }

  @override
  Future<int> count() async {
    final (tenantId, branchId, _) = await _ctx();
    final countExp = _db.expenses.id.count();
    final query = _db.selectOnly(_db.expenses)..addColumns([countExp]);
    query.where(
      _db.expenses.tenantId.equals(tenantId) &
          _db.expenses.branchId.equals(branchId),
    );
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<List<Product>> listProducts({String? search}) async {
    final (tenantId, branchId, _) = await _ctx();
    final query = _db.select(_db.products)
      ..where(
        (p) =>
            p.tenantId.equals(tenantId) &
            p.branchId.equals(branchId) &
            p.isActive.equals(true),
      )
      ..orderBy([(p) => OrderingTerm.asc(p.name)])
      ..limit(200);

    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      query.where((p) => p.name.like(term) | p.sku.like(term));
    }

    return query.get();
  }

  @override
  Future<void> createExpenseOrPurchase(ExpenseInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    if (input.amount <= 0) {
      throw StateError('El monto debe ser mayor a cero');
    }
    if (input.affectsStock) {
      if (input.productId == null || input.stockQuantity == null) {
        throw StateError(
          'Para compras con stock debe indicar producto y cantidad',
        );
      }
      if (input.stockQuantity! <= 0) {
        throw StateError('La cantidad de stock debe ser mayor a cero');
      }
    }

    final (tenantId, branchId, userId) = await _ctx();

    await _db.transaction(() async {
      await _db
          .into(_db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: _uuid.v4(),
              tenantId: tenantId,
              branchId: branchId,
              category: input.category,
              date: DateTime.now(),
              amount: input.amount,
              affectsStock: Value(input.affectsStock),
              notes: Value(input.notes),
            ),
          );

      if (input.affectsStock) {
        final product =
            await (_db.select(_db.products)
                  ..where((p) => p.id.equals(input.productId!))
                  ..limit(1))
                .getSingleOrNull();
        if (product == null) throw StateError('Producto no encontrado');

        await (_db.update(
          _db.products,
        )..where((p) => p.id.equals(product.id))).write(
          ProductsCompanion(
            stock: Value(product.stock + input.stockQuantity!),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      await _db.writeActivity(
        ActivityLogsCompanion.insert(
          id: _uuid.v4(),
          tenantId: Value(tenantId),
          branchId: Value(branchId),
          userId: Value(userId),
          action: input.affectsStock ? 'PURCHASE_CREATED' : 'EXPENSE_CREATED',
          entityType: 'EXPENSE',
          detailsJson: Value(
            jsonEncode({
              'category': input.category,
              'amount': input.amount,
              'affectsStock': input.affectsStock,
              'productId': input.productId,
              'stockQuantity': input.stockQuantity,
            }),
          ),
        ),
      );
    });
  }
}
