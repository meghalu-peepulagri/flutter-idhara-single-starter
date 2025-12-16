import 'package:i_dhara/app/data/models/locations/add_new_location_model.dart';
import 'package:i_dhara/app/data/models/locations/delete_location_model.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';
import 'package:i_dhara/app/data/models/locations/rename_location_model.dart';

abstract class LocationDropdownRepository {
  Future<LocationDropDownResponse?> getLocations();

  //[Get all locations]
  Future<LocationResponse?> getAllLocations(
      int? page, int? limit, String? search);
  //[Add new location]
  Future<AddNewLocationResponse?> addLocation(String name);

  Future<DeleteLocationResponse?> deleteLocation(int locationId);

  Future<RenameLocationResponse?> renameLocation(int locationId, String name);
}
