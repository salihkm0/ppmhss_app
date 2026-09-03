class SchoolContactsModel {
  final String headmasterName;
  final String headmasterPhone;
  final String sitcName;
  final String sitcPhone;
  final String ptaPresidentName;
  final String ptaPresidentPhone;

  SchoolContactsModel({
    this.headmasterName = '',
    this.headmasterPhone = '',
    this.sitcName = '',
    this.sitcPhone = '',
    this.ptaPresidentName = '',
    this.ptaPresidentPhone = '',
  });

  factory SchoolContactsModel.fromJson(Map<String, dynamic> json) {
    return SchoolContactsModel(
      headmasterName: json['headmasterName']?.toString() ?? '',
      headmasterPhone: json['headmasterPhone']?.toString() ?? '',
      sitcName: json['sitcName']?.toString() ?? '',
      sitcPhone: json['sitcPhone']?.toString() ?? '',
      ptaPresidentName: json['ptaPresidentName']?.toString() ?? '',
      ptaPresidentPhone: json['ptaPresidentPhone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headmasterName': headmasterName,
      'headmasterPhone': headmasterPhone,
      'sitcName': sitcName,
      'sitcPhone': sitcPhone,
      'ptaPresidentName': ptaPresidentName,
      'ptaPresidentPhone': ptaPresidentPhone,
    };
  }

  bool get hasAnyContact =>
      headmasterName.isNotEmpty ||
      headmasterPhone.isNotEmpty ||
      sitcName.isNotEmpty ||
      sitcPhone.isNotEmpty ||
      ptaPresidentName.isNotEmpty ||
      ptaPresidentPhone.isNotEmpty;
}
