import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/usage_quota/data/dtos/usage_quota_dto.dart';

class UsageQuotaRemoteDataSource {
  UsageQuotaRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;
  static const _getQuotaSnapshotRpc = 'get_quota_snapshot';

  Future<UsageQuotaDto> getUsageQuota() async {
    if (_supabase.auth.currentUser == null) {
      throw const UnauthenticatedException();
    }

    final response = await _supabase.rpc<Object?>(_getQuotaSnapshotRpc);
    if (response == null) throw const UnauthenticatedException();
    return decodeFunctionResponse(response, UsageQuotaDto.fromJson);
  }
}
