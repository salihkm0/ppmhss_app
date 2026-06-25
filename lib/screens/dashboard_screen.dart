import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_drawer.dart';
import 'package:school_management/widgets/dashboard/admin_dashboard.dart';
import 'package:school_management/screens/staff/staff_shell.dart';
import 'package:school_management/screens/parent/parent_shell.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSocket();
  }

  void _initSocket() {
    try {
      _socketService = UseSocket.getService(context);
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
        // Staff & Parent get a bottom-nav shell (no drawer)
        if (userRole == 'staff') return const StaffShell();
        if (userRole == 'parent') return const ParentShell();

        // Admin keeps the classic drawer layout
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
          body: const AdminDashboard(),
        );
      },
    );
  }
}
