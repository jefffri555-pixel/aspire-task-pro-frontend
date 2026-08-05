import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import 'employee_task_history_page.dart';

class EmployeeListView extends StatefulWidget {
  final String? initialDepartmentId;
  final String? initialDepartmentName;
  final bool isReadOnly;

  const EmployeeListView({
    super.key,
    this.initialDepartmentId,
    this.initialDepartmentName,
    this.isReadOnly = false,
  });

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();

  String _role = 'staff';
  String? _selectedDeptId;

  String? _filterDepartmentId;
  String? _filterDepartmentName;

  @override
  void initState() {
    super.initState();
    _filterDepartmentId = widget.initialDepartmentId;
    _filterDepartmentName = widget.initialDepartmentName;
  }

  final List<Map<String, String>> _depts = [
    {'id': 'dept_sales', 'name': 'Sales & Marketing'},
    {'id': 'dept_ops', 'name': 'Operations & Bookings'},
    {'id': 'dept_admin', 'name': 'Finance & Administration'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  void _addEmployeeDialog(BuildContext context) {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _designationController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email')),
                TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone')),
                TextField(
                    controller: _designationController,
                    decoration:
                        const InputDecoration(labelText: 'Designation')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                        value: 'team_leader', child: Text('Team Leader')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _role = val;
                      });
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedDeptId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: _depts.map((d) {
                    return DropdownMenuItem(
                        value: d['id'], child: Text(d['name']!));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDeptId = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final api = Provider.of<ApiService>(context, listen: false);
                await api.createUser({
                  'name': _nameController.text,
                  'email': _emailController.text,
                  'phone': _phoneController.text,
                  'designation': _designationController.text,
                  'role': _role,
                  'department_id': _selectedDeptId,
                });
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Register'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = Provider.of<ApiService>(context);
    final currentUser = api.currentUser;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_filterDepartmentName != null
            ? 'Employees — $_filterDepartmentName'
            : 'Employees Registry'),
        actions: [
          if (currentUser?.role == 'manager')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => _addEmployeeDialog(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add Staff'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_filterDepartmentName != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Chip(
                    label: Text('Department: $_filterDepartmentName'),
                    deleteIcon: widget.isReadOnly
                        ? null
                        : const Icon(Icons.close, size: 18),
                    onDeleted: widget.isReadOnly
                        ? null
                        : () {
                            setState(() {
                              _filterDepartmentId = null;
                              _filterDepartmentName = null;
                            });
                          },
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<User>>(
              future: api.fetchUsers(departmentId: _filterDepartmentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snapshot.data ?? [];

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_filterDepartmentName != null
                            ? 'No employees found in $_filterDepartmentName.'
                            : 'No employees found.'),
                        if (_filterDepartmentName != null &&
                            !widget.isReadOnly) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filterDepartmentId = null;
                                _filterDepartmentName = null;
                              });
                            },
                            child: const Text('View All Employees'),
                          ),
                        ]
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final employee = list[index];

                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EmployeeTaskHistoryPage(
                                employeeId: employee.id,
                                employeeName: employee.name,
                                employeeCode: employee.employeeId,
                                designation: employee.designation,
                                departmentId: employee.departmentId,
                                departmentName: employee.departmentName,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AspireColors.primary.withOpacity(0.1),
                            child: Text(
                                employee.name.substring(0, 1).toUpperCase()),
                          ),
                          title: Text(employee.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${employee.designation} (${employee.employeeId})\nDept: ${employee.departmentName ?? "General"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Performance score pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: employee.performanceScore >= 90
                                      ? Colors.green.shade50.withOpacity(0.2)
                                      : Colors.amber.shade50.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${employee.performanceScore}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: employee.performanceScore >= 90
                                        ? Colors.green
                                        : Colors.amber.shade800,
                                  ),
                                ),
                              ),

                              // Delete button (Manager only)
                              if (currentUser?.role == 'manager' &&
                                  employee.id != currentUser?.id)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete employee'),
                                        content: Text(
                                            'Are you sure you want to delete employee record for ${employee.name}?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel')),
                                          ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              child: const Text('Remove')),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await api.deleteUser(employee.id);
                                      setState(() {});
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
