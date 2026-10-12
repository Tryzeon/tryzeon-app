import 'package:tryzeon/core/modules/location/domain/entities/geo_coordinates.dart';
import 'package:tryzeon/core/modules/location/domain/entities/location_permission_status.dart';

abstract class LocationService {
  Future<GeoCoordinates?> getCoordinates();

  Future<LocationPermissionStatus> requestPermission();

  Future<bool> hasPermission();

  Future<void> openAppSettings();
}
