import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/store/profile/data/dtos/store_profile_dto.dart';

class StoreProfileRemoteDataSource {
  StoreProfileRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _storeProfileTable = AppConstants.tableStoreProfiles;

  Future<StoreProfileDto?> getStoreProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_storeProfileTable)
        .select(
          'id, owner_id, name, slug, address, latitude, longitude, logo_path, channels, order_contacts, created_at, updated_at',
        )
        .eq('owner_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return StoreProfileDto.fromJson(response);
  }

  Future<void> updateStoreProfile(final Map<String, dynamic> changes) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final json = Map<String, dynamic>.from(changes)
      ..remove('id')
      ..remove('owner_id');

    await _supabaseClient
        .from(_storeProfileTable)
        .update(json)
        .eq('owner_id', user.id)
        .select('id')
        .single();
  }
}
