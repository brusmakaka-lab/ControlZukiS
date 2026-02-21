import 'dart:io';

import 'package:controlzukis/core/constants/app_constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  AppPaths._();

  static Future<Directory> appDir() async {
    final dir = await getApplicationSupportDirectory();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> databaseFile() async {
    final dir = await appDir();
    return File(p.join(dir.path, AppConstants.dbFileName));
  }

  static Future<Directory> imagesDir() async {
    final dir = await appDir();
    final images = Directory(p.join(dir.path, AppConstants.imagesDirName));
    if (!images.existsSync()) {
      await images.create(recursive: true);
    }
    return images;
  }

  static Future<Directory> thumbsDir() async {
    final dir = await appDir();
    final thumbs = Directory(p.join(dir.path, AppConstants.thumbsDirName));
    if (!thumbs.existsSync()) {
      await thumbs.create(recursive: true);
    }
    return thumbs;
  }

  static Future<File> logsFile() async {
    final dir = await appDir();
    final file = File(p.join(dir.path, AppConstants.logsFileName));
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    return file;
  }

  static Future<Directory> backupsDir() async {
    final dir = await appDir();
    final backups = Directory(p.join(dir.path, 'backups'));
    if (!backups.existsSync()) {
      await backups.create(recursive: true);
    }
    return backups;
  }

  static Future<File> maintenanceFlagFile() async {
    final dir = await appDir();
    return File(p.join(dir.path, 'maintenance.flag'));
  }
}
