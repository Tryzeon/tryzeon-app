import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/location/domain/entities/geo_coordinates.dart';
import 'package:typed_result/typed_result.dart';

abstract class GeocodingService {
  /// `Ok(null)` means the geocoder found no match for [address].
  Future<Result<GeoCoordinates?, Failure>> geocodeAddress(final String address);
}
