import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';

class AttendanceSettingsPage extends StatefulWidget {
  const AttendanceSettingsPage({super.key});

  @override
  State<AttendanceSettingsPage> createState() => _AttendanceSettingsPageState();
}

class _AttendanceSettingsPageState extends State<AttendanceSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final settings = await apiService.getAttendanceSettings();
    setState(() {
      _settings = settings;
      if (settings['weekly_off_days']?.contains('Sunday') == true) {
        _settings['weekly_off_sunday'] = 'true';
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Custom validation for Shift End > Shift Start
    final start = _settings['shift_start_time']?.toString() ?? '09:30';
    final end = _settings['shift_end_time']?.toString() ?? '18:30';
    if (start.compareTo(end) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift End must be after Shift Start'), backgroundColor: Colors.red),
      );
      return;
    }
    
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    // Map weekly_off_sunday back to weekly_off_days
    if (_settings['weekly_off_sunday']?.toString() == 'true') {
      _settings['weekly_off_days'] = '["Sunday"]';
    } else {
      _settings['weekly_off_days'] = '[]';
    }

    bool allSuccess = true;
    for (var entry in _settings.entries) {
      if (entry.key == 'weekly_off_sunday') continue;
      final success = await apiService.saveAttendanceSetting(entry.key, entry.value);
      if (!success) allSuccess = false;
    }

    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allSuccess ? 'Attendance settings updated successfully.' : 'Some settings failed to save.'),
          backgroundColor: allSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AspireColors.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(String key, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: _settings[key]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (isNumber && double.tryParse(value) == null) return 'Must be a number';
          if (key == 'office_latitude') {
             final lat = double.tryParse(value);
             if (lat == null || lat < -90 || lat > 90) return 'Latitude must be between -90 and 90';
          }
          if (key == 'office_longitude') {
             final lng = double.tryParse(value);
             if (lng == null || lng < -180 || lng > 180) return 'Longitude must be between -180 and 180';
          }
          if (key == 'office_radius') {
             final r = double.tryParse(value);
             if (r == null || r <= 0) return 'Radius must be greater than 0';
          }
          if (key == 'grace_period_minutes') {
             final gp = double.tryParse(value);
             if (gp == null || gp < 0) return 'Cannot be negative';
          }
          return null;
        },
        onSaved: (value) {
          if (isNumber) {
            _settings[key] = double.tryParse(value ?? '0');
          } else {
            _settings[key] = value;
          }
        },
        onChanged: (value) {
          if (!isNumber) _settings[key] = value;
        },
      ),
    );
  }

  Widget _buildSwitch(String key, String label) {
    final value = _settings[key]?.toString() == 'true';
    return SwitchListTile(
      title: Text(label),
      value: value,
      activeColor: AspireColors.primary,
      onChanged: (bool newValue) {
        setState(() {
          _settings[key] = newValue.toString();
        });
      },
    );
  }

  Widget _buildDropdown(String key, String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _settings[key]?.toString() ?? items.first,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() {
              _settings[key] = v;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Shift Settings'),
              _buildTextField('shift_start_time', 'Shift Start Time (HH:MM)'),
              _buildTextField('shift_end_time', 'Shift End Time (HH:MM)'),
              _buildTextField('grace_period_minutes', 'Grace Period (minutes)', isNumber: true),

              _buildSectionHeader('Half Day Settings'),
              _buildTextField('half_day_cutoff_time', 'Half Day Cutoff Time (HH:MM)'),
              _buildTextField('min_working_hours', 'Minimum Full Day Hours', isNumber: true),
              _buildTextField('min_half_day_hours', 'Minimum Half Day Hours', isNumber: true),

              _buildSectionHeader('Absent Settings'),
              _buildTextField('attendance_closing_time', 'Attendance Closing Time (HH:MM)'),
              _buildSwitch('auto_mark_absent', 'Automatically mark Absent after closing time'),

              _buildSectionHeader('Punch Settings'),
              _buildSwitch('enable_punch_in', 'Enable Punch In'),
              _buildSwitch('enable_punch_out', 'Enable Punch Out'),
              _buildSwitch('require_punch_in_selfie', 'Require Selfie for Punch In'),
              _buildSwitch('require_punch_out_selfie', 'Require Selfie for Punch Out'),
              _buildSwitch('require_punch_in_gps', 'Require GPS for Punch In'),
              _buildSwitch('require_punch_out_gps', 'Require GPS for Punch Out'),

              _buildSectionHeader('Holiday & Weekly Off Settings'),
              _buildDropdown('saturday_off_rule', 'Saturday Off Rule', [
                'No Saturday Off',
                'Every Saturday Off',
                '1st Saturday Off',
                '2nd Saturday Off',
                '3rd Saturday Off',
                '4th Saturday Off',
                'Alternate Saturdays'
              ]),
              _buildSwitch('weekly_off_sunday', 'Sunday as Weekly Off'), // We map this later to weekly_off_days in _saveSettings
              
              _buildSectionHeader('Geofence Settings'),
              _buildTextField('office_name', 'Office Name'),
              _buildTextField('office_latitude', 'Office Latitude', isNumber: true),
              _buildTextField('office_longitude', 'Office Longitude', isNumber: true),
              _buildTextField('office_radius', 'Allowed Radius in meters', isNumber: true),

              _buildSectionHeader('Notification Settings'),
              _buildSwitch('enable_punch_in_reminder', 'Enable Punch In Reminder'),
              _buildTextField('punch_in_reminder_time', 'Punch In Reminder Time (HH:MM)'),
              _buildSwitch('enable_late_check_in_notification', 'Enable Late Check-In Notification'),
              _buildSwitch('enable_punch_out_reminder', 'Enable Punch Out Reminder'),
              _buildTextField('punch_out_reminder_time', 'Punch Out Reminder Time (HH:MM)'),
              _buildSwitch('enable_missed_punch_out_reminder', 'Enable Missed Punch Out Reminder'),
              _buildSwitch('enable_absent_notification', 'Enable Absent Notification'),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AspireColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Settings',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
