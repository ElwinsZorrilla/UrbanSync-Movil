import 'package:flutter_test/flutter_test.dart';
import 'package:urbansync/shared/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('acepta un correo válido', () {
      expect(Validators.email('ana@urbansync.com'), isNull);
    });

    test('rechaza vacío', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rechaza formato inválido', () {
      expect(Validators.email('ana@'), isNotNull);
      expect(Validators.email('ana.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('acepta 6+ caracteres', () {
      expect(Validators.password('Clave1*'), isNull);
    });

    test('rechaza menos de 6', () {
      expect(Validators.password('123'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('coincide', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });

    test('no coincide', () {
      expect(Validators.confirmPassword('abc123', 'xyz999'), isNotNull);
    });
  });

  group('Validators.cedula', () {
    test('acepta cédula válida', () {
      expect(Validators.cedula('00112345678'), isNull);
    });

    test('rechaza vacía', () {
      expect(Validators.cedula(''), isNotNull);
    });
  });
}
