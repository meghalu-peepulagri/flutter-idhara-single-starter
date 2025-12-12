import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repository.dart';

class MotorsRepositoryImpl implements MotorsRepository {
  @override
  Future<MotorResponse?> getMotors() async {
    final response = await NetworkManager().get('/motors');
    if (response.statusCode == 200) {
      final res = MotorResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
