import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/repository/locations/location_dropdown_repository.dart';

class LocationDropdownRepoImpl extends LocationDropdownRepository {
  @override
  Future<LocationDropDownResponse?> getLocations() async {
    final response = await NetworkManager().get('/locations/basic');
    if (response.statusCode == 200) {
      final res = LocationDropDownResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
