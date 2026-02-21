import 'dart:convert';
import 'dart:io';

import 'package:controlzukis/core/constants/app_constants.dart';
import 'package:controlzukis/core/storage/app_paths.dart';
import 'package:logger/logger.dart';

enum LogLevel { trace, debug, info, warning, error, fatal }

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  static IOSink? _sink;

  static Future<void> init() async {
    final logsFile = await AppPaths.logsFile();
    _sink = logsFile.openWrite(mode: FileMode.append);
  }

  static Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }

  static void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    final data = <String, dynamic>{
      'ts': DateTime.now().toIso8601String(),
      'level': level.name,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      'extra': extra,
    };

    final line = jsonEncode(data);
    _sink?.writeln(line);

    switch (level) {
      case LogLevel.trace:
      case LogLevel.debug:
        _logger.d(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.info:
        _logger.i(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.warning:
        _logger.w(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.error:
      case LogLevel.fatal:
        _logger.e(message, error: error, stackTrace: stackTrace);
        break;
    }
  }

  static Future<File> exportLogsTo(File targetFile) async {
    await _sink?.flush();
    final source = await AppPaths.logsFile();
    if (!source.existsSync()) {
      await targetFile.writeAsString('');
      return targetFile;
    }
    return source.copy(targetFile.path);
  }

  static Future<void> clear() async {
    final source = await AppPaths.logsFile();
    if (source.existsSync()) {
      await source.writeAsString('');
    }
  }

  static String get logsFileName => AppConstants.logsFileName;
}
