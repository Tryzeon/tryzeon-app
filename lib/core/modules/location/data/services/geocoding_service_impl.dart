import 'package:geocoding/geocoding.dart';
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/location/domain/entities/geo_coordinates.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

/// Backed by the platform-native geocoder (iOS/Android), so no API key.
class GeocodingServiceImpl implements GeocodingService {
  @override
  Future<Result<GeoCoordinates?, Failure>> geocodeAddress(
    final String address,
  ) async {
    if (address.trim().isEmpty) return const Ok(null);
    try {
      try {
        await setLocaleIdentifier('zh_TW');
      } catch (e) {
        AppLogger.info('Failed to set the geocoding locale: $e');
      }
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return const Ok(null);
      final first = locations.first;
      return Ok((latitude: first.latitude, longitude: first.longitude));
    } catch (e, stackTrace) {
      AppLogger.warning('Geocoding failed for "$address"', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
