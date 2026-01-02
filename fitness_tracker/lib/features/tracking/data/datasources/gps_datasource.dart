import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/platform/notification_datasource.dart';
import '../../domain/entities/location_point.dart';

abstract class GpsDataSource {
  Future<LocationPoint?> getCurrentLocation();
  Stream<LocationPoint> get locationStream;
  Future<bool> isGpsEnabled();
  Future<bool> requestPermissions();
}

class GpsDataSourceImpl implements GpsDataSource {
  final NotificationDataSource _notificationDataSource = NotificationDataSourceImpl();
  final StreamController<LocationPoint> _controller = StreamController.broadcast();

  @override
  Future<bool> requestPermissions() async {
    var status = await Permission.location.request();
    return status.isGranted;
  }

  @override
  Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPoint?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        speed: position.speed,
        accuracy: position.accuracy,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<LocationPoint> get locationStream {
    // ✅ Usa LocationSettings (obligatorio desde geolocator v10+)
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // ✅ int (metros), no double
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _controller.add(LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        speed: position.speed,
        accuracy: position.accuracy,
        timestamp: position.timestamp ?? DateTime.now(),
      ));
    });

    return _controller.stream;
  }
}