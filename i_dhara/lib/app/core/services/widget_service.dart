import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';

class WidgetService {
  static const String appGroupId = 'group.com.idhara.app';
  static const String androidWidgetName = 'PumpWidgetProvider';
  static const String iosWidgetName = 'PumpWidget';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Error initializing HomeWidget: $e');
    }
  }

  static Future<void> updateWidgetData(
      List<Motor> motors, MqttService? mqttService) async {
    try {
      // Map all motors to simpler JSON objects matching what the native widgets expect
      final widgetDataList = motors.map((motor) {
        final mac = motor.starter?.macAddress;
        final pcb = motor.starter?.pcbNumber;

        // Find latest data from MQTT if available
        MotorData? mqttData;
        if (mqttService != null) {
          for (int i = 1; i <= 4; i++) {
            final groupId = 'G0$i';
            if (mac != null && mac.isNotEmpty) {
              final data = mqttService.motorDataMap['$mac-$groupId'];
              if (data?.hasReceivedData == true) {
                mqttData = data;
                break;
              }
            }
            if (pcb != null && pcb.isNotEmpty && mqttData == null) {
              final data = mqttService.motorDataMap['$pcb-$groupId'];
              if (data?.hasReceivedData == true) {
                mqttData = data;
                break;
              }
            }
          }
        }

        // State (1 for ON, 0 for OFF)
        final isRunning = (mqttData != null && mqttData.hasReceivedData)
            ? mqttData.state == 1
            : motor.state == 1;

        // Signal Quality
        final signalQuality = (mqttData != null &&
                mqttData.hasReceivedData &&
                mqttData.signalStrength > 0)
            ? mqttData.signalStrength
            : (motor.starter?.signalQuality ?? 0);

        // Fault
        final params = motor.starter?.starterParameters;
        int fault = 0;
        if (mqttData != null &&
            mqttData.hasReceivedData &&
            mqttData.fault != 0) {
          fault = mqttData.fault;
        } else if (params != null && params.isNotEmpty) {
          fault = params.first.fault ?? 0;
        }

        // Determine run time (dummy data for visual UI if not available, or real logic if you have it)
        // Since we don't have accurate run time duration in Motor model, we'll keep it simple for now.
        // Calculate progress out of 24 hours (1440 minutes)
        int progress = 0;
        final runTimeString = motor.runTimeDuration ?? '';
        if (runTimeString.isNotEmpty && runTimeString != '0h 0m 0s') {
          int hours = 0;
          int minutes = 0;

          final hMatch = RegExp(r'(\d+)\s*h').firstMatch(runTimeString);
          if (hMatch != null) {
            hours = int.tryParse(hMatch.group(1) ?? '0') ?? 0;
          }

          final mMatch = RegExp(r'(\d+)\s*m').firstMatch(runTimeString);
          if (mMatch != null) {
            minutes = int.tryParse(mMatch.group(1) ?? '0') ?? 0;
          }

          // Fallback if the format is HH:MM:SS
          if (hours == 0 && minutes == 0 && runTimeString.contains(':')) {
            final parts = runTimeString.split(':');
            if (parts.length >= 2) {
              hours = int.tryParse(parts[0]) ?? 0;
              minutes = int.tryParse(parts[1]) ?? 0;
            }
          }

          int totalMinutes = (hours * 60) + minutes;
          double progressDouble = (totalMinutes / 1440.0) * 100;
          progress = progressDouble.clamp(0.0, 100.0).toInt();
        }

        return {
          'id': motor.id,
          'name': motor.aliasName ?? motor.name ?? 'Pump',
          'isRunning': isRunning,
          'signalQuality': signalQuality,
          'fault': fault,
          'runTimeMinutes': runTimeString,
          'runTimeProgress': progress,
        };
      }).toList();

      final jsonString = jsonEncode(widgetDataList);

      await HomeWidget.saveWidgetData<String>('pump_data', jsonString);
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iosWidgetName,
      );

      debugPrint('Widget string updated: $jsonString');
    } catch (e) {
      debugPrint('Error updating widget data: $e');
    }
  }
}
