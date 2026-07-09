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

  test('login devuelve token y usuario', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        data: {
          'token': 'jwt-token',
          'user': {
            'id': '1',
            'email': 'ciudadano@urbansync.com',
            'fullName': 'Ciudadano',
            'identificationNumber': '001',
            'position': 'Ciudadano',
            'role': 'Ciudadano',
          },
        },
      ),
    );

    final result = await repository.login('ciudadano@urbansync.com', 'Clave1*');

    expect(result.token, 'jwt-token');
    expect(result.user.role, 'Ciudadano');
    expect(result.user.roleGroup.name, 'citizen');
  });

  test('login mapea error HTTP a ApiException', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 401,
        ),
      ),
    );

    expect(
      () => repository.login('x@x.com', 'bad'),
      throwsA(isA<ApiException>()),
    );
  });
}
