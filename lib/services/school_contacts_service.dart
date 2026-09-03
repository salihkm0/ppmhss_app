import 'package:school_management/models/school_contacts_model.dart';
import 'package:school_management/services/api_service.dart';

class SchoolContactsService {
  final ApiService _apiService = ApiService();

  Future<SchoolContactsModel> getSchoolContacts() async {
    try {
      final response = await _apiService.get('/app-config/school-contacts', noCache: true);
      if (response.data != null && response.data['data'] != null) {
        return SchoolContactsModel.fromJson(Map<String, dynamic>.from(response.data['data']));
      }
      return SchoolContactsModel();
    } catch (_) {
      return SchoolContactsModel();
    }
  }

  Future<bool> updateSchoolContacts(SchoolContactsModel contacts) async {
    try {
      final response = await _apiService.put('/app-config/school-contacts', data: contacts.toJson());
      return response.data != null && response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
