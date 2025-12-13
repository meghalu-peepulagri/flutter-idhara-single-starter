import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';
import 'package:i_dhara/app/data/repository/locations/location_repository.dart';

class LocationRepoImpl extends LocationDropdownRepository {
  @override
  Future<LocationDropDownResponse?> getLocations() async {
    final response = await NetworkManager().get('/locations/basic');
    if (response.statusCode == 200) {
      final res = LocationDropDownResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<LocationResponse?> getAllLocations() async {
    final response = await NetworkManager().get('/locations');
    if (response.statusCode == 200) {
      final res = LocationResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
