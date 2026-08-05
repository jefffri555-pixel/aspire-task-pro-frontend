import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../models/lead.dart';
import '../../models/user.dart';

class LeadBoardView extends StatefulWidget {
  const LeadBoardView({super.key});

  @override
  State<LeadBoardView> createState() => _LeadBoardViewState();
}

class _EmployeeDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const _EmployeeDropdown(
      {required this.initialValue, required this.onChanged});

  @override
  State<_EmployeeDropdown> createState() => _EmployeeDropdownState();
}

class _EmployeeDropdownState extends State<_EmployeeDropdown> {
  String? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context, listen: false);
    return FutureBuilder<List<User>>(
      future: api.fetchUsers(),
      builder: (context, snapshot) {
        final staff =
            (snapshot.data ?? []).where((u) => u.role == 'staff').toList();

        return DropdownButtonFormField<String>(
          value: _currentValue,
          decoration: const InputDecoration(
              labelText: 'Assign Staff Executive',
              border: OutlineInputBorder()),
          items: staff.map((s) {
            return DropdownMenuItem(value: s.id, child: Text(s.name));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _currentValue = val;
            });
            widget.onChanged(val);
          },
        );
      },
    );
  }
}

class _LeadBoardViewState extends State<LeadBoardView> {
  final _leadNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _destinationController = TextEditingController();
  final _packageController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  final _followupController = TextEditingController();

  String _source = 'Website Enquiry';
  String? _assignedStaffId;

  // Search & Filter State
  String _searchQuery = '';
  String _filterSource = '';
  String? _filterStaffId;

  final List<String> _sources = [
    'Website Enquiry',
    'Instagram Ads',
    'Facebook Lead',
    'Walk-in Client',
    'Referral Partner',
  ];

  final List<Map<String, String>> _statusColumns = [
    {'id': 'new_lead', 'name': 'New Lead'},
    {'id': 'contacted', 'name': 'Contacted'},
    {'id': 'follow_up', 'name': 'Follow Up'},
    {'id': 'interested', 'name': 'Interested'},
    {'id': 'not_interested', 'name': 'Not Interested'},
    {'id': 'booking_confirmed', 'name': 'Booking Confirmed'},
  ];

  @override
  void dispose() {
    _leadNameController.dispose();
    _mobileController.dispose();
    _destinationController.dispose();
    _packageController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    _followupController.dispose();
    super.dispose();
  }

  Color _getStatusIndicatorColor(String status) {
    switch (status) {
      case 'new_lead':
        return Colors.blue;
      case 'contacted':
        return Colors.cyan;
      case 'follow_up':
        return Colors.amber;
      case 'interested':
        return Colors.indigo;
      case 'not_interested':
        return Colors.grey;
      case 'booking_confirmed':
        return AspireColors.accent;
      default:
        return Colors.blueGrey;
    }
  }

