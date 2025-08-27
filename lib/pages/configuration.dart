class Configuration {
  String? cpuId;
  String? motherboardId;
  String? ramId;
  String? gpuId;
  String? storageId;
  String? psuId;
  String? caseId;

  String? name;
  String? description;
  String? user;  // Usually user ID or email // mozda bolje mail

  Map<String, dynamic> toMap() {
    return {
      'cpu': cpuId,
      'mobo': motherboardId,
      'ram': ramId,
      'gpu': gpuId,
      'storage': storageId,
      'psu': psuId,
      'case': caseId,
      'name': name,
      'description': description,
      'user': user,
    };
  }
}