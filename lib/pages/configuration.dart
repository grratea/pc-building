class Configuration {
  String? cpuId;
  String? motherboardId;
  String? ramId;
  String? gpuId;
  String? storageId;
  String? psuId;
  String? caseId;

  Map<String, dynamic> toMap() {
    return {
      'cpu': cpuId,
      'mobo': motherboardId,
      'ram': ramId,
      'gpu': gpuId,
      'storage': storageId,
      'psu': psuId,
      'case': caseId,
    };
  }
}
