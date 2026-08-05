import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/department.dart';
import '../employees/employee_list_view.dart';

class DepartmentManagementPage extends StatefulWidget {
  final bool isReadOnly;
  final String? filterDepartmentId;

  const DepartmentManagementPage({
    super.key,
    this.isReadOnly = false,
    this.filterDepartmentId,
  });

  @override
  State<DepartmentManagementPage> createState() =>
      _DepartmentManagementPageState();
}

class _DepartmentManagementPageState extends State<DepartmentManagementPage> {
  final TextEditingController _deptController = TextEditingController();

  @override
  void dispose() {
    _deptController.dispose();
    super.dispose();
  }

  void _showAddDeptDialog(BuildContext context) {
    _deptController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Department'),
        content: TextFormField(
          controller: _deptController,
          decoration: const InputDecoration(
              labelText: 'Department Name',
              hintText: 'e.g. Finance & Accounting'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_deptController.text.trim().isEmpty) return;
              final api = Provider.of<ApiService>(context, listen: false);
              final dept =
                  await api.createDepartment(_deptController.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                if (dept != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Successfully created department'),
                      backgroundColor: Colors.green));
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          api.errorMessage ?? 'Failed to create department'),
                      backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('Add Department'),
          ),
        ],
      ),
    );
  }

  void _showEditDeptDialog(BuildContext context, Department dept) {
    _deptController.text = dept.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Department Name'),
        content: TextFormField(
          controller: _deptController,
          decoration: const InputDecoration(labelText: 'Department Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_deptController.text.trim().isEmpty) return;
              final api = Provider.of<ApiService>(context, listen: false);
              final updated = await api.updateDepartment(
                  dept.id, _deptController.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                if (updated != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Successfully renamed department'),
                      backgroundColor: Colors.green));
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          api.errorMessage ?? 'Failed to rename department'),
                      backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _toggleDeptStatus(
      BuildContext context, Department dept, bool isActive) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final success = await api.toggleDepartmentStatus(dept.id, isActive);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Department ${isActive ? "activated" : "deactivated"} successfully'),
            backgroundColor: Colors.green));
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(api.errorMessage ?? 'Failed to change status'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (!widget.isReadOnly)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
                onPressed: () => _showAddDeptDialog(context),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Department>>(
        future: api.fetchDepartments(activeOnly: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var depts = snapshot.data ?? [];
          if (widget.filterDepartmentId != null) {
            depts =
                depts.where((d) => d.id == widget.filterDepartmentId).toList();
          }

          return depts.isEmpty
              ? const Center(child: Text('No departments found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: [
                      const DataColumn(
                          label: Text('Department Name',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataColumn(
                          label: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataColumn(
                          label: Text('Created Date',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      if (!widget.isReadOnly)
                        const DataColumn(
                            label: Text('Actions',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: depts.map((dept) {
                      return DataRow(
                          onSelectChanged: (_) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EmployeeListView(
                                  initialDepartmentId: dept.id,
                                  initialDepartmentName: dept.name,
                                ),
                              ),
                            );
                          },
                          color: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                            return dept.isActive
                                ? null
                                : Colors.grey.withOpacity(0.1);
                          }),
                          cells: [
                            DataCell(Text(dept.name,
                                style: TextStyle(
                                    color: dept.isActive
                                        ? Colors.blue
                                        : Colors.grey,
                                    decoration: dept.isActive
                                        ? TextDecoration.underline
                                        : TextDecoration.none))),
                            DataCell(Text(
                              dept.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  color:
                                      dept.isActive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(dept.createdAt != null
                                ? dept.createdAt!.split("T")[0]
                                : "N/A")),
                            if (!widget.isReadOnly)
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: dept.isActive,
                                    onChanged: (val) =>
                                        _toggleDeptStatus(context, dept, val),
                                    activeColor: Colors.green,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.blue),
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        _showEditDeptDialog(context, dept),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ))
                          ]);
                    }).toList(),
                  ),
                );
        },
      ),
    );
  }
}
