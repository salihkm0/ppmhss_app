class StudentModel {
  final String id;
  final String fullName;
  final String studentCode;
  final String? admissionNo;
  final String? rollNumber;
  final String? className;
  final String? division;
  final String? gender;
  final DateTime? dateOfBirth;
  final DateTime? admissionDate;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? fatherFullName;
  final String? motherFullName;
  final String? guardian;
  final String? relationOfGuardian;
  final String? occupationOfGuardian;
  final String? phoneNumber;
  final String? religion;
  final String? casteName;
  final String? category;
  final String? bloodGroup;
  final String? nationality;
  final String? birthPlace;
  final String? identificationMark1;
  final String? identificationMark2;
  final String? eid;
  final String? houseName;
  final String? streetName;
  final String? postOffice;
  final String? pincode;
  final String? localBody;
  final String? municipality;
  final String? gramaPanchayath;
  final String? districtPanchayath;
  final String? corporation;
  final String? taluk;
  final String? blockPanchayath;
  final String? revenueDistrict;
  final String? bankName;
  final String? branchName;
  final String? ifscCode;
  final String? accountNumber;
  final String? classOnAdmission;
  final String? instructionMedium;
  final int? annualIncome;
  final bool? apl;
  final String? hostelites;
  final String status;
  final String? classId;
  final String? academicYearId;
  final dynamic firstLanguagePaper1;
  final dynamic firstLanguagePaper2;
  final dynamic thirdLanguage;
  final dynamic additionalLanguage;
  final DateTime? createdAt;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.studentCode,
    this.admissionNo,
    this.rollNumber,
    this.className,
    this.division,
    this.gender,
    this.dateOfBirth,
    this.admissionDate,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.fatherFullName,
    this.motherFullName,
    this.guardian,
    this.relationOfGuardian,
    this.occupationOfGuardian,
    this.phoneNumber,
    this.religion,
    this.casteName,
    this.category,
    this.bloodGroup,
    this.nationality,
    this.birthPlace,
    this.identificationMark1,
    this.identificationMark2,
    this.eid,
    this.houseName,
    this.streetName,
    this.postOffice,
    this.pincode,
    this.localBody,
    this.municipality,
    this.gramaPanchayath,
    this.districtPanchayath,
    this.corporation,
    this.taluk,
    this.blockPanchayath,
    this.revenueDistrict,
    this.bankName,
    this.branchName,
    this.ifscCode,
    this.accountNumber,
    this.classOnAdmission,
    this.instructionMedium,
    this.annualIncome,
    this.apl,
    this.hostelites,
    this.status = 'active',
    this.classId,
    this.academicYearId,
    this.firstLanguagePaper1,
    this.firstLanguagePaper2,
    this.thirdLanguage,
    this.additionalLanguage,
    this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    // Helper: safely parse int from String/int/double
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    // Helper: extract _id string whether field is a Map or plain String
    String? extractId(dynamic v) {
      if (v == null) return null;
      if (v is Map) return v['_id']?.toString();
      return v.toString();
    }

    return StudentModel(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['studentName']?.toString() ?? '',
      studentCode: json['studentCode']?.toString() ?? '',
      admissionNo: json['admissionNo']?.toString(),
      rollNumber: json['rollNumber']?.toString(),
      className: json['className']?.toString() ??
          (json['classId'] is Map ? json['classId']['name']?.toString() : null),
      division: json['division']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'].toString()) : null,
      admissionDate: json['admissionDate'] != null ? DateTime.tryParse(json['admissionDate'].toString()) : null,
      parentName: json['parentName']?.toString(),
      parentPhone: json['parentPhone']?.toString(),
      parentEmail: json['parentEmail']?.toString(),
      fatherFullName: json['fatherFullName']?.toString(),
      motherFullName: json['motherFullName']?.toString(),
      guardian: json['guardian']?.toString(),
      relationOfGuardian: json['relationOfGuardian']?.toString(),
      occupationOfGuardian: json['occupationOfGuardian']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      religion: json['religion']?.toString(),
      casteName: json['casteName']?.toString(),
      category: json['category']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      nationality: json['nationality']?.toString(),
      birthPlace: json['birthPlace']?.toString(),
      identificationMark1: json['identificationMark1']?.toString(),
      identificationMark2: json['identificationMark2']?.toString(),
      eid: json['eid']?.toString(),
      houseName: json['houseName']?.toString(),
      streetName: json['streetName']?.toString(),
      postOffice: json['postOffice']?.toString(),
      pincode: json['pincode']?.toString(),
      localBody: json['localBody']?.toString(),
      municipality: json['municipality']?.toString(),
      gramaPanchayath: json['gramaPanchayath']?.toString(),
      districtPanchayath: json['districtPanchayath']?.toString(),
      corporation: json['corporation']?.toString(),
      taluk: json['taluk']?.toString(),
      blockPanchayath: json['blockPanchayath']?.toString(),
      revenueDistrict: json['revenueDistrict']?.toString(),
      bankName: json['bankName']?.toString(),
      branchName: json['branchName']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      classOnAdmission: json['classOnAdmission']?.toString(),
      instructionMedium: json['instructionMedium']?.toString(),
      annualIncome: parseInt(json['annualIncome']),
      apl: json['apl'] == true || json['apl'] == 'true',
      hostelites: json['hostelites']?.toString(),
      status: json['status']?.toString() ?? 'active',
      classId: extractId(json['classId']),
      academicYearId: extractId(json['academicYearId']),
      firstLanguagePaper1: json['firstLanguagePaper1'],
      firstLanguagePaper2: json['firstLanguagePaper2'],
      thirdLanguage: json['thirdLanguage'],
      additionalLanguage: json['additionalLanguage'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'studentCode': studentCode,
      'admissionNo': admissionNo,
      'rollNumber': rollNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'admissionDate': admissionDate?.toIso8601String(),
      'fatherFullName': fatherFullName,
      'motherFullName': motherFullName,
      'guardian': guardian,
      'relationOfGuardian': relationOfGuardian,
      'occupationOfGuardian': occupationOfGuardian,
      'phoneNumber': phoneNumber,
      'religion': religion,
      'casteName': casteName,
      'category': category,
      'bloodGroup': bloodGroup,
      'nationality': nationality,
      'birthPlace': birthPlace,
      'identificationMark1': identificationMark1,
      'identificationMark2': identificationMark2,
      'eid': eid,
      'houseName': houseName,
      'streetName': streetName,
      'postOffice': postOffice,
      'pincode': pincode,
      'localBody': localBody,
      'municipality': municipality,
      'gramaPanchayath': gramaPanchayath,
      'districtPanchayath': districtPanchayath,
      'corporation': corporation,
      'taluk': taluk,
      'blockPanchayath': blockPanchayath,
      'revenueDistrict': revenueDistrict,
      'bankName': bankName,
      'branchName': branchName,
      'ifscCode': ifscCode,
      'accountNumber': accountNumber,
      'classOnAdmission': classOnAdmission,
      'instructionMedium': instructionMedium,
      'annualIncome': annualIncome,
      'apl': apl,
      'hostelites': hostelites,
      'status': status,
      'classId': classId,
      'academicYearId': academicYearId,
      'firstLanguagePaper1': firstLanguagePaper1,
      'firstLanguagePaper2': firstLanguagePaper2,
      'thirdLanguage': thirdLanguage,
      'additionalLanguage': additionalLanguage,
    };
  }
}