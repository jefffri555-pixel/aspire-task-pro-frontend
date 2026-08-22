import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../widgets/aspire_logo.dart';
import 'auth/login_view.dart';
import 'dashboard/admin_dashboard.dart';
import 'dashboard/manager_dashboard.dart';
import 'dashboard/tl_dashboard.dart';
import 'dashboard/staff_dashboard.dart';
import 'tasks/task_list_view.dart';
import 'employees/employee_list_view.dart';
import 'admin/department_management_page.dart';
import 'reports/reports_view.dart';
import 'calendar/task_calendar_view.dart';
import 'attendance/attendance_view.dart';
import 'attendance/attendance_hub_view.dart';
import '../models/user.dart';

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;

  // Build the list of active screens based on user role
  List<Widget> _getScreens(User user) {
    final role = user.role;
    if (role == 'admin' || role == 'super_admin') {
      return [
        AdminDashboard(
          onNavigate: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        const TaskListView(),
        const EmployeeListView(),
        const DepartmentManagementPage(),
        const AttendanceHubView(),
        const ReportsView(),
      ];
    } else if (role == 'manager' || role == 'managing_director') {
      return [
        ManagerDashboard(
          onNavigate: (index) {
            if (!mounted) return;
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        const TaskListView(),
        const EmployeeListView(),
        const DepartmentManagementPage(),
        const TaskCalendarView(),
        const AttendanceHubView(),
        const ReportsView(),
      ];
    } else if (role == 'team_leader') {
      return [
        TLDashboard(
          onNavigate: (index) {
            if (!mounted) return;
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        const TaskListView(),
        DepartmentManagementPage(
          isReadOnly: true,
          filterDepartmentId: user.departmentId,
        ),
        const TaskCalendarView(),
        const AttendanceHubView(),
        const ReportsView(),
      ];
    } else if (role == 'staff') {
      return [
        StaffDashboard(
          onNavigate: (index) {
            if (!mounted) return;
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        const TaskListView(),
        const TaskCalendarView(),
        const AttendanceHubView(),
      ];
    } else {
      return [
        StaffDashboard(
          onNavigate: (index) {
            if (!mounted) return;
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        const TaskListView(),
        const TaskCalendarView(),
        const AttendanceHubView(),
      ];
    }
  }

  // Build navigation items
  List<NavigationDestination> _getNavDestinations(String role) {
    if (role == 'admin' || role == 'super_admin') {
      return const [
        NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin Hub',
        ),
        NavigationDestination(
          icon: Icon(Icons.task_outlined),
          selectedIcon: Icon(Icons.task),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Employees',
        ),
        NavigationDestination(
          icon: Icon(Icons.domain_outlined),
          selectedIcon: Icon(Icons.domain),
          label: 'Departments',
        ),
        NavigationDestination(
          icon: Icon(Icons.access_time_outlined),
          selectedIcon: Icon(Icons.access_time),
          label: 'Attendance',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Reports',
        ),
      ];
    } else if (role == 'manager' || role == 'managing_director') {
      return const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
        NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks'),
        NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Staff'),
        NavigationDestination(
            icon: Icon(Icons.domain_outlined),
            selectedIcon: Icon(Icons.domain),
            label: 'Departments'),
        NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar'),
        NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Attendance'),
        NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Reports'),
      ];
    } else if (role == 'team_leader') {
      return const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
        NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks'),
        NavigationDestination(
            icon: Icon(Icons.domain_outlined),
            selectedIcon: Icon(Icons.domain),
            label: 'My Department'),
        NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar'),
        NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Attendance'),
        NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Reports'),
      ];
    } else if (role == 'staff') {
      return const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
        NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'My Tasks'),
        NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar'),
        NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Attendance'),
      ];
    } else {
      return const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
        NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'My Tasks'),
        NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar'),
        NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Attendance'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final user = api.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final role = user.role;
    final screens = _getScreens(user);
    final destinations = _getNavDestinations(role);
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final myAppBar = AppBar(
          title: const AspireLogo(
            size: 32,
            showText: true,
            isDarkBackground: false,
          ),
          actions: [
            // Fallback banner indicator
            if (api.isUsingMockFallback)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Offline Demo Mode',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),

            // Theme toggler
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                AspireTaskProApp.of(context).toggleTheme();
              },
            ),

            // Profile chip or signout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                backgroundColor:
                    isDark ? AspireColors.darkBorder : AspireColors.lightBorder,
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                api.logout();
              },
            ),
          ],
        );

        if (isMobile) {
          return Scaffold(
            extendBody: true,
            appBar: myAppBar,
            body: SafeArea(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AspireColors.primary.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: NavigationBar(
                    height: 64,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (idx) {
                      setState(() {
                        _currentIndex = idx;
                      });
                    },
                    destinations: destinations.map((d) {
                      final isSelected =
                          destinations.indexOf(d) == _currentIndex;
                      return NavigationDestination(
                        icon: d.icon,
                        selectedIcon: isSelected
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AspireColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AspireColors.primary.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: IconTheme(
                                  data: const IconThemeData(
                                      color: Colors.white, size: 20),
                                  child: d.selectedIcon ?? d.icon,
                                ),
                              )
                            : d.icon,
                        label: d.label,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          appBar: myAppBar,
          body: Row(
            children: [
              // Desktop Sidebar Navigation
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (idx) {
                  setState(() {
                    _currentIndex = idx;
                  });
                },
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: const IconThemeData(color: Colors.white),
                unselectedIconTheme: IconThemeData(
                    color: isDark
                        ? AspireColors.darkTextSecondary
                        : AspireColors.lightTextSecondary),
                indicatorColor: AspireColors.primary,
                destinations: destinations.map((d) {
                  return NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  );
                }).toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1),

              // Active Dashboard Window
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
