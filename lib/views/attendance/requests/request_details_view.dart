import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../models/leave_request.dart';
import '../../../services/api_service.dart';

class RequestDetailsView extends StatefulWidget {
  final LeaveRequest request;

  const RequestDetailsView({super.key, required this.request});

  @override
  State<RequestDetailsView> createState() => _RequestDetailsViewState();
}

class _RequestDetailsViewState extends State<RequestDetailsView> {
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  void _review(String status) async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    final success = await apiService.reviewLeaveRequest(
      widget.request.id, 
      status, 
      _remarksController.text.trim()
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully'), backgroundColor: AspireColors.success),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiService.errorMessage ?? 'Failed to update request'), backgroundColor: AspireColors.error),
        );
      }
    }
  }

  Widget _buildAuditTrail() {
    if (widget.request.audits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('Audit Trail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...widget.request.audits.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${a.reviewerName ?? 'System'} marked as ${a.status.toUpperCase()}', 
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              if (a.createdAt != null) Text(a.createdAt!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (a.remarks != null && a.remarks!.isNotEmpty) 
                Text('Remarks: ${a.remarks}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<ApiService>(context, listen: false).currentUser;
    final bool canReview = currentUser?.id != widget.request.userId && 
                          widget.request.status == 'pending' &&
                          ['admin', 'super_admin', 'manager', 'managing_director', 'team_leader'].contains(currentUser?.role ?? '');
                          
    final bool canCancel = currentUser?.id == widget.request.userId && widget.request.status == 'pending';

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.request.leaveType, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AspireColors.primary)),
            const SizedBox(height: 16),
            
            if (widget.request.employeeName != null) ...[
              Text('Employee: ${widget.request.employeeName} (${widget.request.employeeId ?? ""})', style: const TextStyle(fontSize: 16)),
              if (widget.request.departmentName != null)
                Text('Department: ${widget.request.departmentName}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
            ],

            Text('Duration: ${widget.request.startDate} to ${widget.request.endDate} (${widget.request.durationType})', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Status: ${widget.request.status.toUpperCase()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.request.status == 'approved' ? Colors.green : (widget.request.status == 'rejected' ? Colors.red : Colors.orange))),
            
            if (widget.request.reason != null && widget.request.reason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.request.reason!),
            ],
            
            if (widget.request.location != null && widget.request.location!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.request.location!),
            ],
            
            if (widget.request.purpose != null && widget.request.purpose!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Purpose:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.request.purpose!),
            ],

            if (widget.request.adminNotes != null && widget.request.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Final Remarks:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.request.adminNotes!),
            ],
            
            const SizedBox(height: 16),
            _buildAuditTrail(),

            if (canReview) ...[
              const SizedBox(height: 32),
              TextField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => _review('rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _review('approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Approve', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
            
            if (canCancel) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => _review('cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel Request'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
