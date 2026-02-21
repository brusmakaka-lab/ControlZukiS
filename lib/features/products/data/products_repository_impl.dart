import 'dart:io';
import 'dart:convert';

import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/write_access_service.dart';
import 'package:controlzukis/core/storage/app_paths.dart';
import 'package:controlzukis/features/products/domain/models/product_input.dart';
import 'package:controlzukis/features/products/domain/repositories/products_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl({
    required AppDatabase db,
    required WriteAccessService writeAccess,
  }) : _db = db,
       _writeAccess = writeAccess;

  final AppDatabase _db;
  final WriteAccessService _writeAccess;
  final Uuid _uuid = const Uuid();

  Future<AppMeta> _meta() async {
    final meta = await _db.getAppMeta();
    if (meta == null) {
      throw StateError('Metadatos de aplicación no inicializados');
    }
    return meta;
  }

  Future<(String tenantId, String branchId)> _ctx() async {
    final meta = await _meta();
    final tenantId = meta.currentTenantId;
    final branchId = meta.currentBranchId;
    if (tenantId == null || branchId == null) {
      throw StateError('Contexto de tenant/sucursal no configurado');
    }
    return (tenantId, branchId);
  }

  Future<void> _saveCustomFieldValues({
    required String productId,
    required List<CustomFieldInput> fields,
  }) async {
    await (_db.delete(
      _db.productCustomFieldValues,
    )..where((t) => t.productId.equals(productId))).go();

    for (final field in fields) {
      if (!field.hasAnyValue) continue;
      await _db
          .into(_db.productCustomFieldValues)
          .insert(
            ProductCustomFieldValuesCompanion.insert(
              id: _uuid.v4(),
              productId: productId,
              fieldDefinitionId: field.fieldDefinitionId,
              valueText: Value(field.valueText),
              valueNumber: Value(field.valueNumber),
              valueBool: Value(field.valueBool),
              valueDate: Value(field.valueDate),
              valueJson: Value(field.valueJson),
            ),
          );
    }
  }

  @override
  Future<List<Product>> list({
    required int limit,
    required int offset,
    String? search,
    String? categoryId,
  }) async {
    final (tenantId, branchId) = await _ctx();
    final q = _db.select(_db.products)
      ..where((t) => t.tenantId.equals(tenantId) & t.branchId.equals(branchId));

    if (search != null && search.trim().isNotEmpty) {
      final value = '%${search.trim()}%';
      q.where((t) => t.name.like(value) | t.sku.like(value));
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      q.where((t) => t.categoryId.equals(categoryId));
    }

    q
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit, offset: offset);
    return q.get();
  }

  @override
  Future<int> count({String? search, String? categoryId}) async {
    final (tenantId, branchId) = await _ctx();
    final countExp = _db.products.id.count();
    final q = _db.selectOnly(_db.products)..addColumns([countExp]);
    q.where(
      _db.products.tenantId.equals(tenantId) &
          _db.products.branchId.equals(branchId),
    );

    if (search != null && search.trim().isNotEmpty) {
      final value = '%${search.trim()}%';
      q.where(_db.products.name.like(value) | _db.products.sku.like(value));
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      q.where(_db.products.categoryId.equals(categoryId));
    }

    final row = await q.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<void> create(ProductInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final (tenantId, branchId) = await _ctx();
    final productId = _uuid.v4();
    await _db.transaction(() async {
      await _db
          .into(_db.products)
          .insert(
            ProductsCompanion.insert(
              id: productId,
              tenantId: tenantId,
              branchId: branchId,
              categoryId: Value(input.categoryId),
              sku: Value(input.sku),
              name: input.name,
              description: Value(input.description),
              isService: Value(input.isService),
              isInventoriable: Value(!input.isService),
              stock: Value(input.stock),
              buyPrice: Value(input.buyPrice),
              sellPrice: Value(input.sellPrice),
            ),
          );
      await _saveCustomFieldValues(
        productId: productId,
        fields: input.customFields,
      );
    });
  }

  @override
  Future<void> update(String productId, ProductInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    await _db.transaction(() async {
      await (_db.update(
        _db.products,
      )..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          categoryId: Value(input.categoryId),
          sku: Value(input.sku),
          name: Value(input.name),
          description: Value(input.description),
          isService: Value(input.isService),
          isInventoriable: Value(!input.isService),
          stock: Value(input.stock),
          buyPrice: Value(input.buyPrice),
          sellPrice: Value(input.sellPrice),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _saveCustomFieldValues(
        productId: productId,
        fields: input.customFields,
      );
    });
  }

  @override
  Future<List<ProductCustomFieldDefinition>>
  listCustomFieldDefinitions() async {
    final meta = await _meta();
    final tenantId = meta.currentTenantId;
    final businessType = meta.businessType;
    if (tenantId == null || businessType == null) return const [];

    return (_db.select(_db.productCustomFieldDefinitions)
          ..where(
            (t) =>
                t.tenantId.equals(tenantId) &
                t.businessType.equals(businessType) &
                t.isActive.equals(true),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.order),
            (t) => OrderingTerm.asc(t.label),
          ]))
        .get();
  }

  @override
  Future<List<ProductCustomFieldValue>> listCustomFieldValues(
    String productId,
  ) async {
    return (_db.select(
      _db.productCustomFieldValues,
    )..where((t) => t.productId.equals(productId))).get();
  }

  @override
  Future<void> createCustomFieldDefinition({
    required String key,
    required String label,
    required String type,
    required bool required,
    String? optionsJson,
  }) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final meta = await _meta();
    final tenantId = meta.currentTenantId;
    final businessType = meta.businessType;
    if (tenantId == null || businessType == null) {
      throw StateError('No hay contexto de tenant/rubro para crear campos');
    }

    final maxOrder = _db.productCustomFieldDefinitions.order.max();
    final q = _db.selectOnly(_db.productCustomFieldDefinitions)
      ..addColumns([maxOrder])
      ..where(
        _db.productCustomFieldDefinitions.tenantId.equals(tenantId) &
            _db.productCustomFieldDefinitions.businessType.equals(businessType),
      );
    final row = await q.getSingle();
    final nextOrder = (row.read(maxOrder) ?? -1) + 1;

    String? normalizedOptions = optionsJson;
    if ((type == 'SELECT' || type == 'MULTISELECT') &&
        (normalizedOptions == null || normalizedOptions.trim().isEmpty)) {
      normalizedOptions = jsonEncode(<String>[]);
    }

    await _db
        .into(_db.productCustomFieldDefinitions)
        .insert(
          ProductCustomFieldDefinitionsCompanion.insert(
            id: _uuid.v4(),
            tenantId: tenantId,
            businessType: businessType,
            key: key,
            label: label,
            type: type,
            required: Value(required),
            optionsJson: Value(normalizedOptions),
            order: Value(nextOrder),
          ),
        );
  }

  @override
  Future<void> delete(String productId) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final images = await listImages(productId);

    await _db.transaction(() async {
      await (_db.delete(
        _db.productCustomFieldValues,
      )..where((t) => t.productId.equals(productId))).go();
      await (_db.delete(
        _db.productImages,
      )..where((t) => t.productId.equals(productId))).go();
      await (_db.delete(
        _db.products,
      )..where((t) => t.id.equals(productId))).go();
    });

    for (final image in images) {
      final imageFile = File(image.imagePath);
      if (imageFile.existsSync()) {
        await imageFile.delete();
      }

      final thumbPath = image.thumbnailPath;
      if (thumbPath != null && thumbPath.isNotEmpty) {
        final thumbFile = File(thumbPath);
        if (thumbFile.existsSync()) {
          await thumbFile.delete();
        }
      }
    }
  }

  @override
  Future<List<ProductImage>> listImages(String productId) {
    return (_db.select(_db.productImages)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPrimary),
            (t) => OrderingTerm.asc(t.sortOrder),
          ]))
        .get();
  }

  @override
  Future<void> addImage({
    required String productId,
    required String sourcePath,
  }) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw StateError('Imagen no encontrada');
    }

    final imagesDir = await AppPaths.imagesDir();
    final thumbsDir = await AppPaths.thumbsDir();
    final extension = p.extension(source.path).toLowerCase();
    final safeExt = extension.isEmpty ? '.jpg' : extension;

    final imageName = '${_uuid.v4()}$safeExt';
    final imageTarget = p.join(imagesDir.path, imageName);
    await source.copy(imageTarget);

    final thumbName = 'thumb_${_uuid.v4()}.jpg';
    final thumbTarget = p.join(thumbsDir.path, thumbName);
    try {
      await FlutterImageCompress.compressAndGetFile(
        imageTarget,
        thumbTarget,
        quality: 55,
        minWidth: 420,
        minHeight: 420,
        format: CompressFormat.jpeg,
      );
    } on UnimplementedError {
      // Fallback para plataformas donde flutter_image_compress no está implementado
      // (p.ej., algunos entornos Windows desktop).
      await File(imageTarget).copy(thumbTarget);
    }

    final countExp = _db.productImages.id.count();
    final q = _db.selectOnly(_db.productImages)
      ..addColumns([countExp])
      ..where(_db.productImages.productId.equals(productId));
    final row = await q.getSingle();
    final currentCount = row.read(countExp) ?? 0;

    await _db
        .into(_db.productImages)
        .insert(
          ProductImagesCompanion.insert(
            id: _uuid.v4(),
            productId: productId,
            imagePath: imageTarget,
            thumbnailPath: Value(thumbTarget),
            isPrimary: Value(currentCount == 0),
            sortOrder: Value(currentCount),
          ),
        );
  }

  @override
  Future<void> setPrimaryImage({
    required String productId,
    required String imageId,
  }) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    await (_db.update(_db.productImages)
          ..where((t) => t.productId.equals(productId)))
        .write(const ProductImagesCompanion(isPrimary: Value(false)));

    await (_db.update(_db.productImages)..where((t) => t.id.equals(imageId)))
        .write(const ProductImagesCompanion(isPrimary: Value(true)));
  }

  @override
  Future<void> deleteImage({required String imageId}) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final image = await (_db.select(
      _db.productImages,
    )..where((t) => t.id.equals(imageId))).getSingleOrNull();
    if (image == null) return;

    await (_db.delete(
      _db.productImages,
    )..where((t) => t.id.equals(imageId))).go();

    final imageFile = File(image.imagePath);
    if (imageFile.existsSync()) {
      await imageFile.delete();
    }

    final thumbPath = image.thumbnailPath;
    if (thumbPath != null && thumbPath.isNotEmpty) {
      final thumbFile = File(thumbPath);
      if (thumbFile.existsSync()) {
        await thumbFile.delete();
      }
    }

    final remaining = await listImages(image.productId);
    if (remaining.isNotEmpty && !remaining.any((e) => e.isPrimary)) {
      await setPrimaryImage(
        productId: image.productId,
        imageId: remaining.first.id,
      );
    }
  }
}
