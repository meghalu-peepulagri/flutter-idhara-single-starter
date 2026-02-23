import 'dart:async';

import 'package:get/get.dart';
import 'package:i_dhara/app/core/services/connectivity_service.dart';

mixin ConnectivityMixin on GetxController {
  StreamSubscription? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription =
        ConnectivityService.to.onReconnected.listen((_) {
      onRetry();
    });
  }

  /// Override this method to implement the retry logic when internet is restored.
  Future<void> onRetry();

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
