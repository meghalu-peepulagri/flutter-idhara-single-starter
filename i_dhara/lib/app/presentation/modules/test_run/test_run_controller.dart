import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repo_impl.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repository.dart';

class TestRunController extends GetxController {
  final DevicesRepositoryImpl _repository = DevicesRepositoryImpl();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

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
}
