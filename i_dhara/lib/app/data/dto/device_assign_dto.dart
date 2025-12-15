class StarterCreateDto {
  final String pcbNumber;
  final String motorName;
  final double hp;
  final int locationId;

  final String? name;
  final String? serialNumber;
  final String? starterNumber;
  final String? macAddress;
  final int? gatewayId;

  StarterCreateDto({
    required this.pcbNumber,
    required this.motorName,
    required this.hp,
    required this.locationId,
    this.name,
    this.serialNumber,
    this.starterNumber,
    this.macAddress,
    this.gatewayId,
  });

  /// Convert DTO to API JSON payload
  Map<String, dynamic> toJson() {
    return {
      "pcb_number": pcbNumber,
      "motor_name": motorName,
      "hp": hp,
      "location_id": locationId,
      if (name != null) "name": name,
      if (serialNumber != null) "serial_number": serialNumber,
      if (starterNumber != null) "starter_number": starterNumber,
      if (macAddress != null) "mac_address": macAddress,
      if (gatewayId != null) "gateway_id": gatewayId,
    };
  }
}
