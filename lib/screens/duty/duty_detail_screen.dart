import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/duty_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';
import 'package:intl/intl.dart';

class DutyDetailScreen extends StatefulWidget {
  final String dutyId;
  
  const DutyDetailScreen({super.key, required this.dutyId});

  @override
  State<DutyDetailScreen> createState() => _DutyDetailScreenState();
}

class _DutyDetailScreenState extends State<DutyDetailScreen> {
  bool _isLoading = false;

  void _confirmDuty() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
      PopupNotification.showSuccess(context, 'Duty confirmed successfully');
      Navigator.pop(context);
    });
  }

  void _cancelDuty() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Duty'),
        content: const Text('Are you sure you want to cancel this duty? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              Future.delayed(const Duration(seconds: 1), () {
                setState(() => _isLoading = false);
                PopupNotification.showSuccess(context, 'Duty cancelled successfully');
                Navigator.pop(context);
              });
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Duty Details',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          final duty = state.duties.duties.firstWhere(
            (d) => d.id == widget.dutyId,
            orElse: () => throw Exception('Duty not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Duty Status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        duty.status == 'confirmed' ? Colors.green : Colors.orange,
                        (duty.status == 'confirmed' ? Colors.green : Colors.orange).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        duty.status == 'confirmed' ? Icons.check_circle : Icons.pending,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        duty.status == 'confirmed' ? 'Confirmed' : 'Pending Confirmation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Duty Information
                _buildInfoCard(
                  icon: Icons.assignment_outlined,
                  title: 'Duty Type',
                  value: duty.dutyTypeLabel,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: DateFormat('EEEE, MMMM d, yyyy').format(duty.date),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.access_time,
                  title: 'Shift',
                  value: duty.shiftLabel,
                ),
                if (duty.location != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Location',
                    value: duty.location!,
                  ),
                ],
                if (duty.className != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.school,
                    title: 'Class/Event',
                    value: duty.className!,
                  ),
                ],
                if (duty.remarks != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.note_outlined,
                    title: 'Remarks',
                    value: duty.remarks!,
                  ),
                ],
                const SizedBox(height: 24),
                // Action Buttons
                if (duty.status == 'assigned') ...[
                  CustomButton(
                    text: 'Confirm Duty',
                    onPressed: _confirmDuty,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Cancel Duty',
                    onPressed: _cancelDuty,
                    isOutlined: true,
                    color: Colors.red,
                  ),
                ] else if (duty.status == 'confirmed') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You have confirmed this duty. Please report on time.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}