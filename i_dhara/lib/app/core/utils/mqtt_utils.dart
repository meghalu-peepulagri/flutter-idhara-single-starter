import '../../data/models/settings/user_setting_limits2_model.dart';

String deviceAllocation(SettingStarter? starter) {
  return '';
}

String getMotorIdentifier(String allocate, String pcbNumber, String macNumber) {
  print("line 8 --->  $allocate $pcbNumber $macNumber");
  final mac = macNumber;
  final pcb = pcbNumber;
  if (allocate == 'true') {
    return pcb.toString();
  } else {
    return mac.toString();
  }
}
