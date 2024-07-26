// lib/models/company_model.dart

class CompanyModel {
  final int? companyId;
  final String companyName;
  final String address;
  final String phone;
  final String startDate;
  final String version;
  final String logoPath;

  CompanyModel({
    this.companyId,
    required this.companyName,
    required this.address,
    required this.phone,
    required this.startDate,
    required this.version,
    required this.logoPath,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> json) => CompanyModel(
    companyId: json["companyId"],
    companyName: json["companyName"],
    address: json["address"],
    phone: json["phone"],
    startDate: json["startDate"],
    version: json["version"],
    logoPath: json["logoPath"],
  );

  Map<String, dynamic> toMap() => {
    "companyId": companyId,
    "companyName": companyName,
    "address": address,
    "phone": phone,
    "startDate": startDate,
    "version": version,
    "logoPath": logoPath,
  };
}
