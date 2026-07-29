import 'dart:async';
import 'package:pedometer/pedometer.dart';

class StepCounterService {
  int? _initialStepCount;
  int? _latestStepCount;
  StreamSubscription<StepCount>? _stepSubscription;
  bool _isSensorAvailable = true;

  void startListening() {
    _initialStepCount = null;
    _latestStepCount = null;
    _isSensorAvailable = true;

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          _latestStepCount = event.steps;
          _initialStepCount ??= event.steps;
        },
        onError: (error) {
          _isSensorAvailable = false;
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isSensorAvailable = false;
    }
  }

  int stopAndCalculateSteps({
    required double totalDistanceMeters,
    required double stepLengthMeters,
  }) {
    _stepSubscription?.cancel();
    _stepSubscription = null;

    if (_isSensorAvailable &&
        _initialStepCount != null &&
        _latestStepCount != null &&
        _latestStepCount! >= _initialStepCount!) {
      return _latestStepCount! - _initialStepCount!;
    }

    if (totalDistanceMeters > 0 && stepLengthMeters > 0) {
      return (totalDistanceMeters / stepLengthMeters).floor();
    }
    return 0;
  }
}
