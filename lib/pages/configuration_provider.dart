import 'package:flutter/cupertino.dart';
import 'package:zavrsni/pages/configuration.dart';

class ConfigurationProvider extends ChangeNotifier {
  final Configuration _currentConfig = Configuration();
  String? _cpuSocket;

  Configuration get currentConfig => _currentConfig;
  String? get cpuSocket => _cpuSocket;

  void setCpu(String cpuId, String socket) {
    _currentConfig.cpuId = cpuId;
    _cpuSocket = socket;
    notifyListeners();
  }

  void setMotherboard(String moboId) {
    _currentConfig.motherboardId = moboId;
    notifyListeners();
  }
  void setGpu(String gpuId) {
    _currentConfig.gpuId = gpuId;
    notifyListeners();
  }

  void setRam(String ramId) {
    _currentConfig.ramId = ramId;
    notifyListeners();
  }

  void setStorage(String storageId) {
    _currentConfig.storageId = storageId;
    notifyListeners();
  }

  void setPsu(String psuId) {
    _currentConfig.psuId = psuId;
    notifyListeners();
  }

  void setCase(String caseId) {
    _currentConfig.caseId = caseId;
    notifyListeners();
  }

}
