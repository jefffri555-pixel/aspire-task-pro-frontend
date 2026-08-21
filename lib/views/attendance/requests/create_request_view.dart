import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/colors.dart';
import '../../../services/api_service.dart';

class CreateRequestView extends StatefulWidget {
  const CreateRequestView({super.key});

  @override
  State<CreateRequestView> createState() => _CreateRequestViewState();
}

class _CreateRequestViewState extends State<CreateRequestView> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Leave';
  String _leaveType = 'Casual Leave';
  String _durationType = 'full_day';
  
  DateTime? _startDate;
  DateTime? _endDate;
  
  final _reasonController = TextEditingController();
  final _locationController = TextEditingController();
  final _purposeController = TextEditingController();
  
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    final actualLeaveType = _selectedType == 'Leave' ? _leaveType : _selectedType;
    
    final req = await apiService.createLeaveRequest(
      leaveType: actualLeaveType,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
      durationType: _durationType,
      reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
      location: _selectedType == 'On Duty' ? _locationController.text : null,
      purpose: _selectedType == 'On Duty' ? _purposeController.text : null,
      // Attachment URL logic placeholder
    );

    setState(() => _isLoading = false);

    if (req != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request created successfully'), backgroundColor: AspireColors.success),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiService.errorMessage ?? 'Failed to create request'), backgroundColor: AspireColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Request Type', border: OutlineInputBorder()),
                items: ['Leave', 'Work From Home', 'On Duty']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedType = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              if (_selectedType == 'Leave') ...[
                DropdownButtonFormField<String>(
                  value: _leaveType,
                  decoration: const InputDecoration(labelText: 'Leave Type', border: OutlineInputBorder()),
                  items: ['Casual Leave', 'Sick Leave', 'Earned Leave', 'Other']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _leaveType = val!),
                ),
                const SizedBox(height: 16),
              ],

              if (_selectedType != 'On Duty') ...[
                DropdownButtonFormField<String>(
                  value: _durationType,
                  decoration: const InputDecoration(labelText: 'Duration', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'full_day', child: Text('Full Day')),
                    DropdownMenuItem(value: 'half_day', child: Text('Half Day')),
                  ],
                  onChanged: (val) => setState(() => _durationType = val!),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            if (_endDate == null || _endDate!.isBefore(_startDate!)) {
                              _endDate = _startDate;
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_startDate == null ? 'From Date' : DateFormat('MMM dd, yyyy').format(_startDate!)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_endDate == null ? 'To Date' : DateFormat('MMM dd, yyyy').format(_endDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedType == 'On Duty') ...[
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purposeController,
                  decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: _selectedType == 'On Duty' ? 'Reason / Description' : 'Reason', 
                  border: const OutlineInputBorder()
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AspireColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
