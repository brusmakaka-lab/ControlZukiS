import 'package:controlzukis/app/app.dart';
import 'package:controlzukis/core/logging/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  runApp(const ProviderScope(child: ControlZukiSApp()));
}
