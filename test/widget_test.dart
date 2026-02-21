import 'package:controlzukis/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('arranca y muestra splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ControlZukiSApp()));
    expect(find.text('Inicializando ControlZukiS...'), findsOneWidget);
  });
}
