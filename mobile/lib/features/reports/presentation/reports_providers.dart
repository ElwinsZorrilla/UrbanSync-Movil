import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_repository.dart';
import '../domain/report_summary.dart';

final reportSummaryProvider = FutureProvider.autoDispose<ReportSummary>(
  (ref) => ref.read(reportsRepositoryProvider).summary(),
);
