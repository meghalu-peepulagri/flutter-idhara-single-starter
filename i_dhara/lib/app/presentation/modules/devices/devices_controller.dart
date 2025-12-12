import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repo_impl.dart';

class DevicesController extends GetxController {
  final RxList<Devices> devicesList = <Devices>[].obs;

  final RxBool isLoading = false.obs;
  var isRefreshing = false.obs;

  final RxString errorMessage = ''.obs;

  final DevicesRepositoryImpl _repository = DevicesRepositoryImpl();

  @override
  void onInit() {
    super.onInit();
    fetchDevices();
  }

  /// Fetch devices from API
  Future<void> fetchDevices() async {
    try {
      if (!isRefreshing.value) isLoading.value = true;

      final response = await _repository.getDevices();

      if (response != null && response.data != null) {
        devicesList.value = response.data!.records ?? [];
      } else {
        errorMessage.value = 'No data found';
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error fetching devices: $e';
      print('Error in fetchDevices: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshDevices() async {
    isRefreshing.value = true;
    await fetchDevices();
  }

  List<Devices> searchDevices(String query) {
    if (query.isEmpty) return devicesList;

    return devicesList.where((device) {
      final nameMatch =
          device.name?.toLowerCase().contains(query.toLowerCase()) ?? false;
      final pcbMatch =
          device.pcbNumber?.toLowerCase().contains(query.toLowerCase()) ??
              false;
      return nameMatch || pcbMatch;
    }).toList();
  }
}
