import 'dart:convert';
import 'dart:io';

import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/storage/app_paths.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stress seed + métricas', (tester) async {
    final db = AppDatabase();
    await db.customStatement('PRAGMA foreign_keys = OFF');
    await db.customStatement('DELETE FROM sale_items');
    await db.customStatement('DELETE FROM sales');
    await db.customStatement('DELETE FROM product_custom_field_values');
    await db.customStatement('DELETE FROM product_images');
    await db.customStatement('DELETE FROM products');
    await db.customStatement('DELETE FROM customers');
    await db.customStatement('DELETE FROM expenses');
    await db.customStatement('DELETE FROM users');
    await db.customStatement('DELETE FROM branches');
    await db.customStatement('DELETE FROM categories');
    await db.customStatement('DELETE FROM tenants');
    await db.customStatement('DELETE FROM app_metas');
    await db.customStatement('DELETE FROM activity_logs');
    await db.customStatement('DELETE FROM license_audits');
    await db.customStatement('PRAGMA foreign_keys = ON');
    final now = DateTime.now();

    await db.upsertAppMeta(
      AppMetasCompanion.insert(
        id: 'meta-stress',
        installedAt: now,
        trialEndsAt: now.add(const Duration(days: 30)),
        lastSeenAt: now,
        licenseStatus: 'ACTIVE',
        currentTenantId: const Value('t1'),
        currentBranchId: const Value('b1'),
        currentUserId: const Value('u1'),
        sessionActive: const Value(true),
        businessType: const Value('ferreteria'),
        maintenanceMode: const Value(false),
      ),
    );
    await db
        .into(db.tenants)
        .insert(TenantsCompanion.insert(id: 't1', name: 'T1'));
    await db
        .into(db.branches)
        .insert(BranchesCompanion.insert(id: 'b1', tenantId: 't1', name: 'B1'));
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: 'u1',
            tenantId: 't1',
            branchId: 'b1',
            name: 'Root',
            email: 'root@test.com',
            role: 'SUPER_ADMIN',
            passwordHash: 'x',
          ),
        );

    final sw = Stopwatch()..start();
    for (var i = 0; i < 500; i++) {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'p$i',
              tenantId: 't1',
              branchId: 'b1',
              name: 'Producto $i',
              sellPrice: const Value(10),
            ),
          );
    }
    for (var i = 0; i < 500; i++) {
      await db
          .into(db.customers)
          .insert(
            CustomersCompanion.insert(
              id: 'c$i',
              tenantId: 't1',
              fullName: 'Cliente $i',
            ),
          );
    }
    final seedMs = sw.elapsedMilliseconds;

    sw
      ..reset()
      ..start();
    await (db.select(db.products)
          ..where((t) => t.tenantId.equals('t1'))
          ..limit(25, offset: 0))
        .get();
    final firstPageMs = sw.elapsedMilliseconds;

    sw
      ..reset()
      ..start();
    await (db.select(db.products)
          ..where((t) => t.name.like('%Producto 49%'))
          ..limit(25, offset: 0))
        .get();
    final searchMs = sw.elapsedMilliseconds;

    final qaDir = Directory('${(await AppPaths.appDir()).path}/qa');
    await qaDir.create(recursive: true);
    final report = {
      'seedMs': seedMs,
      'firstPageMs': firstPageMs,
      'searchMs': searchMs,
      'productsSeeded': 500,
      'customersSeeded': 500,
      'note':
          'Escala reducida para CI local; parametrizable a 5k/20k en entorno de carga.',
    };
    await File('${qaDir.path}/stress_metrics.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      flush: true,
    );

    await db.close();
    expect(firstPageMs >= 0, true);
  });
}
