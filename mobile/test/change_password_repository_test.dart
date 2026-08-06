import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:urbansync/core/network/api_exception.dart';
import 'package:urbansync/features/auth/data/auth_repository.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late AuthRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = AuthRepository(dio);
  });

  test('changePassword envía las tres claves al endpoint', () async {
    when(
      () =>
          dio.post<void>('/api/auth/change-password', data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(path: '/api/auth/change-password'),
        statusCode: 204,
      ),
    );

    await repository.changePassword(
      currentPassword: 'Actual1*',
      newPassword: 'Nueva1*',
      confirmNewPassword: 'Nueva1*',
    );

    final captured = verify(
      () => dio.post<void>(
        '/api/auth/change-password',
        data: captureAny(named: 'data'),
      ),
    ).captured.single;

    expect(captured, {
      'currentPassword': 'Actual1*',
      'newPassword': 'Nueva1*',
      'confirmNewPassword': 'Nueva1*',
    });
  });

  test('changePassword mapea el 401 de contraseña actual incorrecta', () async {
    when(
      () =>
          dio.post<void>('/api/auth/change-password', data: any(named: 'data')),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/auth/change-password'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/change-password'),
          statusCode: 401,
          data: {
            'title': 'Contraseña actual incorrecta',
            'detail': 'La contraseña actual no es válida.',
          },
        ),
      ),
    );

    await expectLater(
      () => repository.changePassword(
        currentPassword: 'mala',
        newPassword: 'Nueva1*',
        confirmNewPassword: 'Nueva1*',
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having(
              (e) => e.message,
              'message',
              'La contraseña actual no es válida.',
            ),
      ),
    );
  });
}
