import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../models/regularization_request.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/premium_card.dart';

class AdminRegularizationDashboard extends StatefulWidget {
  const AdminRegularizationDashboard({super.key});

  @override
  State<AdminRegularizationDashboard> createState() => _AdminRegularizationDashboardState();
}

class _AdminRegularizationDashboardState extends State<AdminRegularizationDashboard> {
  bool _isLoading = true;
  List<RegularizationRequest> _requests = [];
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final statusFilter = _selectedStatus == 'All' ? null : _selectedStatus.toLowerCase();
    
    final requests = await api.fetchAllRegularizationRequests(status: statusFilter);
    
    if (mounted) {
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return AspireColors.success;
      case 'rejected': return AspireColors.error;
      case 'cancelled': return Colors.grey;
      default: return AspireColors.warning;
    }
  }

  void _showReviewModal(RegularizationRequest req) {
    final remarksController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Review Request',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Employee', '${req.employeeName} (${req.employeeId})'),
                    _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(DateTime.parse(req.date))),
                    _buildDetailRow('Type', req.correctionType),
                    if (req.currentValue != null) _buildDetailRow('Current Value', req.currentValue!),
                    _buildDetailRow('Requested Value', req.requestedValue),
                    if (req.reason != null) _buildDetailRow('Reason', req.reason!),
                    if (req.attachmentUrl != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.link),
                          label: const Text('View Attachment'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AspireColors.error, foregroundColor: Colors.white),
                            onPressed: isSubmitting ? null : () async {
                              setModalState(() => isSubmitting = true);
                              final api = Provider.of<ApiService>(context, listen: false);
                              final success = await api.updateRegularizationRequestStatus(req.id, 'rejected', remarksController.text);
                              if (success) {
                                Navigator.pop(ctx);
                                _fetchRequests();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(api.errorMessage ?? 'Error')));
                                setModalState(() => isSubmitting = false);
                              }
                            },
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AspireColors.success, foregroundColor: Colors.white),
                            onPressed: isSubmitting ? null : () async {
                              setModalState(() => isSubmitting = true);
                              final api = Provider.of<ApiService>(context, listen: false);
                              final success = await api.updateRegularizationRequestStatus(req.id, 'approved', remarksController.text);
                              if (success) {
                                Navigator.pop(ctx);
                                _fetchRequests();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(api.errorMessage ?? 'Error')));
                                setModalState(() => isSubmitting = false);
                              }
                            },
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AspireColors.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'Team Regularizations'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 8),
              child: Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: ['All', 'Pending', 'Approved', 'Rejected'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _fetchRequests();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? const Center(child: Text('No regularization requests found.'))
                      : RefreshIndicator(
                          onRefresh: _fetchRequests,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppConstants.defaultPadding),
                            itemCount: _requests.length,
                            itemBuilder: (context, index) {
                              final req = _requests[index];
                              final statusColor = _getStatusColor(req.status);
                              final dateStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(req.date));
                              
                              return PremiumCard(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                onTap: req.status == 'pending' ? () => _showReviewModal(req) : null,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${req.employeeName}',
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            req.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text('${req.departmentName} • ${req.employeeId}', style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Text('Date: $dateStr'),
                                    Text('Type: ${req.correctionType}'),
                                    Text('Requested: ${req.requestedValue}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
