import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/colors.dart';
import '../../../models/leave_request.dart';
import '../../../services/api_service.dart';
import 'create_request_view.dart';
import 'request_details_view.dart';

class AttendanceRequestsView extends StatefulWidget {
  const AttendanceRequestsView({super.key});

  @override
  State<AttendanceRequestsView> createState() => _AttendanceRequestsViewState();
}

class _AttendanceRequestsViewState extends State<AttendanceRequestsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<LeaveRequest> _myRequests = [];
  List<LeaveRequest> _teamRequests = [];
  
  bool _canApprove = false;

  @override
  void initState() {
    super.initState();
    final userRole = Provider.of<ApiService>(context, listen: false).currentUser?.role ?? 'staff';
    _canApprove = ['admin', 'super_admin', 'manager', 'managing_director', 'team_leader'].contains(userRole);
    
    _tabController = TabController(length: _canApprove ? 2 : 1, vsync: this);
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    final myReqs = await apiService.getLeaveRequests(userId: apiService.currentUser?.id);
    List<LeaveRequest> teamReqs = [];
    if (_canApprove) {
      teamReqs = await apiService.getLeaveRequests();
      // Filter out our own from team requests just for clean UI
      teamReqs = teamReqs.where((r) => r.userId != apiService.currentUser?.id).toList();
    }

    setState(() {
      _myRequests = myReqs;
      _teamRequests = teamReqs;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.orange;
    }
  }

  Widget _buildRequestCard(LeaveRequest req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(req.leaveType, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (req.employeeName != null) Text('Employee: ${req.employeeName}'),
            Text('Dates: ${req.startDate} to ${req.endDate}'),
            Text('Status: ${req.status.toUpperCase()}', style: TextStyle(color: _getStatusColor(req.status), fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RequestDetailsView(request: req)),
          );
          if (refresh == true) {
            _loadRequests();
          }
        },
      ),
    );
  }

  Widget _buildList(List<LeaveRequest> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text('No requests found'));
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (ctx, i) => _buildRequestCard(requests[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AspireColors.primary,
          labelColor: AspireColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            const Tab(text: 'My Requests'),
            if (_canApprove) const Tab(text: 'Team Requests'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_myRequests),
              if (_canApprove) _buildList(_teamRequests),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AspireColors.primary,
        onPressed: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRequestView()),
          );
          if (refresh == true) _loadRequests();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
