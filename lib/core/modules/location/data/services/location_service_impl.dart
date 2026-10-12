import 'package:geolocator/geolocator.dart';
import 'package:tryzeon/core/modules/location/domain/entities/geo_coordinates.dart';
import 'package:tryzeon/core/modules/location/domain/entities/location_permission_status.dart';
import 'package:tryzeon/core/modules/location/domain/services/location_service.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class LocationServiceImpl implements LocationService {
  @override
  Future<bool> hasPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
    };
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<GeoCoordinates?> getCoordinates() async {
    try {
      if (!await hasPermission()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get coordinates', e, stackTrace);
      return null;
    }
  }
}
