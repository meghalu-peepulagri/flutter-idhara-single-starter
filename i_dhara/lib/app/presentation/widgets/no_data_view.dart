import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:i_dhara/app/core/utils/app_text/app_text.dart';

class NoAlertsFound extends StatelessWidget {
  const NoAlertsFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/faults_no_data.svg',
            height: 100,
            width: 100,
            // color:   const Color(0xFFFFA500),
          ),
          AppText(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            text: AppLocalizations.of(context)!.noAlerts,
          ),
        ],
      ),
    );
  }
}

class NoFaultsFound extends StatelessWidget {
  const NoFaultsFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/Alerts.svg',
            height: 100,
            width: 100,
            // color:   const Color(0xFFFFA500),
          ),
          AppText(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            text: AppLocalizations.of(context)!.noFaults,
          ),
        ],
      ),
    );
  }
}

class NoLocationsFound extends StatelessWidget {
  const NoLocationsFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/location.svg',
            height: 70,
            width: 70,
          ),
          AppText(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              text: AppLocalizations.of(context)!.noLocations),
        ],
      ),
    );
  }
}

class NoGatewaysFound extends StatelessWidget {
  const NoGatewaysFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/wifi.svg', // Reuse same asset or replace
            height: 80,
            width: 80,
          ),
          AppText(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            text: AppLocalizations.of(context)!.noGateways,
          ),
        ],
      ),
    );
  }
}

class NoPondsFound extends StatelessWidget {
  const NoPondsFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/images/Pond.svg', height: 100, width: 100),
          AppText(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              text: AppLocalizations.of(context)!.noPonds),
        ],
      ),
    );
  }
}

class NoLogsFound extends StatelessWidget {
  const NoLogsFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/log-data.svg',
            height: 80,
            width: 80,
            color: Colors.grey.shade500,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
            ),
            child: AppText(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              text: AppLocalizations.of(context)!.noLogs,
            ),
          ),
        ],
      ),
    );
  }
}

class NoStartersFound extends StatelessWidget {
  const NoStartersFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/Device Icon.svg',
            height: 70,
            width: 70,
          ),
          AppText(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              text: AppLocalizations.of(context)!.noDevices),
        ],
      ),
    );
  }
}

class NoMotorFound extends StatelessWidget {
  const NoMotorFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/motor.svg',
            height: 80,
            width: 80,
            // color: Colors.grey.shade500,
          ),
          AppText(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            text: "  ${AppLocalizations.of(context)!.noPumps}",
          ),
        ],
      ),
    );
  }
}

class NoModeFound extends StatelessWidget {
  const NoModeFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/Modes.svg',
            height: 80,
            width: 80,
            color: Colors.grey.shade500,
          ),
          AppText(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            text: AppLocalizations.of(context)!.noModes,
          ),
        ],
      ),
    );
  }
}

class NoGraphsFound extends StatelessWidget {
  const NoGraphsFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.only(left: 8, top: 15, right: 8, bottom: 15),
      child: Column(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/images/No graph.svg', height: 70, width: 70),
          AppText(
              text: AppLocalizations.of(context)!.noGraph,
              fontSize: 16,
              fontWeight: FontWeight.w500)
        ],
      ),
    ));
  }
}
