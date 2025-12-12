import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';

abstract class MotorsRepository {
  Future<MotorResponse?> getMotors();
}
