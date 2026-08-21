import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/premium_button.dart';

class CreateRegularizationView extends StatefulWidget {
  const CreateRegularizationView({super.key});

  @override
  State<CreateRegularizationView> createState() => _CreateRegularizationViewState();
}

class _CreateRegularizationViewState extends State<CreateRegularizationView> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _selectedDate = DateTime.now();
  String _correctionType = 'Add Missing Punch In';
  final TextEditingController _currentValueController = TextEditingController();
  final TextEditingController _requestedValueController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  String? _attachmentPath;
  bool _isLoading = false;

  final List<String> _correctionTypes = [
    'Add Missing Punch In',
    'Add Missing Punch Out',
    'Edit Punch In Time',
    'Edit Punch Out Time',
    'Correct Attendance Status',
    'Correct Break Time',
    'Correct Working Hours',
    'Other'
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow up to 30 days past
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _attachmentPath = picked.path;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    final result = await api.createRegularizationRequest(
      date: dateStr,
      correctionType: _correctionType,
      currentValue: _currentValueController.text.trim().isEmpty ? null : _currentValueController.text.trim(),
      requestedValue: _requestedValueController.text.trim(),
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      attachmentPath: _attachmentPath,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted successfully'), backgroundColor: AspireColors.success));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(api.errorMessage ?? 'Failed to submit request'), backgroundColor: AspireColors.error));
      }
    }
  }

  @override
  void dispose() {
    _currentValueController.dispose();
    _requestedValueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'Request Correction'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Attendance Date'),
                  subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today, color: AspireColors.primary),
                  onTap: _pickDate,
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Correction Type
                DropdownButtonFormField<String>(
                  value: _correctionType,
                  decoration: InputDecoration(
                    labelText: 'Correction Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                  items: _correctionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _correctionType = val);
                  },
                ),
                const SizedBox(height: 16),
                
                // Current Value
                TextFormField(
                  controller: _currentValueController,
                  decoration: InputDecoration(
                    labelText: 'Current Recorded Value (Optional)',
                    hintText: 'e.g. 09:30 AM or Absent',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Requested Value
                TextFormField(
                  controller: _requestedValueController,
                  decoration: InputDecoration(
                    labelText: 'Requested Correct Value',
                    hintText: 'e.g. 09:00 AM or Present',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter requested value' : null,
                ),
                const SizedBox(height: 16),
                
                // Reason
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please provide a reason' : null,
                ),
                const SizedBox(height: 16),
                
                // Attachment
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file, color: AspireColors.primary),
                  title: Text(_attachmentPath == null ? 'Attach Proof (Optional)' : 'Attachment Selected'),
                  trailing: _attachmentPath != null 
                      ? IconButton(icon: const Icon(Icons.clear, color: AspireColors.error), onPressed: () => setState(() => _attachmentPath = null))
                      : null,
                  onTap: _pickAttachment,
                ),
                const SizedBox(height: 32),
                
                PremiumButton(
                  text: 'Submit Request',
                  onPressed: _submitRequest,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
