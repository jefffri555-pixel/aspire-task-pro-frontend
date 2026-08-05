import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/project.dart';
import '../../models/user.dart';
import '../../models/department.dart';
import '../../services/api_service.dart';

class ProjectFormView extends StatefulWidget {
  final Project? project;
  const ProjectFormView({super.key, this.project});

  @override
  State<ProjectFormView> createState() => _ProjectFormViewState();
}

class _ProjectFormViewState extends State<ProjectFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();

  String _priority = 'medium';
  String? _selectedDeptId;
  String? _selectedManagerId;
  String? _selectedTLId;
  List<String> _selectedEmployeeIds = [];
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));

  bool get isEditMode => widget.project != null;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      final p = widget.project!;
      _nameController.text = p.name;
      _clientController.text = p.clientName;
      _priority = p.priority;
      _selectedDeptId = p.assignedTeamId;
      _selectedManagerId = p.managerId;
      _selectedTLId = p.teamLeaderId;
      _selectedEmployeeIds = p.assignedEmployees.map((e) => e.id).toList();
      _startDate = DateTime.tryParse(p.startDate) ?? DateTime.now();
      _dueDate = DateTime.tryParse(p.dueDate) ??
          DateTime.now().add(const Duration(days: 14));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDeptId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select an assigned department/team.'),
              backgroundColor: Colors.redAccent),
        );
        return;
      }

      final api = Provider.of<ApiService>(context, listen: false);
      final Map<String, dynamic> projectData = {
        'name': _nameController.text.trim(),
        'client_name': _clientController.text.trim(),
        'priority': _priority,
        'assigned_team_id': _selectedDeptId,
        'manager_id': _selectedManagerId,
        'team_leader_id': _selectedTLId,
        'assigned_employee_ids': _selectedEmployeeIds,
        'start_date': _startDate.toString(),
        'due_date': _dueDate.toString(),
      };

      Project? project;
      if (isEditMode) {
        project = await api.updateProject(widget.project!.id, projectData);
      } else {
        project = await api.createProject(projectData);
      }

      if (project != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode
                ? 'Project updated successfully!'
                : 'Project created successfully!'),
            backgroundColor: AspireColors.accent,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showStaffSelector(BuildContext context, List<User> staff) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Project Staff Team'),
              content: SizedBox(
                width: 400,
                height: 350,
                child: ListView.builder(
                  itemCount: staff.length,
                  itemBuilder: (context, idx) {
                    final u = staff[idx];
                    final isChecked = _selectedEmployeeIds.contains(u.id);
                    return CheckboxListTile(
                      title: Text(u.name),
                      subtitle: Text(u.designation),
                      value: isChecked,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedEmployeeIds.add(u.id);
                          } else {
                            _selectedEmployeeIds.remove(u.id);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = Provider.of<ApiService>(context);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEditMode ? 'Edit Project parameters' : 'Create New Project'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          api.fetchDepartments(activeOnly: true),
          api.fetchUsers(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final depts = (snapshot.data?[0] as List<Department>?) ?? [];
          final users = (snapshot.data?[1] as List<User>?) ?? [];

          final managers = users
              .where((u) => u.role == 'manager' || u.role == 'admin')
              .toList();
          final tls = users.where((u) => u.role == 'team_leader').toList();
          final staff = users.where((u) => u.role == 'staff').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Define Project parameters',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      // Project Name input
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter project name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Client Name input
                      TextFormField(
                        controller: _clientController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter client name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Assigned Team (Department dropdown)
                      DropdownButtonFormField<String>(
                        value: _selectedDeptId,
                        decoration: const InputDecoration(
                          labelText: 'Assign Department Team',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        items: depts.map((d) {
                          return DropdownMenuItem(
                              value: d.id, child: Text(d.name));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDeptId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Assign Manager dropdown
                      DropdownButtonFormField<String?>(
                        value: _selectedManagerId,
                        decoration: const InputDecoration(
                          labelText: 'Project Manager',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.supervisor_account),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Unassigned (None)')),
                          ...managers.map((m) => DropdownMenuItem(
                              value: m.id, child: Text(m.name))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedManagerId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Assign Team Leader dropdown
                      DropdownButtonFormField<String?>(
                        value: _selectedTLId,
                        decoration: const InputDecoration(
                          labelText: 'Team Leader',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_pin),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Unassigned (None)')),
                          ...tls.map((t) => DropdownMenuItem(
                              value: t.id, child: Text(t.name))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTLId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Assigned Employees Tags
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Assigned Staff Team',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Assign Staff'),
                            onPressed: () => _showStaffSelector(context, staff),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _selectedEmployeeIds.isEmpty
                          ? const Text('No staff members assigned.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _selectedEmployeeIds.map((uid) {
                                final u = staff.firstWhere(
                                    (usr) => usr.id == uid,
                                    orElse: () => User(
                                        id: uid,
                                        employeeId: '',
                                        name: 'Unknown',
                                        email: '',
                                        phone: '',
                                        role: 'staff',
                                        designation: '',
                                        performanceScore: 100.0));
                                return Chip(
                                  label: Text(u.name,
                                      style: const TextStyle(fontSize: 12)),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedEmployeeIds.remove(uid);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 16),
                      // Priority dropdown
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority Level',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.priority_high),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(
                              value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _priority = val ?? 'medium';
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Start Date picker
                      ListTile(
                        title: const Text('Start Schedule'),
                        subtitle:
                            Text('${_startDate.toLocal()}'.substring(0, 10)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Due Date picker
                      ListTile(
                        title: const Text('Target Deadline'),
                        subtitle:
                            Text('${_dueDate.toLocal()}'.substring(0, 10)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: _startDate,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _dueDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      // Submit Button
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AspireColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                            isEditMode ? 'Save Changes' : 'Launch Project',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
