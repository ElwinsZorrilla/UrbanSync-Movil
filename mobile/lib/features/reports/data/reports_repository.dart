import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/report_summary.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.read(dioProvider)),
);

class ReportsRepository {
  const ReportsRepository(this._dio);
  final Dio _dio;

  Future<ReportSummary> summary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/reports/summary',
      );
      return ReportSummary.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
