import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'configuration.dart';

class ConfigurationProvider extends ChangeNotifier {
  final Configuration _currentConfig = Configuration();
  String? _cpuSocket;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? _currentConfigId;

  Configuration get currentConfig => _currentConfig;
  String? get cpuSocket => _cpuSocket;

  String? get currentConfigId => _currentConfigId;

  set currentConfigId(String? id) {
    _currentConfigId = id;
    notifyListeners();
  }

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

  Future<void> saveCurrentConfiguration(String name, String description, bool isPublic) async {
    final user = FirebaseAuth.instance.currentUser?.uid ?? '';

    final data = _currentConfig.toMap();

    data['name'] = name;
    data['description'] = description;
    data['userId'] = user;
    data['savedAt'] = FieldValue.serverTimestamp();
    data['isPublic'] = isPublic;

    try {
      final docRef = await firestore.collection('configurations').add(data);
      _currentConfigId = docRef.id;
      notifyListeners();
    } catch (e) {
      print('Failed to save config: $e');
      rethrow;
    }
  }
}





