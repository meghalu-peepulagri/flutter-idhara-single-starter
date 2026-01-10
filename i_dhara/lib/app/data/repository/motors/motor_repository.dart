import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';

abstract class MotorsRepository {
  Future<MotorResponse?> getMotors(int? page, int? limit);
  Future<MotorDetailsResponse?> getMotorDetails();
}
