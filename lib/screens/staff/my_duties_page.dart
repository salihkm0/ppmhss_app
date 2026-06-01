import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:school_management/actions/duty_actions.dart';
import 'package:school_management/models/duty_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';

class MyDutiesPage extends StatefulWidget {
  const MyDutiesPage({super.key});

  @override
  State<MyDutiesPage> createState() => _MyDutiesPageState();
}

class _MyDutiesPageState extends State<MyDutiesPage> {
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(fetchMyDutiesThunk());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Duties'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StoreConnector<AppState, _DutyViewModel>(
        converter: (store) => _DutyViewModel(
          duties: store.state.duties.duties,
          isLoading: store.state.duties.isLoading,
          error: store.state.duties.error,
        ),
        builder: (context, vm) {
          if (vm.isLoading && vm.duties.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          if (vm.error != null && vm.duties.isEmpty) {
            return Center(
              child: CustomErrorWidget(message: vm.error!, onRetry: _loadData),
            );
          }

          final filtered = _filterType == 'all'
              ? vm.duties
              : vm.duties.where((d) => d.dutyType == _filterType).toList();

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryColor,
            child: Column(
              children: [
                _buildStats(vm.duties),
                _buildFilterChips(vm.duties),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildDutyCard(filtered[index]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats(List<DutyModel> duties) {
    final upcoming = duties.where((d) => d.date.isAfter(DateTime.now())).length;
    final completed = duties.where((d) => d.status == 'completed').length;
    final today = duties.where((d) {
      final now = DateTime.now();
      return d.date.year == now.year &&
          d.date.month == now.month &&
          d.date.day == now.day;
    }).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', duties.length.toString(), Icons.assignment),
          _buildStatItem('Today', today.toString(), Icons.today),
          _buildStatItem('Upcoming', upcoming.toString(), Icons.schedule),
          _buildStatItem('Completed', completed.toString(), Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildFilterChips(List<DutyModel> duties) {
    final types = ['all', ...duties.map((d) => d.dutyType).toSet()];
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = _filterType == type;
          return FilterChip(
            label: Text(type == 'all' ? 'All' : _dutyTypeLabel(type)),
            selected: isSelected,
            onSelected: (_) => setState(() => _filterType = type),
            backgroundColor: Colors.white,
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontSize: 12,
            ),
            side: BorderSide(color: Colors.grey[300]!),
          );
        },
      ),
    );
  }

  Widget _buildDutyCard(DutyModel duty) {
    final now = DateTime.now();
    final isToday = duty.date.year == now.year &&
        duty.date.month == now.month &&
        duty.date.day == now.day;
    final isPast = duty.date.isBefore(DateTime(now.year, now.month, now.day));

    Color statusColor;
    String statusLabel;
    if (duty.status == 'completed') {
      statusColor = Colors.green;
      statusLabel = 'Completed';
    } else if (isToday) {
      statusColor = Colors.orange;
      statusLabel = 'Today';
    } else if (isPast) {
      statusColor = Colors.grey;
      statusLabel = 'Past';
    } else {
      statusColor = Colors.blue;
      statusLabel = 'Upcoming';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left: date block
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(duty.date),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                  Text(
                    DateFormat('MMM').format(duty.date).toUpperCase(),
                    style: TextStyle(fontSize: 10, color: statusColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Middle: details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dutyTypeLabel(duty.dutyType),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        duty.shiftLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (duty.location != null && duty.location!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          duty.location!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                  if (duty.className != null && duty.className!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.class_, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          duty.className!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Right: status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _filterType == 'all' ? 'No Duties Assigned' : 'No $_filterType duties',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no duty assignments at the moment.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _dutyTypeLabel(String type) {
    switch (type) {
      case 'exam':        return 'Exam Duty';
      case 'invigilation': return 'Invigilation';
      case 'supervision': return 'Supervision';
      case 'sports':      return 'Sports Duty';
      case 'gate':        return 'Gate Duty';
      default:            return type[0].toUpperCase() + type.substring(1);
    }
  }
}

class _DutyViewModel {
  final List<DutyModel> duties;
  final bool isLoading;
  final String? error;

  _DutyViewModel({
    required this.duties,
    required this.isLoading,
    this.error,
  });
}
