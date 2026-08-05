import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../models/dashboard_stats.dart';
import '../../utils/file_download_helper.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  String _selectedReportType = 'employee';

  List<dynamic> _departments = [];
  String? _selectedDepartmentId;
  String _selectedDepartmentName = 'All Departments';
  bool _isLoadingDepartments = true;
  bool _isDownloadingPdf = false;
  bool _isDownloadingExcel = false;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final depts = await api.fetchReportDepartments();
    if (mounted) {
      setState(() {
        _departments = depts;
        _isLoadingDepartments = false;
      });
    }
  }

  String _safeReportFileName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return normalized.isEmpty ? 'all-departments' : normalized;
  }

  Future<void> _downloadPdfReport() async {
    if (_isDownloadingPdf) return;

    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      debugPrint('PDF DOWNLOAD CLICKED');
      debugPrint(
        'Department: $_selectedDepartmentId / '
        '$_selectedDepartmentName',
      );

      final apiService = Provider.of<ApiService>(context, listen: false);
      final bytes = await apiService.downloadDepartmentPdf(
        departmentId: _selectedDepartmentId,
      );

      final safeName = _safeReportFileName(_selectedDepartmentName);

      await saveBytesToDevice(
        bytes: bytes,
        fileName: '$safeName-performance-report.pdf',
        mimeType: 'application/pdf',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF report downloaded successfully'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('PDF DOWNLOAD ERROR: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to download PDF: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  Future<void> _downloadExcelReport() async {
    if (_isDownloadingExcel) return;

    setState(() {
      _isDownloadingExcel = true;
    });

    try {
      debugPrint('EXCEL DOWNLOAD CLICKED');
      debugPrint(
        'Department: $_selectedDepartmentId / '
        '$_selectedDepartmentName',
      );

      final apiService = Provider.of<ApiService>(context, listen: false);
      final bytes = await apiService.downloadDepartmentExcel(
        departmentId: _selectedDepartmentId,
      );

      final safeName = _safeReportFileName(_selectedDepartmentName);

      await saveBytesToDevice(
        bytes: bytes,
        fileName: '$safeName-performance-report.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel report downloaded successfully'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('EXCEL DOWNLOAD ERROR: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to download Excel: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingExcel = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final api = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics Center',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<DashboardStats?>(
        future: api.fetchDashboardStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data;
          final performers = stats?.topPerformers ?? [];
          final teamPerformance = stats?.teamPerformance ?? [];

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                'Export Corporate Deliverables',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select parameters and download complete worksheets for tasks inventories, lead pipelines, and staff performance indices.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_isLoadingDepartments)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: _selectedDepartmentId,
                  decoration: const InputDecoration(
                    labelText: 'Select Department Report Scope',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Departments'),
                    ),
                    ..._departments.map(
                      (department) => DropdownMenuItem<String>(
                        value: department['id'],
                        child: Text(department['name']),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value;
                      if (value == null) {
                        _selectedDepartmentName = 'All Departments';
                      } else {
                        _selectedDepartmentName = _departments
                            .firstWhere((item) => item['id'] == value)['name'];
                      }
                    });
                  },
                ),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 700 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    Card(
                      color: isDark
                          ? AspireColors.darkCard
                          : Colors.red.shade50.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.picture_as_pdf,
                                    color: Colors.red, size: 36),
                                const SizedBox(height: 12),
                                Text('Generate PDF Document',
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                const Text(
                                    'Download a detailed department-wise employee and task performance report.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text(
                                    'Selected Department:\n$_selectedDepartmentName',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  _isDownloadingPdf ? null : _downloadPdfReport,
                              icon: _isDownloadingPdf
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.download),
                              label: Text(_isDownloadingPdf
                                  ? 'Generating PDF...'
                                  : 'Download PDF'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                            )
                          ],
                        ),
                      ),
                    ),
                    Card(
                      color: isDark
                          ? AspireColors.darkCard
                          : Colors.green.shade50.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.table_chart,
                                    color: Colors.green, size: 36),
                                const SizedBox(height: 12),
                                Text('Generate Excel Spreadsheet',
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                const Text(
                                    'Download sortable department, employee, and task-level report data.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text(
                                    'Selected Department:\n$_selectedDepartmentName',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _isDownloadingExcel
                                  ? null
                                  : _downloadExcelReport,
                              icon: _isDownloadingExcel
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.download),
                              label: Text(_isDownloadingExcel
                                  ? 'Generating Excel...'
                                  : 'Download Excel'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Departmental Productivity Levels',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      if (teamPerformance.isNotEmpty)
                        Column(
                          children: teamPerformance.map((team) {
                            final progress =
                                (team['avg_progress'] as num?)?.toDouble() ??
                                    0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildProgressRow(
                                  context,
                                  team['team_name'] ?? 'Team',
                                  progress / 100,
                                  AspireColors.secondary),
                            );
                          }).toList(),
                        )
                      else ...[
                        _buildProgressRow(
                            context, 'Sales & Marketing', 0.85, Colors.blue),
                        const SizedBox(height: 12),
                        _buildProgressRow(context, 'Operations & Bookings',
                            0.92, AspireColors.accent),
                        const SizedBox(height: 12),
                        _buildProgressRow(
                            context, 'Customer Support', 0.78, Colors.amber),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Performing Employees',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                          'Ranked by completed packages and client SLA responses',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 16),
                      Divider(
                          color: isDark
                              ? AspireColors.darkBorder
                              : AspireColors.lightBorder),
                      const SizedBox(height: 8),
                      performers.isEmpty
                          ? const Center(
                              child: Text('No performance data available.'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  performers.length > 3 ? 3 : performers.length,
                              itemBuilder: (context, index) {
                                final perf = performers[index];
                                final score = double.tryParse(
                                        perf['performance_score']?.toString() ??
                                            '100') ??
                                    100.0;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AspireColors.primary.withOpacity(0.1),
                                    child: Text('#${index + 1}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AspireColors.primary)),
                                  ),
                                  title: Text(perf['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(perf['designation'] ?? ''),
                                  trailing: Text(
                                    '$score%',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: score >= 90
                                            ? Colors.green
                                            : Colors.amber.shade800),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressRow(
      BuildContext context, String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text('${(val * 100).round()}%',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: val,
          color: color,
          backgroundColor: Colors.grey.shade200,
        )
      ],
    );
  }
}
