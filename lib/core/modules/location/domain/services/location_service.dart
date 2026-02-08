import 'package:geolocator/geolocator.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';

/// 位置服務抽象介面
abstract class LocationService {
  /// 取得使用者所在城市和區
  /// 若無法取得位置（權限拒絕、定位失敗等），返回 null
  Future<UserLocation?> getUserLocation();

  /// 請求位置權限
  /// 回傳最終的權限狀態，以便 UI 決定是否引導去設定
  Future<LocationPermission> requestPermission();

  /// 檢查目前是否有權限
  Future<bool> hasPermission();
}
