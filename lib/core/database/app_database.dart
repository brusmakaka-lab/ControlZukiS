import 'package:controlzukis/core/storage/app_paths.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class AppMetas extends Table {
  TextColumn get id => text()();
  DateTimeColumn get installedAt => dateTime()();
  DateTimeColumn get trialEndsAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();
  TextColumn get licenseStatus => text()();
  BoolColumn get demoMode => boolean().withDefault(const Constant(false))();
  TextColumn get currentTenantId => text().nullable()();
  TextColumn get currentBranchId => text().nullable()();
  TextColumn get currentUserId => text().nullable()();
  BoolColumn get sessionActive =>
      boolean().withDefault(const Constant(false))();
  TextColumn get businessType => text().nullable()();
  BoolColumn get maintenanceMode =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get allowNegativeStock =>
      boolean().withDefault(const Constant(false))();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tenants extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get legalName => text().nullable()();
  TextColumn get taxId => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Branches extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get branchId => text().references(Branches, #id)();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get role => text()();
  TextColumn get passwordHash => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get name => text()();
  TextColumn get businessType => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get branchId => text().references(Branches, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get sku => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isService => boolean().withDefault(const Constant(false))();
  BoolColumn get isInventoriable =>
      boolean().withDefault(const Constant(true))();
  RealColumn get stock => real().withDefault(const Constant(0.0))();
  RealColumn get minStock => real().withDefault(const Constant(0.0))();
  RealColumn get buyPrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProductImages extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get imagePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProductCustomFieldDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get businessType => text()();
  TextColumn get key => text()();
  TextColumn get label => text()();
  TextColumn get type => text()();
  BoolColumn get required => boolean().withDefault(const Constant(false))();
  TextColumn get optionsJson => text().nullable()();
  IntColumn get order => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProductCustomFieldValues extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get fieldDefinitionId =>
      text().references(ProductCustomFieldDefinitions, #id)();
  TextColumn get valueText => text().nullable()();
  RealColumn get valueNumber => real().nullable()();
  BoolColumn get valueBool => boolean().nullable()();
  DateTimeColumn get valueDate => dateTime().nullable()();
  TextColumn get valueJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get fullName => text()();
  TextColumn get dniCuit => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get branchId => text().references(Branches, #id)();
  TextColumn get customerId => text().nullable().references(Customers, #id)();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get total => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get subtotal => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get branchId => text().references(Branches, #id)();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();
  BoolColumn get affectsStock => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ActivityLogs extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().nullable()();
  TextColumn get branchId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get detailsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LicenseAudits extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().nullable()();
  TextColumn get deviceId => text()();
  TextColumn get action => text()();
  TextColumn get statusBefore => text().nullable()();
  TextColumn get statusAfter => text().nullable()();
  TextColumn get keyMasked => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await AppPaths.databaseFile();
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    AppMetas,
    Tenants,
    Branches,
    Users,
    Categories,
    Products,
    ProductImages,
    ProductCustomFieldDefinitions,
    ProductCustomFieldValues,
    Customers,
    Sales,
    SaleItems,
    Expenses,
    ActivityLogs,
    LicenseAudits,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      await _preMigrationBackup(from, to);
      if (from < 2) {
        await m.addColumn(appMetas, appMetas.sessionActive);
        await m.addColumn(appMetas, appMetas.maintenanceMode);
      }
      await _createIndexes();
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_name ON products (name);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_sku ON products (sku);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_category_id ON products (category_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_date ON sales (date);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items (sale_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses (date);',
    );
  }

  Future<void> _preMigrationBackup(int from, int to) async {
    final source = await AppPaths.databaseFile();
    if (!source.existsSync()) {
      return;
    }

    final backupName =
        'pre_migration_v${from}_to_v${to}_${DateTime.now().millisecondsSinceEpoch}.sqlite';
    final backupPath = p.join(source.parent.path, backupName);
    await source.copy(backupPath);
  }

  Future<AppMeta?> getAppMeta() async {
    return (select(appMetas)..limit(1)).getSingleOrNull();
  }

  Future<void> upsertAppMeta(AppMetasCompanion value) async {
    await into(appMetas).insertOnConflictUpdate(value);
  }

  Future<List<Category>> getCategoriesByBusinessType(
    String tenantId,
    String businessType,
  ) {
    return (select(categories)
          ..where(
            (t) =>
                t.tenantId.equals(tenantId) &
                t.businessType.equals(businessType) &
                t.isActive.equals(true),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  Future<void> writeActivity(ActivityLogsCompanion log) async {
    await into(activityLogs).insert(log);
  }

  Future<void> writeLicenseAudit(LicenseAuditsCompanion audit) async {
    await into(licenseAudits).insert(audit);
  }
}
