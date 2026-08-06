import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbansync/features/auth/presentation/change_password_page.dart';

void main() {
  testWidgets('ChangePasswordPage muestra los tres campos', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChangePasswordPage())),
    );

    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Contraseña actual'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
    expect(find.text('Confirmar nueva contraseña'), findsOneWidget);
  });

  testWidgets('ChangePasswordPage valida campos vacíos', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChangePasswordPage())),
    );

    await tester.tap(
      find.widgetWithText(FilledButton, 'Actualizar contraseña'),
    );
    await tester.pump();

    expect(find.text('La contraseña es obligatoria.'), findsNWidgets(2));
    expect(find.text('Debe confirmar la contraseña.'), findsOneWidget);
  });

  testWidgets('ChangePasswordPage exige que la confirmación coincida', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChangePasswordPage())),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Actual1*');
    await tester.enterText(fields.at(1), 'NuevaPass1*');
    await tester.enterText(fields.at(2), 'OtraPass1*');

    await tester.tap(
      find.widgetWithText(FilledButton, 'Actualizar contraseña'),
    );
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });
}
