import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/duty_actions.dart';
import 'package:school_management/models/duty_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/utils/theme.dart';
import 'package:intl/intl.dart';

class DutyListScreen extends StatefulWidget {
  const DutyListScreen({super.key});

  @override
  State<DutyListScreen> createState() => _DutyListScreenState();
}

class _DutyListScreenState extends State<DutyListScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    // Don't load here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDuties();
  }

  void _loadDuties() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(FetchDutiesAction());
  }

  List<DutyModel> _filterDuties(List<DutyModel> duties) {
    final now = DateTime.now();
    switch (_filter) {
      case 'upcoming':
        return duties.where((d) => d.date.isAfter(now) || d.date.isAtSameMomentAs(now)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      case 'past':
        return duties.where((d) => d.date.isBefore(now)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      default:
        return duties.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Assigned';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Duties',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        onWillChange: (previous, next) {
          // Handle any state changes if needed
        },
        builder: (context, state) {
          final filteredDuties = _filterDuties(state.duties.duties);
          
          return Column(
            children: [
              // Filter Tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Upcoming', 'upcoming'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Past', 'past'),
                  ],
                ),
              ),
              // Stats Cards
              Container(
                margin: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard('Total', state.duties.duties.length, Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard('Upcoming', 
                      state.duties.duties.where((d) => d.date.isAfter(DateTime.now())).length, 
                      Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard('Completed',
                      state.duties.duties.where((d) => d.status == 'completed').length,
                      Colors.orange),
                  ],
                ),
              ),
              // Duty List
              Expanded(
                child: state.duties.isLoading && state.duties.duties.isEmpty
                  ? const LoadingWidget()
                  : filteredDuties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No duties found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredDuties.length,
                          itemBuilder: (context, index) {
                            final duty = filteredDuties[index];
                            final isUpcoming = duty.date.isAfter(DateTime.now());
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/duties/detail',
                                    arguments: duty.id,
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              duty.dutyTypeLabel,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(duty.status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusText(duty.status),
                                              style: TextStyle(
                                                color: _getStatusColor(duty.status),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('EEEE, MMM d, yyyy').format(duty.date),
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                          ),
                                          if (isUpcoming && duty.date.isAtSameMomentAs(DateTime.now()))
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'Today',
                                                  style: TextStyle(fontSize: 10, color: Colors.red),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                                          const SizedBox(width: 8),
                                          Text(
                                            duty.shiftLabel,
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                      if (duty.location != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                                            const SizedBox(width: 8),
                                            Text(
                                              duty.location!,
                                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}