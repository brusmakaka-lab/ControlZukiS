import 'dart:convert';

import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/write_access_service.dart';
import 'package:controlzukis/features/sales/domain/models/create_sale_input.dart';
import 'package:controlzukis/features/sales/domain/repositories/sales_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl({
    required AppDatabase db,
    required WriteAccessService writeAccess,
  }) : _db = db,
       _writeAccess = writeAccess;

  final AppDatabase _db;
  final WriteAccessService _writeAccess;
  final Uuid _uuid = const Uuid();

  Future<
    (String tenantId, String branchId, String userId, bool allowNegativeStock)
  >
  _ctx() async {
    final meta = await _db.getAppMeta();
    final tenantId = meta?.currentTenantId;
    final branchId = meta?.currentBranchId;
    final userId = meta?.currentUserId;
    if (tenantId == null || branchId == null || userId == null) {
      throw StateError('Contexto operativo incompleto');
    }
    return (tenantId, branchId, userId, meta?.allowNegativeStock ?? false);
  }

  @override
  Future<List<Product>> listProducts({String? search}) async {
    final (tenantId, branchId, _, _) = await _ctx();
    final query = _db.select(_db.products)
      ..where(
        (t) =>
            t.tenantId.equals(tenantId) &
            t.branchId.equals(branchId) &
            t.isActive.equals(true),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(200);

    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      query.where((t) => t.name.like(term) | t.sku.like(term));
    }

    return query.get();
  }

  @override
  Future<void> createSaleWithStock(CreateSaleInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    if (input.items.isEmpty) {
      throw StateError('La venta requiere al menos un ítem');
    }

    final (tenantId, branchId, userId, allowNegativeStock) = await _ctx();

    await _db.transaction(() async {
      final saleId = _uuid.v4();
      var subtotal = 0.0;

      final productsById = <String, Product>{};
      for (final item in input.items) {
        final product =
            await (_db.select(_db.products)
                  ..where((p) => p.id.equals(item.productId))
                  ..limit(1))
                .getSingleOrNull();
        if (product == null) {
          throw StateError('Producto inexistente: ${item.productId}');
        }
        if (product.tenantId != tenantId || product.branchId != branchId) {
          throw StateError('Producto fuera de contexto de sucursal');
        }
        if (item.quantity <= 0) {
          throw StateError('Cantidad inválida para ${product.name}');
        }
        if (!allowNegativeStock &&
            product.isInventoriable &&
            !product.isService) {
          if (product.stock < item.quantity) {
            throw StateError('Stock insuficiente para ${product.name}');
          }
        }
        productsById[product.id] = product;
        subtotal += item.quantity * (item.unitPrice ?? product.sellPrice);
      }

      final total = subtotal - input.discount + input.tax;

      await _db
          .into(_db.sales)
          .insert(
            SalesCompanion.insert(
              id: saleId,
              tenantId: tenantId,
              branchId: branchId,
              customerId: Value(input.customerId),
              userId: userId,
              date: DateTime.now(),
              subtotal: subtotal,
              discount: Value(input.discount),
              tax: Value(input.tax),
              total: total,
              notes: Value(input.notes),
            ),
          );

      for (final item in input.items) {
        final product = productsById[item.productId]!;
        final unitPrice = item.unitPrice ?? product.sellPrice;
        final itemSubtotal = unitPrice * item.quantity;

        await _db
            .into(_db.saleItems)
            .insert(
              SaleItemsCompanion.insert(
                id: _uuid.v4(),
                saleId: saleId,
                productId: product.id,
                quantity: item.quantity,
                unitPrice: unitPrice,
                subtotal: itemSubtotal,
              ),
            );

        if (product.isInventoriable && !product.isService) {
          final nowMillis = DateTime.now().millisecondsSinceEpoch;
          final rows = await _db.customUpdate(
            allowNegativeStock
                ? 'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?'
                : 'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ? AND stock >= ?',
            variables: [
              Variable.withReal(item.quantity),
              Variable.withInt(nowMillis),
              Variable.withString(product.id),
              if (!allowNegativeStock) Variable.withReal(item.quantity),
            ],
            updates: {_db.products},
            updateKind: UpdateKind.update,
          );

          if (rows == 0) {
            throw StateError('Stock insuficiente para ${product.name}');
          }
        }
      }

      await _db.writeActivity(
        ActivityLogsCompanion.insert(
          id: _uuid.v4(),
          tenantId: Value(tenantId),
          branchId: Value(branchId),
          userId: Value(userId),
          action: 'SALE_CREATED_WITH_STOCK',
          entityType: 'SALE',
          entityId: Value(saleId),
          detailsJson: Value(
            jsonEncode({
              'subtotal': subtotal,
              'discount': input.discount,
              'tax': input.tax,
              'total': total,
              'items': input.items.length,
            }),
          ),
        ),
      );
    });
  }
}
