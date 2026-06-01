import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_drawer.dart';
import 'package:school_management/widgets/dashboard/admin_dashboard.dart';
import 'package:school_management/widgets/dashboard/staff_dashboard.dart';
import 'package:school_management/widgets/dashboard/parent_dashboard.dart';
import 'package:school_management/hooks/use_socket.dart';
import 'package:school_management/services/socket_service.dart';
import 'package:school_management/actions/auth_actions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SocketService? _socketService;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSocket();
  }

  void _initSocket() {
    try {
      _socketService = UseSocket.getService(context);
      setState(() {
        _isConnected = _socketService?.isConnected ?? false;
      });
    } catch (e) {
      print('Socket service not yet available: $e');
    }
  }

  Future<void> _logout() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    _socketService?.disconnect();
    await store.dispatch(logoutThunk(LogoutAction()));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String>(
      converter: (store) => store.state.auth.user?.role ?? 'parent',
      builder: (context, userRole) {
        return Scaffold(
          key: _scaffoldKey,
          appBar: CustomAppBar(
            title: 'Dashboard',
            onMenuPressed: () {
              if (_scaffoldKey.currentState?.isDrawerOpen == false) {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
          ),
          drawer: CustomDrawer(onLogout: _logout),
          body: _buildDashboard(userRole),
        );
      },
    );
  }

  Widget _buildDashboard(String role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'staff':
        return const StaffDashboard();
      default:
        return const ParentDashboard();
    }
  }
}