class MotorAssignDto {
  final int? motorId;
  final String motorName;
  final double hp;

  MotorAssignDto({
    this.motorId,
    required this.motorName,
    required this.hp,
  });

  Map<String, dynamic> toJson() => {
        if (motorId != null) "motor_id": motorId,
        "motor_name": motorName,
        "hp": hp,
      };
}

class StarterCreateDto {
  final String pcbNumber;
  final int locationId;
  final String? deviceInstalledLoc;
  final List<MotorAssignDto> motors;

  StarterCreateDto({
    required this.pcbNumber,
    required this.locationId,
    required this.motors,
    this.deviceInstalledLoc,
  });

  /// Convert DTO to API JSON payload
  Map<String, dynamic> toJson() {
    return {
      "pcb_number": pcbNumber,
      "location_id": locationId,
      if (deviceInstalledLoc != null)
        "device_installed_location": deviceInstalledLoc,
      "motors": motors.map((m) => m.toJson()).toList(),
    };
  }
}
