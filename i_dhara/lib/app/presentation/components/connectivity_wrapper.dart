import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/services/connectivity_service.dart';
import 'package:i_dhara/app/presentation/widgets/no_internet_view.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!ConnectivityService.to.rxIsConnected.value) {
        return const Scaffold(
          body: Center(
            child: NoInternetWidget(),
          ),
        );
      }
      return child;
    });
  }
}
