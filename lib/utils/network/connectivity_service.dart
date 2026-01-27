import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Logger _logger;

  final StreamController<NetworkStatus> _networkStatusController =
      StreamController<NetworkStatus>.broadcast();

  Stream<NetworkStatus> get networkStatusStream =>
      _networkStatusController.stream;
  NetworkStatus _currentStatus = NetworkStatus.online;
  NetworkStatus get currentStatus => _currentStatus;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isDisposed = false;

  ConnectivityService({required Logger logger}) : _logger = logger;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (_isDisposed) return;

    final isConnected =
        results.any((result) => result != ConnectivityResult.none);

    final newStatus = isConnected ? NetworkStatus.online : NetworkStatus.offline;

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      if (!_networkStatusController.isClosed) {
        _networkStatusController.add(newStatus);
      }
      _logger.d('Network status changed: $newStatus');
    }
  }

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _networkStatusController.close();
  }
}
