import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../models/regularization_request.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/premium_card.dart';
import 'create_regularization_view.dart';

class MyRegularizationRequestsView extends StatefulWidget {
  const MyRegularizationRequestsView({super.key});

  @override
  State<MyRegularizationRequestsView> createState() => _MyRegularizationRequestsViewState();
}

class _MyRegularizationRequestsViewState extends State<MyRegularizationRequestsView> {
  bool _isLoading = true;
  List<RegularizationRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final requests = await api.fetchMyRegularizationRequests();
    
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'My Regularizations'),
      body: SafeArea(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
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
                              const SizedBox(height: 8),
                              Text(
                                req.correctionType,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AspireColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (req.currentValue != null && req.currentValue!.isNotEmpty)
                                Text('Current: ${req.currentValue}'),
                              Text('Requested: ${req.requestedValue}', style: const TextStyle(fontWeight: FontWeight.w500)),
                              if (req.reason != null && req.reason!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Reason: ${req.reason}', style: const TextStyle(color: AspireColors.textSecondary)),
                              ],
                              if (req.remarks != null && req.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Remarks: ${req.remarks}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const CreateRegularizationView()),
          );
          if (result == true) {
            _fetchRequests();
          }
        },
        backgroundColor: AspireColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
