import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/locations/add_new_location_model.dart';
import 'package:i_dhara/app/data/models/locations/delete_location_model.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';
import 'package:i_dhara/app/data/models/locations/rename_location_model.dart';
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
  Future<LocationResponse?> getAllLocations(
      int? page, int? limit, String? search) async {
    Map<String, dynamic> queryParams = {};
    if (search != null && search.isNotEmpty) {
      queryParams['search_string'] = search;
    }
    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();
    final response =
        await NetworkManager().get('/locations', queryParameters: queryParams);
    if (response.statusCode == 200) {
      final res = LocationResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<AddNewLocationResponse?> addLocation(String name) async {
    final body = {"name": name};
    final response = await NetworkManager().post('/locations', data: body, {});

    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = AddNewLocationResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  @override
  Future<DeleteLocationResponse?> deleteLocation(int locationId) async {
    final response = await NetworkManager().patch('/locations/$locationId');
    print("line 268 -----------> $locationId");
    print("line 269 -----------> ${response.data}");
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 422) {
      return DeleteLocationResponse.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<RenameLocationResponse?> renameLocation(
      int locationId, String name) async {
    final body = {"name": name};
    final response = await NetworkManager()
        .patch('/locations/$locationId/rename', data: body);

    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = RenameLocationResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }
}
