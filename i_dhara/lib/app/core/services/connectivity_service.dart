import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find();

  final Connectivity _connectivity = Connectivity();
  final RxBool _isConnected = true.obs;

  bool get isConnected => _isConnected.value;
  RxBool get rxIsConnected => _isConnected;

  final _reconnectedController = StreamController<void>.broadcast();
  Stream<void> get onReconnected => _reconnectedController.stream;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      Get.log('ConnectivityService checkInitialConnectivity Error: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.0+ returns a list
    final bool wasDisconnected = !_isConnected.value;
    final bool currentlyConnected =
        results.any((result) => result != ConnectivityResult.none);

    _isConnected.value = currentlyConnected;

    if (wasDisconnected && currentlyConnected) {
      Get.log('ConnectivityService: Internet Reconnected');
      _reconnectedController.add(null);
    }

    Get.log(
        'ConnectivityService Status: ${currentlyConnected ? "Connected" : "Disconnected"}');
  }

  @override
  void onClose() {
    _reconnectedController.close();
    super.onClose();
  }
}
