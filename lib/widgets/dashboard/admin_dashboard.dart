import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:intl/intl.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/actions/dashboard_actions.dart';
import 'package:school_management/models/dashboard_model.dart';
import 'package:school_management/models/user_model.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/utils/formatters.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';
import 'package:school_management/services/socket_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _activeChartIndex = 0;
  bool _showRefreshIndicator = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(fetchAdminDashboardThunk());
  }

  void _setupSocketListeners() {
    final socketService = SocketService();

    socketService.addListener('dashboard:updated', (data) {
      if (mounted) {
        final store = StoreProvider.of<AppState>(context, listen: false);
        store.dispatch(UpdateDashboardStatsAction(stats: data));
        _showTemporaryRefresh();
      }
    });

    socketService.addListener('activity:created', (activity) {
      if (mounted) {
        final store = StoreProvider.of<AppState>(context, listen: false);
        store.dispatch(AddDashboardActivityAction(activity: activity));
      }
    });
  }

  void _showTemporaryRefresh() {
    setState(() {
      _showRefreshIndicator = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showRefreshIndicator = false;
        });
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _AdminDashboardViewModel>(
      onInit: (store) {
        _setupSocketListeners();
      },
      converter: (store) => _AdminDashboardViewModel(
        dashboardData: store.state.dashboard.adminData,
        isLoading: store.state.dashboard.isLoading,
        error: store.state.dashboard.error,
        lastUpdated: store.state.dashboard.lastUpdated,
        user: store.state.auth.user,
        isSocketConnected: store.state.socket.isConnected,
      ),
      builder: (context, vm) {
        if (vm.isLoading && vm.dashboardData == null) {
          return const Center(child: LoadingWidget());
        }

        if (vm.error != null && vm.dashboardData == null) {
          return Center(
            child: CustomErrorWidget(
              message: vm.error!,
              onRetry: () => _loadDashboardData(),
            ),
          );
        }

        final dashboard = vm.dashboardData;
        if (dashboard == null) {
          return Center(
            child: CustomErrorWidget(
              message: 'No dashboard data available',
              onRetry: () => _loadDashboardData(),
            ),
          );
        }

        final summary = dashboard.summary;

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                          vm.user, dashboard.academicYear, vm.lastUpdated),
                      const SizedBox(height: 20),
                      _buildStatsGrid(summary),
                      const SizedBox(height: 20),
                      _buildPerformanceCards(
                          summary, dashboard.examPerformance),
                      const SizedBox(height: 20),
                      _buildChartSection(dashboard),
                      const SizedBox(height: 20),
                      _buildDemographicsSection(dashboard),
                      const SizedBox(height: 20),
                      _buildTopClassesAndEvents(dashboard),
                      const SizedBox(height: 20),
                      _buildRecentActivities(dashboard.recentActivities),
                    ],
                  ),
                ),
              ),
            ),
            if (_showRefreshIndicator)
              Positioned(
                bottom: 16,
                right: 16,
                child: _buildRefreshToast(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
      UserModel? user, AcademicYearInfo? academicYear, String? lastUpdated) {
    final firstName = user?.name?.split(' ').first ?? 'Admin';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, $firstName! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (academicYear != null)
                      Text(
                        academicYear.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      "Here's what's happening with your school today.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 12, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  'Last updated: ${DateFormat('h:mm a').format(DateTime.parse(lastUpdated))}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdminDashboardSummary summary) {
    final stats = [
      {
        'title': 'Total Students',
        'value': summary.totalStudents,
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Total Staff',
        'value': summary.totalStaff,
        'icon': Icons.person,
        'color': Colors.green,
      },
      {
        'title': 'Total Classes',
        'value': summary.totalClasses,
        'icon': Icons.class_,
        'color': Colors.orange,
      },
      {
        'title': 'Active Exams',
        'value': summary.currentExams,
        'icon': Icons.assignment,
        'color': Colors.purple,
      },
      {
        'title': 'Attendance Rate',
        'value': summary.attendancePercentage.toStringAsFixed(1),
        'icon': Icons.check_circle,
        'color': Colors.teal,
        'suffix': '%',
      },
      {
        'title': 'A+ Students',
        'value': summary.fullAPlusCount,
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final value = stat['value'].toString();

        return _buildStatCard(
          title: stat['title'] as String,
          value: '$value${stat['suffix'] ?? ''}',
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCards(
      AdminDashboardSummary summary, ExamPerformance? examPerformance) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avg. Attendance',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.attendancePercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: summary.attendancePercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.attendanceToday} present today',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pass Percentage',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Icon(Icons.bar_chart, size: 14, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${examPerformance?.passPercentage.toStringAsFixed(1) ?? 0}%',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getTrendIcon(examPerformance?.trend ?? 'stable'),
                      size: 12,
                      color: _getTrendColor(examPerformance?.trend ?? 'stable'),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'vs last term',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${examPerformance?.topPerformers ?? 0} A+ students',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.remove;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildChartSection(AdminDashboardData dashboard) {
    final tabs = [
      {'title': 'Subject Performance', 'icon': Icons.bar_chart},
      {'title': 'Class Distribution', 'icon': Icons.pie_chart},
      {'title': 'Grade Distribution', 'icon': Icons.emoji_events},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = _activeChartIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChartTab(
                    title: tabs[index]['title'] as String,
                    icon: tabs[index]['icon'] as IconData,
                    isSelected: isSelected,
                    onTap: () => setState(() => _activeChartIndex = index),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: 280,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildChartContent(dashboard),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent(AdminDashboardData dashboard) {
    switch (_activeChartIndex) {
      case 0:
        return _buildSubjectPerformanceChart(dashboard.subjectPerformance);
      case 1:
        return _buildClassDistributionChart(dashboard.classDistribution);
      case 2:
        return _buildGradeDistributionChart(dashboard.gradeDistribution);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSubjectPerformanceChart(List<SubjectPerformance> subjects) {
    if (subjects.isEmpty) {
      return const Center(
        child: Text(
          'No subject performance data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final displaySubjects = subjects.take(6).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displaySubjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final subject = displaySubjects[index];
        final score = double.tryParse(subject.averageScore) ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subject.subjectName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${subject.averageScore}%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  score >= 75
                      ? Colors.green
                      : score >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
                minHeight: 6,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClassDistributionChart(List<ClassDistribution> classes) {
    if (classes.isEmpty) {
      return const Center(
        child: Text(
          'No class distribution data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final totalStudents =
        classes.fold<int>(0, (sum, c) => sum + c.studentCount);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final classItem = classes[index];
        final percentage = totalStudents > 0
            ? (classItem.studentCount / totalStudents) * 100
            : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  classItem.className,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${classItem.studentCount} students (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGradeDistributionChart(List<GradeDistribution> grades) {
    if (grades.isEmpty) {
      return const Center(
        child: Text(
          'No grade distribution data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final displayGrades = grades.where((g) => g.count > 0).toList();
    final total = displayGrades.fold<int>(0, (sum, g) => sum + g.count);
    final passCount = displayGrades
        .where((g) => !['F', 'D'].contains(g.grade))
        .fold<int>(0, (sum, g) => sum + g.count);
    final passPercentage = total > 0 ? (passCount / total) * 100 : 0;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayGrades.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final grade = displayGrades[index];
              final percentage = total > 0 ? (grade.count / total) * 100 : 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grade ${grade.grade}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${grade.count} students (${grade.percentage}%)',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getGradeColor(grade.grade),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Students Graded',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text('$total',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Pass Percentage',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text('${passPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return Colors.green;
      case 'A':
        return Colors.lightGreen;
      case 'B+':
        return Colors.teal;
      case 'B':
        return Colors.blue;
      case 'C+':
        return Colors.orange;
      case 'C':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  Widget _buildDemographicsSection(AdminDashboardData dashboard) {
    final gender = dashboard.demographics?.gender;
    final categories = dashboard.demographics?.category ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Gender Distribution',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                if (gender != null && (gender.male > 0 || gender.female > 0))
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildGenderItem('Male', gender.male, Colors.blue),
                        const SizedBox(height: 12),
                        _buildGenderItem('Female', gender.female, Colors.pink),
                        if (gender.other > 0) ...[
                          const SizedBox(height: 12),
                          _buildGenderItem(
                              'Other', gender.other, Colors.purple),
                        ],
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No gender data available',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Category Distribution',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                if (categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: categories.take(4).map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCategoryItem(category),
                        );
                      }).toList(),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No category data available',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final name = category['_id'] ?? 'Unknown';
    final count = category['count'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTopClassesAndEvents(AdminDashboardData dashboard) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Top Performing Classes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                if (dashboard.topClasses.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dashboard.topClasses.take(5).length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final classItem = dashboard.topClasses[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    classItem.className,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${classItem.studentCount} students',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${classItem.averagePercentage}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 3,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    widthFactor: (double.tryParse(
                                                classItem.averagePercentage) ??
                                            0) /
                                        100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No class performance data available',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUpcomingEvents(dashboard.upcomingEvents),
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents(List<UpcomingEvent> events) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          if (events.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.take(5).length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = events[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getEventPriorityColor(event.priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${event.type} • ${DateFormat('MMM d').format(event.date)}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getEventPriorityColor(event.priority)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${event.daysLeft}d left',
                          style: TextStyle(
                            fontSize: 10,
                            color: _getEventPriorityColor(event.priority),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No upcoming events',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }

  Color _getEventPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildRecentActivities(List<RecentActivity> activities) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Recent Activities',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (activities.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.take(10).length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getActivityTypeColor(activity.type)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getActivityIcon(activity.type),
                          size: 16,
                          color: _getActivityTypeColor(activity.type),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatTimeAgo(activity.timestamp),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.performedByRole ?? 'System',
                          style:
                              TextStyle(fontSize: 9, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.access_time, size: 32, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No recent activities',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'student_added':
        return Icons.person_add;
      case 'exam_created':
      case 'exam_published':
        return Icons.assignment;
      case 'attendance_marked':
        return Icons.check_circle;
      case 'duty_assigned':
        return Icons.work;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityTypeColor(String type) {
    switch (type) {
      case 'student_added':
        return Colors.green;
      case 'exam_created':
      case 'exam_published':
        return Colors.purple;
      case 'attendance_marked':
        return Colors.blue;
      case 'duty_assigned':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRefreshToast() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Dashboard updated',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ViewModel for the dashboard
class _AdminDashboardViewModel {
  final AdminDashboardData? dashboardData;
  final bool isLoading;
  final String? error;
  final String? lastUpdated;
  final UserModel? user;
  final bool isSocketConnected;

  _AdminDashboardViewModel({
    this.dashboardData,
    required this.isLoading,
    this.error,
    this.lastUpdated,
    this.user,
    required this.isSocketConnected,
  });
}
