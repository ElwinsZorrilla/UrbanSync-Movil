import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:urbansync/app/app.dart';

Future<bool> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int tries = 60,
  Duration step = const Duration(milliseconds: 500),
}) async {
  for (var i = 0; i < tries; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: login del gestor → home → dashboard → perfil (con capturas)',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: UrbanSyncApp()));

    // Splash → restauración de sesión → Login.
    final onLogin = await _waitFor(tester, find.text('Iniciar sesión'));
    expect(onLogin, isTrue, reason: 'No llegó a la pantalla de login');

    await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('01-login');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'supervisor@urbansync.com');
    await tester.enterText(fields.at(1), 'Supervisor123*');
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));

    // Login real contra la API dockerizada → redirección al home del gestor.
    final onHome = await _waitFor(tester, find.text('Cola de análisis'));
    expect(onHome, isTrue,
        reason:
            'No llegó al home del gestor tras el login (¿API arriba en 10.0.2.2:8080?)');
    await tester.pump(const Duration(seconds: 1));
    await binding.takeScreenshot('02-home-triage');
    expect(find.text('Indicadores'), findsWidgets);

    // Indicadores (dashboard con fl_chart).
    await tester.tap(find.text('Indicadores'));
    await _waitFor(tester, find.text('Incidencias por estado'));
    await tester.pump(const Duration(seconds: 1));
    await binding.takeScreenshot('03-dashboard');

    // Perfil.
    await tester.tap(find.text('Perfil'));
    await _waitFor(tester, find.text('Cerrar sesión'));
    await tester.pump(const Duration(seconds: 1));
    await binding.takeScreenshot('04-perfil');
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
