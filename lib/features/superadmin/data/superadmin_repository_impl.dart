import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:controlzukis/core/config/app_env.dart';
import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/role_guard.dart';
import 'package:controlzukis/core/logging/app_logger.dart';
import 'package:controlzukis/core/models/license_status.dart';
import 'package:controlzukis/core/services/device_service.dart';
import 'package:controlzukis/core/storage/app_paths.dart';
import 'package:controlzukis/features/superadmin/domain/models/backup_info.dart';
import 'package:controlzukis/features/superadmin/domain/models/superadmin_diagnostics.dart';
import 'package:controlzukis/features/superadmin/domain/models/superadmin_state_snapshot.dart';
import 'package:controlzukis/features/superadmin/domain/repositories/superadmin_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class SuperAdminRepositoryImpl implements SuperAdminRepository {
  SuperAdminRepositoryImpl({
    required AppDatabase db,
    required RoleGuard roleGuard,
    required DeviceService deviceService,
  }) : _db = db,
       _roleGuard = roleGuard,
       _deviceService = deviceService;

  final AppDatabase _db;
  final RoleGuard _roleGuard;
  final DeviceService _deviceService;
  final Uuid _uuid = const Uuid();

  Future<void> _ensureSuperAdmin() async {
    final guard = await _roleGuard.canWrite(
      allowedRoles: const ['SUPER_ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);
  }

  Future<AppMeta> _meta() async {
    final meta = await _db.getAppMeta();
    if (meta == null) throw StateError('App meta no inicializada');
    return meta;
  }

  @override
  Future<SuperAdminStateSnapshot> getSnapshot() async {
    await _ensureSuperAdmin();

    final logs =
        await (_db.select(_db.activityLogs)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(200))
            .get();
    final audits =
        await (_db.select(_db.licenseAudits)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(200))
            .get();

    final appDir = await AppPaths.appDir();
    final dbFile = await AppPaths.databaseFile();
    final logsFile = await AppPaths.logsFile();
    final imagesDir = await AppPaths.imagesDir();
    final thumbsDir = await AppPaths.thumbsDir();

    final diagnostics = SuperAdminDiagnostics(
      appDirPath: appDir.path,
      dbPath: dbFile.path,
      dbSizeBytes: dbFile.existsSync() ? dbFile.lengthSync() : 0,
      logsPath: logsFile.path,
      logsSizeBytes: logsFile.existsSync() ? logsFile.lengthSync() : 0,
      imagesCount: _fileCount(imagesDir),
      thumbsCount: _fileCount(thumbsDir),
      now: DateTime.now(),
    );

    return SuperAdminStateSnapshot(
      logs: logs,
      licenseAudits: audits,
      diagnostics: diagnostics,
    );
  }

  @override
  Future<String> exportLogs() async {
    await _ensureSuperAdmin();

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar logs',
      fileName:
          'controlzukis_logs_${DateTime.now().millisecondsSinceEpoch}.jsonl',
    );
    if (savePath == null) {
      throw StateError('Exportación cancelada');
    }

    final target = File(savePath);
    await target.parent.create(recursive: true);
    await AppLogger.exportLogsTo(target);
    return target.path;
  }

  @override
  Future<void> resetDemo() async {
    await _ensureSuperAdmin();
    final meta = await _meta();
    final now = DateTime.now();
    final trialEndsAt = now.add(const Duration(days: AppEnv.trialDays));

    await _db.transaction(() async {
      await _db.delete(_db.saleItems).go();
      await _db.delete(_db.sales).go();
      await _db.delete(_db.expenses).go();
      await _db.delete(_db.customers).go();
      await _db.delete(_db.activityLogs).go();

      await _db.upsertAppMeta(
        AppMetasCompanion(
          id: Value(meta.id),
          installedAt: Value(meta.installedAt),
          trialEndsAt: Value(trialEndsAt),
          lastSeenAt: Value(now),
          licenseStatus: Value(LicenseStatus.trial.dbValue),
          demoMode: const Value(true),
          currentTenantId: Value(meta.currentTenantId),
          currentBranchId: Value(meta.currentBranchId),
          currentUserId: Value(meta.currentUserId),
          sessionActive: Value(meta.sessionActive),
          businessType: Value(meta.businessType),
          maintenanceMode: Value(meta.maintenanceMode),
          allowNegativeStock: Value(meta.allowNegativeStock),
          schemaVersion: Value(meta.schemaVersion),
          createdAt: Value(meta.createdAt),
          updatedAt: Value(now),
        ),
      );

      final deviceId = await _deviceService.getDeviceId();
      await _db.writeLicenseAudit(
        LicenseAuditsCompanion.insert(
          id: _uuid.v4(),
          tenantId: Value(meta.currentTenantId),
          deviceId: deviceId,
          action: 'RESET_DEMO',
          statusBefore: Value(meta.licenseStatus),
          statusAfter: Value(LicenseStatus.trial.dbValue),
          payloadJson: Value(
            '{"trialEndsAt":"${trialEndsAt.toIso8601String()}"}',
          ),
        ),
      );
    });

    final imagesDir = await AppPaths.imagesDir();
    final thumbsDir = await AppPaths.thumbsDir();
    await _deleteChildren(imagesDir);
    await _deleteChildren(thumbsDir);
  }

  @override
  Future<BackupInfo> createBackupZip() async {
    await _ensureSuperAdmin();

    final backupsDir = await AppPaths.backupsDir();
    final dbFile = await AppPaths.databaseFile();
    final logsFile = await AppPaths.logsFile();
    final imagesDir = await AppPaths.imagesDir();
    final thumbsDir = await AppPaths.thumbsDir();

    final createdAt = DateTime.now();
    final archive = Archive();

    if (dbFile.existsSync()) {
      final bytes = await dbFile.readAsBytes();
      archive.addFile(
        ArchiveFile('db/${p.basename(dbFile.path)}', bytes.length, bytes),
      );
    }

    if (logsFile.existsSync()) {
      final bytes = await logsFile.readAsBytes();
      archive.addFile(
        ArchiveFile('logs/${p.basename(logsFile.path)}', bytes.length, bytes),
      );
    }

    await _appendDirectoryToArchive(
      archive: archive,
      dir: imagesDir,
      zipPrefix: 'images',
    );
    await _appendDirectoryToArchive(
      archive: archive,
      dir: thumbsDir,
      zipPrefix: 'thumbnails',
    );

    final contentSha256 = await _computeContentSha256(
      dbFile: dbFile,
      logsFile: logsFile,
      imagesDir: imagesDir,
      thumbsDir: thumbsDir,
    );

    final metadata = {
      'app': 'ControlZukiS',
      'createdAt': createdAt.toIso8601String(),
      'dbFile': p.basename(dbFile.path),
      'logsFile': p.basename(logsFile.path),
      'contentSha256': contentSha256,
      'formatVersion': 1,
    };
    final metadataBytes = utf8.encode(jsonEncode(metadata));
    archive.addFile(
      ArchiveFile('metadata.json', metadataBytes.length, metadataBytes),
    );

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw StateError('No se pudo generar ZIP de backup');
    final zipSha256 = sha256.convert(zipBytes).toString();

    final file = File(
      p.join(
        backupsDir.path,
        'backup_${createdAt.millisecondsSinceEpoch}_$zipSha256.zip',
      ),
    );
    await file.writeAsBytes(zipBytes, flush: true);

    return BackupInfo(
      filePath: file.path,
      sha256: zipSha256,
      createdAt: createdAt,
    );
  }

  @override
  Future<void> restoreBackupZip(String zipPath) async {
    await _ensureSuperAdmin();

    final maintenance = await AppPaths.maintenanceFlagFile();
    final metaBefore = await _meta();
    await _db.upsertAppMeta(
      AppMetasCompanion(
        id: Value(metaBefore.id),
        installedAt: Value(metaBefore.installedAt),
        trialEndsAt: Value(metaBefore.trialEndsAt),
        lastSeenAt: Value(metaBefore.lastSeenAt),
        licenseStatus: Value(metaBefore.licenseStatus),
        demoMode: Value(metaBefore.demoMode),
        currentTenantId: Value(metaBefore.currentTenantId),
        currentBranchId: Value(metaBefore.currentBranchId),
        currentUserId: Value(metaBefore.currentUserId),
        sessionActive: Value(metaBefore.sessionActive),
        businessType: Value(metaBefore.businessType),
        maintenanceMode: const Value(true),
        allowNegativeStock: Value(metaBefore.allowNegativeStock),
        schemaVersion: Value(metaBefore.schemaVersion),
        createdAt: Value(metaBefore.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await maintenance.writeAsString(
      DateTime.now().toIso8601String(),
      flush: true,
    );

    final zipFile = File(zipPath);
    if (!zipFile.existsSync()) {
      try {
        await maintenance.delete();
      } catch (_) {}
      throw StateError('Backup ZIP no encontrado');
    }

    final dbFile = await AppPaths.databaseFile();
    final logsFile = await AppPaths.logsFile();
    final imagesDir = await AppPaths.imagesDir();
    final thumbsDir = await AppPaths.thumbsDir();

    final backupsDir = await AppPaths.backupsDir();
    final rollbackDir = Directory(
      p.join(
        backupsDir.path,
        'rollback_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await rollbackDir.create(recursive: true);

    final rollbackDb = File(p.join(rollbackDir.path, p.basename(dbFile.path)));
    final rollbackLogs = File(
      p.join(rollbackDir.path, p.basename(logsFile.path)),
    );
    final rollbackImages = Directory(p.join(rollbackDir.path, 'images'));
    final rollbackThumbs = Directory(p.join(rollbackDir.path, 'thumbnails'));

    try {
      if (dbFile.existsSync()) await dbFile.copy(rollbackDb.path);
      if (logsFile.existsSync()) await logsFile.copy(rollbackLogs.path);
      await _copyDirectory(imagesDir, rollbackImages);
      await _copyDirectory(thumbsDir, rollbackThumbs);

      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      await _deleteChildren(imagesDir);
      await _deleteChildren(thumbsDir);
      if (dbFile.existsSync()) await dbFile.delete();
      if (logsFile.existsSync()) await logsFile.delete();

      Map<String, dynamic>? metadata;
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name;
        final data = file.content as List<int>;

        if (name == 'metadata.json') {
          metadata = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
          continue;
        }

        if (name.startsWith('db/')) {
          await dbFile.parent.create(recursive: true);
          await dbFile.writeAsBytes(data, flush: true);
          continue;
        }

        if (name.startsWith('logs/')) {
          await logsFile.parent.create(recursive: true);
          await logsFile.writeAsBytes(data, flush: true);
          continue;
        }

        if (name.startsWith('images/')) {
          final rel = name.substring('images/'.length);
          if (rel.isEmpty) continue;
          final out = File(p.join(imagesDir.path, rel));
          await out.parent.create(recursive: true);
          await out.writeAsBytes(data, flush: true);
          continue;
        }

        if (name.startsWith('thumbnails/')) {
          final rel = name.substring('thumbnails/'.length);
          if (rel.isEmpty) continue;
          final out = File(p.join(thumbsDir.path, rel));
          await out.parent.create(recursive: true);
          await out.writeAsBytes(data, flush: true);
          continue;
        }
      }

      if (metadata == null) {
        throw StateError('metadata.json faltante en backup');
      }

      final expected = metadata['contentSha256']?.toString();
      final actual = await _computeContentSha256(
        dbFile: dbFile,
        logsFile: logsFile,
        imagesDir: imagesDir,
        thumbsDir: thumbsDir,
      );
      if (expected == null || expected != actual) {
        throw StateError('Checksum inválido en restore');
      }
    } catch (e) {
      if (rollbackDb.existsSync()) {
        try {
          if (dbFile.existsSync()) {
            await dbFile.delete();
          }
          await rollbackDb.copy(dbFile.path);
        } catch (_) {
          // Si el archivo está bloqueado por la conexión actual, se conserva
          // el error original del restore y se evita enmascararlo.
        }
      }
      if (rollbackLogs.existsSync()) {
        try {
          if (logsFile.existsSync()) {
            await logsFile.delete();
          }
          await rollbackLogs.copy(logsFile.path);
        } catch (_) {
          // Logs rollback best-effort: nunca reemplazar el error principal.
        }
      }
      await _deleteChildren(imagesDir);
      await _deleteChildren(thumbsDir);
      if (rollbackImages.existsSync()) {
        await _copyDirectory(rollbackImages, imagesDir);
      }
      if (rollbackThumbs.existsSync()) {
        await _copyDirectory(rollbackThumbs, thumbsDir);
      }
      rethrow;
    } finally {
      final after = await _db.getAppMeta();
      if (after != null) {
        await _db.upsertAppMeta(
          AppMetasCompanion(
            id: Value(after.id),
            installedAt: Value(after.installedAt),
            trialEndsAt: Value(after.trialEndsAt),
            lastSeenAt: Value(after.lastSeenAt),
            licenseStatus: Value(after.licenseStatus),
            demoMode: Value(after.demoMode),
            currentTenantId: Value(after.currentTenantId),
            currentBranchId: Value(after.currentBranchId),
            currentUserId: Value(after.currentUserId),
            sessionActive: Value(after.sessionActive),
            businessType: Value(after.businessType),
            maintenanceMode: const Value(false),
            allowNegativeStock: Value(after.allowNegativeStock),
            schemaVersion: Value(after.schemaVersion),
            createdAt: Value(after.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      if (rollbackDir.existsSync()) {
        await rollbackDir.delete(recursive: true);
      }
      if (maintenance.existsSync()) {
        await maintenance.delete();
      }
    }
  }

  Future<void> _appendDirectoryToArchive({
    required Archive archive,
    required Directory dir,
    required String zipPrefix,
  }) async {
    if (!dir.existsSync()) return;
    final entities = dir.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: dir.path).replaceAll('\\', '/');
      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile('$zipPrefix/$rel', bytes.length, bytes));
    }
  }

  Future<String> _computeContentSha256({
    required File dbFile,
    required File logsFile,
    required Directory imagesDir,
    required Directory thumbsDir,
  }) async {
    final sb = StringBuffer();
    if (dbFile.existsSync()) {
      sb.write(sha256.convert(await dbFile.readAsBytes()).toString());
    }
    if (logsFile.existsSync()) {
      sb.write(sha256.convert(await logsFile.readAsBytes()).toString());
    }

    final imageFiles =
        imagesDir
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in imageFiles) {
      sb.write(sha256.convert(await f.readAsBytes()).toString());
    }

    final thumbFiles =
        thumbsDir
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in thumbFiles) {
      sb.write(sha256.convert(await f.readAsBytes()).toString());
    }

    return sha256.convert(utf8.encode(sb.toString())).toString();
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!source.existsSync()) return;
    await target.create(recursive: true);
    final entities = source.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is File) {
        final rel = p.relative(entity.path, from: source.path);
        final dest = File(p.join(target.path, rel));
        await dest.parent.create(recursive: true);
        await entity.copy(dest.path);
      }
    }
  }

  int _fileCount(Directory dir) {
    if (!dir.existsSync()) return 0;
    return dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .length;
  }

  Future<void> _deleteChildren(Directory dir) async {
    if (!dir.existsSync()) return;
    final children = dir.listSync(recursive: false, followLinks: false);
    for (final entry in children) {
      if (entry is File) {
        await entry.delete();
      } else if (entry is Directory) {
        await entry.delete(recursive: true);
      }
    }
  }
}
