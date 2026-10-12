import 'package:tryzeon/core/modules/location/domain/entities/geo_coordinates.dart';

abstract class GeocodingService {
  Future<GeoCoordinates?> geocodeAddress(final String address);
}
