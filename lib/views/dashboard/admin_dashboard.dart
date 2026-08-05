import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../models/dashboard_stats.dart';
import '../tasks/task_list_view.dart';
import '../employees/employee_list_view.dart';
import '../leads/lead_board_view.dart';
import '../reports/reports_view.dart';
import '../reports/reports_view.dart';
import '../../widgets/dashboard_components.dart';
import '../../widgets/premium_card.dart';

class AdminDashboard extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const AdminDashboard({
    super.key,
    this.onNavigate,
  });
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for CRUD form dialogs
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetPassController = TextEditingController();

  String _selectedRole = 'staff';
  String? _selectedDeptId;

  // List of departments with fallback matching
  List<Map<String, String>> _getDepts(bool isMock) {
    if (isMock) {
      return [
        {'id': 'dept_sales', 'name': 'Sales & Marketing'},
        {'id': 'dept_ops', 'name': 'Operations & Bookings'},
        {'id': 'dept_support', 'name': 'Customer Support'},
        {'id': 'dept_admin', 'name': 'Finance & Administration'},
      ];
    } else {
      return [
        {
          'id': 'c7b07384-c113-431a-a563-3f16223405b1',
          'name': 'Sales & Marketing'
        },
        {
          'id': 'c7b07384-c113-431a-a563-3f16223405b2',
          'name': 'Operations & Bookings'
        },
        {
          'id': 'c7b07384-c113-431a-a563-3f16223405b3',
          'name': 'Customer Support'
        },
        {
          'id': 'c7b07384-c113-431a-a563-3f16223405b4',
          'name': 'Finance & Administration'
        },
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    _resetPassController.dispose();
    super.dispose();
  }

  // --- CRUD DIALOGS ---

  void _showAddUserDialog(BuildContext context, bool isMock) {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _designationController.clear();
    _passwordController.clear();
    _selectedRole = 'staff';
    _selectedDeptId = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New User Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Full Name')),
                    TextField(
                        controller: _emailController,
                        decoration:
                            const InputDecoration(labelText: 'Email Address')),
                    TextField(
                        controller: _phoneController,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number')),
                    TextField(
                        controller: _designationController,
                        decoration:
                            const InputDecoration(labelText: 'Designation')),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                          labelText:
                              'Password (Optional - default password123)'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration:
                          const InputDecoration(labelText: 'System Role'),
                      items: const [
                        DropdownMenuItem(
                            value: 'admin', child: Text('Super Admin')),
                        DropdownMenuItem(
                            value: 'manager', child: Text('Manager')),
                        DropdownMenuItem(
                            value: 'team_leader', child: Text('Team Leader')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            _selectedRole = val;
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedDeptId,
                      decoration: const InputDecoration(
                          labelText: 'Department Assignment'),
                      items: _getDepts(isMock).map((d) {
                        return DropdownMenuItem(
                            value: d['id'], child: Text(d['name']!));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
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
                    final user = await api.createAdminUser({
                      'name': _nameController.text.trim(),
                      'email': _emailController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'designation': _designationController.text.trim(),
                      'password': _passwordController.text.isEmpty
                          ? null
                          : _passwordController.text,
                      'role': _selectedRole,
                      'department_id': _selectedDeptId,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      if (user != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Successfully created user: ${user.name}'),
                              backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  api.errorMessage ?? 'Failed to create user'),
                              backgroundColor: Colors.redAccent),
                        );
                      }
                      setState(() {});
                    }
                  },
                  child: const Text('Register User'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, User user, bool isMock) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _designationController.text = user.designation;
    _passwordController.clear();
    _selectedRole = user.role;
    _selectedDeptId = user.departmentId;

    // Verify selected department matches lists
    final depts = _getDepts(isMock);
    if (depts.every((d) => d['id'] != _selectedDeptId)) {
      _selectedDeptId = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit User: ${user.employeeId}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Full Name')),
                    TextField(
                        controller: _emailController,
                        decoration:
                            const InputDecoration(labelText: 'Email Address')),
                    TextField(
                        controller: _phoneController,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number')),
                    TextField(
                        controller: _designationController,
                        decoration:
                            const InputDecoration(labelText: 'Designation')),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                          labelText:
                              'New Password (leave blank to keep current)'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration:
                          const InputDecoration(labelText: 'System Role'),
                      items: const [
                        DropdownMenuItem(
                            value: 'admin', child: Text('Super Admin')),
                        DropdownMenuItem(
                            value: 'manager', child: Text('Manager')),
                        DropdownMenuItem(
                            value: 'team_leader', child: Text('Team Leader')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            _selectedRole = val;
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedDeptId,
                      decoration: const InputDecoration(
                          labelText: 'Department Assignment'),
                      items: depts.map((d) {
                        return DropdownMenuItem(
                            value: d['id'], child: Text(d['name']!));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
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
                    final updated = await api.updateAdminUser(user.id, {
                      'name': _nameController.text.trim(),
                      'email': _emailController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'designation': _designationController.text.trim(),
                      'password': _passwordController.text.isEmpty
                          ? null
                          : _passwordController.text,
                      'role': _selectedRole,
                      'department_id': _selectedDeptId,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      if (updated != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Successfully updated user profile'),
                              backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  api.errorMessage ?? 'Failed to update user'),
                              backgroundColor: Colors.redAccent),
                        );
                      }
                      setState(() {});
                    }
                  },
                  child: const Text('Save Changes'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showResetPasswordDialog(BuildContext context, User user) {
    _resetPassController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset Password for ${user.name}'),
          content: TextField(
            controller: _resetPassController,
            decoration: const InputDecoration(labelText: 'New Password'),
            obscureText: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_resetPassController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Password must be at least 6 characters long'),
                        backgroundColor: Colors.redAccent),
                  );
                  return;
                }

                final api = Provider.of<ApiService>(context, listen: false);
                final success = await api.adminResetPassword(
                    user.id, _resetPassController.text);

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password reset successfully'),
                          backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              api.errorMessage ?? 'Failed to reset password'),
                          backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Reset Password'),
            )
          ],
        );
      },
    );
  }

  // --- VIEWS ---

  Widget _buildOverviewTab(BuildContext context, bool isMock) {
    debugPrint('BUILDING SUPER ADMIN DASHBOARD');
    final api = Provider.of<ApiService>(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder<DashboardStats?>(
          future: api.fetchAdminDashboard(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              debugPrint('Admin Dashboard load error: ${snapshot.error}');
              return AspireDashboardErrorState(
                message: snapshot.error.toString(),
                onRetry: () => setState(() {}),
              );
            }

            final stats = snapshot.data;
            if (stats == null) {
              return const AspireDashboardEmptyState(
                  message: 'Failed to load system metrics');
            }

            final cards = stats.managerCards ?? {};

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspireWelcomeBanner(
                    greeting: 'Welcome',
                    userName: api.currentUser?.name ?? 'Admin',
                    role: 'Super Admin Control Center',
                  ),
                  const SizedBox(height: 24),
                  AspireDashboardGrid(
                    cards: [
                      AspireSummaryCard(
                        title: 'Total Users',
                        value: (cards['totalEmployees'] ?? 0).toString(),
                        icon: Icons.people_alt,
                        color: AspireDashboardColors.blue,
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                      AspireSummaryCard(
                        title: 'Total Tasks',
                        value: (cards['pendingTasksCount'] ?? 0).toString(),
                        icon: Icons.task_alt,
                        color: AspireDashboardColors.green,
                        onTap: () => widget.onNavigate?.call(1),
                      ),
                      AspireSummaryCard(
                        title: 'Database Status',
                        value: isMock ? 'Offline' : 'Online',
                        icon: isMock ? Icons.cloud_off : Icons.cloud_done,
                        color: isMock
                            ? AspireDashboardColors.orange
                            : AspireDashboardColors.green,
                        onTap: () => _tabController.animateTo(2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: api.fetchAdminStatistics(),
                    builder: (context, statsSnapshot) {
                      if (statsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()));
                      }

                      if (statsSnapshot.hasError) {
                        debugPrint(
                            'Admin Statistics load error: ${statsSnapshot.error}');
                        return AspireDashboardErrorState(
                          message: statsSnapshot.error.toString(),
                          onRetry: () => setState(() {}),
                        );
                      }

                      final analyticalStats = statsSnapshot.data ?? {};
                      final taskStats =
                          (analyticalStats['taskStatusStats'] as List?) ?? [];
                      final deptStats =
                          (analyticalStats['departmentStats'] as List?) ?? [];

                      return Column(
                        children: [
                          _buildBreakdownCard('Tasks Status Matrix', taskStats),
                          const SizedBox(height: 24),
                          _buildDeptStatsCard(
                              'Departments Load Distribution', deptStats),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(String title, List<dynamic> list) {
    if (list.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AspireDashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const AspireDashboardEmptyState(
              message: 'No breakdown data available.'),
        ],
      );
    }

    final cards = list.map((item) {
      final status = item['status']?.toString() ?? 'unknown';
      final count = item['count']?.toString() ?? '0';
      final String label = status.toUpperCase().replaceAll('_', ' ');

      Color color = AspireColors.getStatusColor(status);
      IconData icon = Icons.assignment;

      if (status.toLowerCase().contains('pending')) {
        color = AspireColors.warning;
        icon = Icons.hourglass_empty;
      } else if (status.toLowerCase().contains('progress')) {
        color = AspireColors.blue;
        icon = Icons.trending_up;
      } else if (status.toLowerCase().contains('review')) {
        color = AspireColors.warning;
        icon = Icons.visibility;
      } else if (status.toLowerCase().contains('completed')) {
        color = AspireColors.accent;
        icon = Icons.check_circle_outline;
      }

      return AspireSummaryCard(
        title: label,
        value: count,
        icon: icon,
        color: color,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AspireDashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AspireDashboardGrid(cards: cards),
      ],
    );
  }

  Widget _buildDeptStatsCard(String title, List<dynamic> list) {
    if (list.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AspireDashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const AspireDashboardEmptyState(
              message: 'No department stats available.'),
        ],
      );
    }

    final cards = list.map((item) {
      final deptName = item['department_name']?.toString() ?? 'General';
      final users = item['user_count']?.toString() ?? '0';
      final projects = item['project_count']?.toString() ?? '0';

      return PremiumCard(
        padding: const EdgeInsets.all(20),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    deptName,
                    style: const TextStyle(
                      color: AspireDashboardColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AspireDashboardColors.navy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.domain,
                      color: AspireDashboardColors.navy, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Employees',
                      style: TextStyle(
                        color: AspireDashboardColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      users,
                      style: const TextStyle(
                        color: AspireDashboardColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Projects',
                      style: TextStyle(
                        color: AspireDashboardColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      projects,
                      style: const TextStyle(
                        color: AspireDashboardColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AspireDashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AspireDashboardGrid(cards: cards),
      ],
    );
  }

  Widget _buildUsersDirectoryTab(BuildContext context, bool isMock) {
    final api = Provider.of<ApiService>(context);

    return Scaffold(
      body: FutureBuilder<List<User>>(
        future: api.fetchAdminUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return const Center(child: Text('No users accounts registered.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final account = list[index];
              final isCurrent = account.id == api.currentUser?.id;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: account.isAdmin
                        ? Colors.red.withOpacity(0.1)
                        : (account.isManager
                            ? Colors.purple.withOpacity(0.1)
                            : AspireColors.primary.withOpacity(0.1)),
                    child: Text(
                      account.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: account.isAdmin
                            ? Colors.red
                            : (account.isManager
                                ? Colors.purple
                                : AspireColors.primary),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(account.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isCurrent)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('YOU',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'Employee ID: ${account.employeeId} | Role: ${account.role.toUpperCase()}\n'
                    'Designation: ${account.designation} | Dept: ${account.departmentName ?? "None"}\n'
                    'Contact: ${account.email} / ${account.phone}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reset password key icon
                      IconButton(
                        icon: const Icon(Icons.vpn_key_outlined,
                            color: Colors.amber),
                        tooltip: 'Reset Password',
                        onPressed: () =>
                            _showResetPasswordDialog(context, account),
                      ),

                      // Edit profile icon
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        tooltip: 'Edit details',
                        onPressed: () =>
                            _showEditUserDialog(context, account, isMock),
                      ),

                      // Delete button (Disabled for logged-in admin self)
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: isCurrent ? Colors.grey : Colors.redAccent),
                        tooltip: isCurrent
                            ? 'You cannot delete yourself'
                            : 'Remove user',
                        onPressed: isCurrent
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete User Account'),
                                    content: Text(
                                        'Are you sure you want to completely remove user profile for ${account.name}? This action cannot be undone.'),
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
                                        child: const Text('Delete Profile'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final deleted =
                                      await api.deleteAdminUser(account.id);
                                  if (mounted) {
                                    if (deleted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Successfully deleted user'),
                                            backgroundColor: Colors.green),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(api.errorMessage ??
                                                'Failed to delete user'),
                                            backgroundColor: Colors.redAccent),
                                      );
                                    }
                                    setState(() {});
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AspireColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add_alt_1),
        onPressed: () => _showAddUserDialog(context, isMock),
      ),
    );
  }

  Widget _buildUtilitiesTab(BuildContext context, bool isMock) {
    final theme = Theme.of(context);
    final api = Provider.of<ApiService>(context);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text('Administrative Settings & Diagnostics',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns, color: Colors.blue),
                  title: const Text('Server Connection Mode'),
                  subtitle: Text(isMock
                      ? 'Fallback Offline Demo Mode'
                      : 'Connected to PostgreSQL Production Database'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.red),
                  title: const Text('Current Session Account'),
                  subtitle: Text(
                      '${api.currentUser?.name} (${api.currentUser?.email})'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: const Text('Aspire Engine Version'),
                  subtitle: const Text('v2.0.0-SuperAdminPatch'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final isMock = api.isUsingMockFallback;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AspireColors.secondary,
            labelColor: AspireColors.secondary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.people_outline), text: 'Users Directory'),
              Tab(
                  icon: Icon(Icons.settings_applications_outlined),
                  text: 'Utilities'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, isMock),
          _buildUsersDirectoryTab(context, isMock),
          _buildUtilitiesTab(context, isMock),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title is currently under development.',
            style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
