import 'dart:async';
import 'dart:io';

/// Abstract service to check and monitor network connectivity status
abstract class NetworkConnectivityService {
  /// Stream that emits whenever network status changes (true: online, false: offline)
  Stream<bool> get onConnectivityChanged;

  /// Current connectivity status
  Future<bool> get isConnected;

  /// Dispose any resources/controllers
  void dispose();
}

/// Fake/Mockable network connectivity service for unit tests & simulated conditions
class FakeNetworkConnectivityService implements NetworkConnectivityService {
  bool _isConnected;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  FakeNetworkConnectivityService({bool initialConnected = true})
      : _isConnected = initialConnected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isConnected async => _isConnected;

  /// Toggle connectivity and notify listeners
  void setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _controller.add(connected);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}

/// Default network connectivity service using periodic lightweight DNS/Socket probe
class DefaultNetworkConnectivityService implements NetworkConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _lastStatus = true;
  Timer? _pollingTimer;

  DefaultNetworkConnectivityService({Duration checkInterval = const Duration(seconds: 15)}) {
    _init(checkInterval);
  }

  void _init(Duration checkInterval) {
    _check();
    _pollingTimer = Timer.periodic(checkInterval, (_) => _check());
  }

  Future<void> _check() async {
    final status = await isConnected;
    if (status != _lastStatus) {
      _lastStatus = status;
      _controller.add(status);
    }
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}
