import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import 'attendance_view.dart';
import 'admin_attendance_dashboard.dart';
import 'attendance_history_view.dart';
import 'attendance_settings_page.dart';
import 'requests/attendance_requests_view.dart';
import 'admin_regularization_dashboard.dart';
import 'holiday_calendar_view.dart';

class AttendanceHubView extends StatefulWidget {
  const AttendanceHubView({super.key});

  @override
  State<AttendanceHubView> createState() => _AttendanceHubViewState();
}

class _AttendanceHubViewState extends State<AttendanceHubView> {
  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<ApiService>(context, listen: false).currentUser?.role ?? 'staff';
    final isAdminOrManager = ['admin', 'super_admin', 'manager', 'managing_director'].contains(userRole);

    final tabs = <Widget>[
      const Tab(text: 'My Attendance', icon: Icon(Icons.person)),
    ];
    final tabViews = <Widget>[
      const AttendanceView(),
    ];

    if (isAdminOrManager) {
      tabs.add(const Tab(text: 'Team Dashboard', icon: Icon(Icons.dashboard)));
      tabViews.add(const AdminAttendanceDashboard());
      
      tabs.add(const Tab(text: 'Team Corrections', icon: Icon(Icons.edit_calendar)));
      tabViews.add(const AdminRegularizationDashboard());

      tabs.add(const Tab(text: 'Settings', icon: Icon(Icons.settings)));
      tabViews.add(const AttendanceSettingsPage());
    }

    tabs.add(const Tab(text: 'Requests', icon: Icon(Icons.assignment)));
    tabViews.add(const AttendanceRequestsView());

    tabs.add(const Tab(text: 'History', icon: Icon(Icons.history)));
    tabViews.add(const AttendanceHistoryView());

    tabs.add(const Tab(text: 'Calendar', icon: Icon(Icons.event)));
    tabViews.add(const HolidayCalendarView());

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attendance'),
          bottom: TabBar(
            indicatorColor: AspireColors.primary,
            labelColor: AspireColors.primary,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: tabViews,
        ),
      ),
    );
  }
}
