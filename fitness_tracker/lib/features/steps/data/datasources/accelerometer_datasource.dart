import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform; // ✅ Importa Platform desde dart:io
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/platform/notification_datasource.dart';
import '../../domain/entities/step_data.dart';

abstract class AccelerometerDataSource {
  Stream<StepData> get stepStream;
  Future<void> startCounting();
  Future<void> stopCounting();
  Future<bool> requestPermissions();
}

class AccelerometerDataSourceImpl implements AccelerometerDataSource {
  final NotificationDataSource _notificationDataSource = NotificationDataSourceImpl();
  StreamSubscription? _subscription;
  int _stepCount = 0;
  double _lastMagnitude = 0;
  final List<double> _magnitudeHistory = [];
  static const int _historySize = 10;
  static const double _stepThreshold = 11.0;
  static const int _notificationThreshold = 30;
  bool _goalNotified = false;

  final StreamController<StepData> _controller = StreamController<StepData>.broadcast();

  @override
  Stream<StepData> get stepStream => _controller.stream;

  @override
  Future<void> startCounting() async {
    final stream = accelerometerEventStream as Stream<AccelerometerEvent>;
    _subscription = stream.listen((AccelerometerEvent event) {
      final magnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      _magnitudeHistory.add(magnitude);
      if (_magnitudeHistory.length > _historySize) {
        _magnitudeHistory.removeAt(0);
      }
      final avgMagnitude = _magnitudeHistory.reduce((a, b) => a + b) / _magnitudeHistory.length;

      if (magnitude > _stepThreshold && _lastMagnitude <= _stepThreshold) {
        _stepCount++;
        if (_stepCount >= _notificationThreshold && !_goalNotified) {
          _goalNotified = true;
          _notificationDataSource.showStepGoalNotification(_stepCount);
        }
      }
      _lastMagnitude = magnitude;

      final activityType = _determineActivity(avgMagnitude);
      _controller.add(StepData(
        stepCount: _stepCount,
        activityType: activityType,
        magnitude: avgMagnitude,
        fallDetected: magnitude > 25.0,
      ));
    });
  }

  @override
  Future<void> stopCounting() async {
    await _subscription?.cancel();
    _controller.close();
    _stepCount = 0;
    _goalNotified = false;
  }

  @override
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.sensors.request();
      return status.isGranted;
    }
    return true; // iOS no requiere permiso explícito
  }

  ActivityType _determineActivity(double magnitude) {
    if (magnitude < 10.5) return ActivityType.stationary;
    if (magnitude < 13.5) return ActivityType.walking;
    return ActivityType.running;
  }
}