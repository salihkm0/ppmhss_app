import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_management/models/school_contacts_model.dart';
import 'package:school_management/services/school_contacts_service.dart';
import 'package:school_management/utils/theme.dart';

class SchoolContactsCard extends StatefulWidget {
  const SchoolContactsCard({super.key});

  @override
  State<SchoolContactsCard> createState() => _SchoolContactsCardState();
}

class _SchoolContactsCardState extends State<SchoolContactsCard> {
  final SchoolContactsService _service = SchoolContactsService();
  SchoolContactsModel? _contacts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _service.getSchoolContacts();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    }
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final Uri uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_contacts == null || !_contacts!.hasAnyContact) {
      return const SizedBox.shrink();
    }

    final contacts = _contacts!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.contact_phone_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Key Contacts',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Quick access to school officials',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (contacts.headmasterName.isNotEmpty || contacts.headmasterPhone.isNotEmpty)
                  _buildContactTile(
                    title: 'Headmaster',
                    name: contacts.headmasterName,
                    phone: contacts.headmasterPhone,
                    icon: Icons.school_rounded,
                    color: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                if (contacts.sitcName.isNotEmpty || contacts.sitcPhone.isNotEmpty)
                  _buildContactTile(
                    title: 'SITC',
                    subtitle: 'System In-Charge',
                    name: contacts.sitcName,
                    phone: contacts.sitcPhone,
                    icon: Icons.computer_rounded,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                if (contacts.ptaPresidentName.isNotEmpty || contacts.ptaPresidentPhone.isNotEmpty)
                  _buildContactTile(
                    title: 'PTA President',
                    name: contacts.ptaPresidentName,
                    phone: contacts.ptaPresidentPhone,
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF9333EA),
                    bgColor: const Color(0xFFFAF5FF),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required String title,
    String? subtitle,
    required String name,
    required String phone,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name.isNotEmpty ? name : 'Not Specified',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _makeCall(phone),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.call_rounded, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
