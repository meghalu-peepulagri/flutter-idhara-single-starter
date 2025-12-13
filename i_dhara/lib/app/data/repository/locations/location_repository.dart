import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';

abstract class LocationDropdownRepository {
  Future<LocationDropDownResponse?> getLocations();

  //[Get all locations]
  Future<LocationResponse?> getAllLocations();
}
