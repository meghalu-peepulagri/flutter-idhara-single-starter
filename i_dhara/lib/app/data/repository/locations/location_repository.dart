import 'package:i_dhara/app/data/models/locations/add_new_location_model.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';

abstract class LocationDropdownRepository {
  Future<LocationDropDownResponse?> getLocations();

  //[Get all locations]
  Future<LocationResponse?> getAllLocations();
  //[Add new location]
  Future<AddNewLocationResponse?> addLocation(String name);
}