  void _createNewLeadDialog() {
    _leadNameController.clear();
    _mobileController.clear();
    _destinationController.clear();
    _packageController.clear();
    _budgetController.clear();
    _notesController.clear();
    _assignedStaffId = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Sales Lead'),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: _leadNameController,
                      decoration:
                          const InputDecoration(labelText: 'Lead Client Name')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                          labelText: 'Contact Phone Number')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                          labelText: 'Holiday Destination')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _packageController,
                      decoration: const InputDecoration(
                          labelText: 'Holiday Package Interest')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                          labelText: 'Client Budget (\$)')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _source,
                    decoration: const InputDecoration(
                        labelText: 'Lead Acquisition Source'),
                    items: _sources
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _source = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _EmployeeDropdown(
                    initialValue: _assignedStaffId,
                    onChanged: (val) {
                      _assignedStaffId = val;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Initial Discussion Notes')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final api = Provider.of<ApiService>(context, listen: false);
                await api.createLead({
                  'lead_name': _leadNameController.text.trim(),
                  'mobile_number': _mobileController.text.trim(),
                  'destination': _destinationController.text.trim(),
                  'package_interested': _packageController.text.trim(),
                  'budget': double.tryParse(_budgetController.text) ?? 0.00,
                  'source': _source,
                  'assigned_staff_id': _assignedStaffId,
                  'notes': _notesController.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Add Lead'),
            )
          ],
        );
      },
    );
  }

  void _showLeadDetailModal(Lead lead) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final detailLead = await api.fetchLeadById(lead.id);

    if (detailLead == null || !mounted) return;

    _followupController.clear();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(detailLead.leadName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusIndicatorColor(detailLead.status)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    detailLead.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: _getStatusIndicatorColor(detailLead.status),
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Holiday Details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildLeadField('Phone', detailLead.mobileNumber),
                    _buildLeadField('Destination', detailLead.destination),
                    _buildLeadField(
                        'Interested In', detailLead.packageInterested),
                    _buildLeadField('Budget', '\$${detailLead.budget}'),
                    _buildLeadField('Assigned to',
                        detailLead.assignedStaffName ?? 'Unassigned'),
                    const SizedBox(height: 16),

                    // Pipeline progression
                    const Text('Change Lead Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statusColumns.map((col) {
                        return ActionChip(
                          label: Text(col['name']!,
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: detailLead.status == col['id']
                              ? _getStatusIndicatorColor(col['id']!)
                                  .withOpacity(0.2)
                              : null,
                          onPressed: () async {
                            final updated = await api.updateLead(
                                detailLead.id, {'status': col['id']});
                            if (updated != null) {
                              setModalState(() {
                                Navigator.pop(context);
                                _showLeadDetailModal(updated);
                              });
                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Log interaction followups
                    Text('Follow-Up Logs', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _followupController,
                            decoration: const InputDecoration(
                                hintText: 'Log conversation summary...',
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check,
                              color: AspireColors.accent),
                          onPressed: () async {
                            final text = _followupController.text.trim();
                            if (text.isEmpty) return;
                            final f =
                                await api.addFollowUp(detailLead.id, text);
                            if (f != null) {
                              _followupController.clear();
                              Navigator.pop(context);
                              _showLeadDetailModal(detailLead);
                              setState(() {});
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List timeline
                    detailLead.followUps.isEmpty
                        ? const Text('No follow up activity logged yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 12))
                        : Column(
                            children: detailLead.followUps.map((f) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.arrow_right,
                                        color: Colors.grey),
                                    Expanded(
                                      child: Text(
                                        '${f.notes} (${f.followUpDate.substring(0, 10)})',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          );
        });
      },
    );
  }

  Widget _buildLeadField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 13),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSummary(List<Lead> leads) {
    final total = leads.length;
    final converted =
        leads.where((l) => l.status == 'booking_confirmed').length;
    final followUp = leads.where((l) => l.status == 'follow_up').length;
    final rate =
        total > 0 ? (converted / total * 100).toStringAsFixed(1) : '0.0';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            _buildSummaryMetric('Total Leads', total.toString(),
                Icons.leaderboard, Colors.blue),
            _buildSummaryMetric('Bookings', converted.toString(),
                Icons.check_circle, Colors.green),
            _buildSummaryMetric('Follow-ups', followUp.toString(),
                Icons.hourglass_empty, Colors.amber),
            _buildSummaryMetric(
                'Conversion Rate', '$rate%', Icons.trending_up, Colors.indigo),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(
      String title, String val, IconData icon, Color color) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(val,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    final api = Provider.of<ApiService>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 40,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search client, destination...',
                prefixIcon: Icon(Icons.search, size: 18),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterSource.isEmpty ? null : _filterSource,
                hint:
                    const Text('Filter Source', style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All Sources')),
                  ..._sources
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (val) {
                  setState(() {
                    _filterSource = val ?? '';
                  });
                },
              ),
            ),
          ),
          SizedBox(
            height: 40,
            width: 200,
            child: FutureBuilder<List<User>>(
              future: api.fetchUsers(),
              builder: (context, snapshot) {
                final staff = (snapshot.data ?? [])
                    .where((u) => u.role == 'staff')
                    .toList();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _filterStaffId,
                      hint: const Text('Filter Executive',
                          style: TextStyle(fontSize: 13)),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Executives')),
                        ...staff.map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filterStaffId = val;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = Provider.of<ApiService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM - Holidays Lead Board',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _createNewLeadDialog,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add Lead'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AspireColors.accent,
                  foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Lead>>(
        future: api.fetchLeads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final leads = snapshot.data ?? [];

          // Perform local search/filtering
          final filteredLeads = leads.where((l) {
            final matchesSearch = _searchQuery.isEmpty ||
                l.leadName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                l.destination
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                l.source.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesSource =
                _filterSource.isEmpty || l.source == _filterSource;
            final matchesStaff =
                _filterStaffId == null || l.assignedStaffId == _filterStaffId;
            return matchesSearch && matchesSource && matchesStaff;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDashboardSummary(leads),
              _buildFilterPanel(context),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _statusColumns.map((col) {
                          final colLeads = filteredLeads
                              .where((l) => l.status == col['id'])
                              .toList();
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? AspireColors.darkCard
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          col['name']!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Text(colLeads.length.toString(),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: colLeads.length,
                                      itemBuilder: (context, index) {
                                        final lead = colLeads[index];
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          child: InkWell(
                                            onTap: () =>
                                                _showLeadDetailModal(lead),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(lead.leadName,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13)),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                      '${lead.destination} (\$${lead.budget})',
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                              fontSize: 11)),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                          'Src: ${lead.source}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 9,
                                                                  color: Colors
                                                                      .grey)),
                                                      const Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                          size: 10,
                                                          color: Colors.grey),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  } else {
                    return ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: _statusColumns.map((col) {
                        final colLeads = filteredLeads
                            .where((l) => l.status == col['id'])
                            .toList();
                        if (colLeads.isEmpty) return const SizedBox();

                        return ExpansionTile(
                          initiallyExpanded: true,
                          title: Text('${col['name']} (${colLeads.length})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          children: colLeads.map((lead) {
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              child: ListTile(
                                title: Text(lead.leadName),
                                subtitle: Text(
                                    'Destination: ${lead.destination} | Budget: \$${lead.budget}'),
                                onTap: () => _showLeadDetailModal(lead),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 14),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    );
                  }
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
