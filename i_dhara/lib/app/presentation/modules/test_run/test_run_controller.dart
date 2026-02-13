import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repo_impl.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repository.dart';

import '../../../data/models/settings/user_setting_limits2_model.dart';
import '../../../data/repository/settings/settings_repo_impl.dart';

class TestRunController extends GetxController {
  final DevicesRepositoryImpl _repository = DevicesRepositoryImpl();
  bool isLoadingApiData = false;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserSettings2?> userSettings2 = Rx<UserSettings2?>(null);
  var pcbNumber = ''.obs;
  var macAddress = ''.obs;

  var isdisabled = false.obs;

  var drf = 0.obs;
  var olf = 0.obs;
  var flc = 0.0.obs;
  var lrf = 0.0.obs;
  var olr = 0.0.obs;
  var lrr = 0.0.obs;

  final connectivity = Connectivity();
  var hasInternet = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  void _initConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.isNotEmpty) {
      _updateConnectionStatus(connectivityResult.first);
    }
    connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    hasInternet.value = result != ConnectivityResult.none;
  }

  Future<bool> updateTestRunStatus(int motorId, TestRunStatus status) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await _repository.testRun(motorId, status);
      if (response != null && response.success == true) {
        return true;
      } else {
        errorMessage.value =
            response?.message ?? 'Failed to update test run status';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Start test run - calls API with IN_TEST status
  Future<bool> startTestRun(int motorId) async {
    return await updateTestRunStatus(motorId, TestRunStatus.inTest);
  }

  /// Complete test run - calls API with COMPLETED status
  Future<bool> completeTestRun(int motorId) async {
    return await updateTestRunStatus(motorId, TestRunStatus.completed);
  }

  /// Fail test run - calls API with FAILED status
  Future<bool> failTestRun(int motorId) async {
    return await updateTestRunStatus(motorId, TestRunStatus.failed);
  }

  /// Fail test run - calls API with FAILED status
  Future<bool> processingTestRun(int motorId) async {
    return await updateTestRunStatus(motorId, TestRunStatus.processing);
  }

  String pcbnumberPass(Starter? starter) {
    try {
      if (starter != null) {
        if (starter.pcbNumber != null) {
          return starter.pcbNumber.toString();
        } else if (starter.macAddress != null) {
          return starter.macAddress.toString();
        } else {
          return '';
        }
      } else {
        return '0';
      }
    } catch (e) {
      print("error ---> $e");
      return '';
    }
  }

  double calculatedFlc(double val, double flcVal) {
    final percentLow = val.toInt() / 100;
    final res = percentLow * flcVal;
    final newRes = double.parse(res.toStringAsFixed(2)) ?? 0.0;
    return newRes;
  }

  Future<void> fetchUserSettings2() async {
    try {
      // errorMessage.value = '';
      final response = await SettingsRepositoryImpl().getSettings2();
      if (response != null &&
          response.success == true &&
          response.data != null) {
        userSettings2.value = response.data;
        pcbNumber.value = pcbnumberPass(response.data?.starter);
        macAddress.value = response.data?.starter?.macAddress ?? '';
        flc.value = userSettings2.value?.flc?.toDouble() ?? 0.0;
        drf.value = userSettings2.value?.drf?.toInt() ?? 0;
        olf.value = userSettings2.value?.olf?.toInt() ?? 0;
        lrf.value = userSettings2.value?.lrf?.toDouble() ?? 0.0;
        olr.value = userSettings2.value?.olr?.toDouble() ?? 0.0;
        lrr.value = userSettings2.value?.lrr?.toDouble() ?? 0.0;
      } else {
        errorMessage.value = response?.message ?? 'Failed to load settings';
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
      print('Error fetching user settings: $e');
    }
  }
}
