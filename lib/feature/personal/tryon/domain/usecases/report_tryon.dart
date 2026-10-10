import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_report_repository.dart';
import 'package:typed_result/typed_result.dart';

class ReportTryon {
  ReportTryon({required final TryonReportRepository reportRepository})
    : _reportRepository = reportRepository;

  final TryonReportRepository _reportRepository;

  Future<Result<void, Failure>> call(final String tryonId) {
    return _reportRepository.report(tryonId);
  }
}
