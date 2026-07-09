import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:urbansync/app/app.dart';

Future<bool> _waitFor(WidgetTester tester, Finder finder,
    {int tries = 40, Duration step = const Duration(milliseconds: 500)}) async {
  for (var i = 0; i < tries; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: login del gestor llega al home (Cola de análisis)',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: UrbanSyncApp()));

    // Splash → restauración de sesión → Login.
    final onLogin = await _waitFor(tester, find.text('Iniciar sesión'));
    expect(onLogin, isTrue, reason: 'No llegó a la pantalla de login');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'supervisor@urbansync.com');
    await tester.enterText(fields.at(1), 'Supervisor123*');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));

    // Login real contra la API dockerizada → redirección al home del gestor.
    final onHome = await _waitFor(tester, find.text('Cola de análisis'));
    expect(onHome, isTrue,
        reason: 'No llegó al home del gestor tras el login (¿API arriba en 10.0.2.2:8080?)');

    // La barra de navegación por rol del gestor debe mostrar Indicadores.
    expect(find.text('Indicadores'), findsWidgets);
  });
}
