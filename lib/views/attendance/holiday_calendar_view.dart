import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../models/holiday.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/premium_button.dart';

class HolidayCalendarView extends StatefulWidget {
  const HolidayCalendarView({super.key});

  @override
  State<HolidayCalendarView> createState() => _HolidayCalendarViewState();
}

class _HolidayCalendarViewState extends State<HolidayCalendarView> {
  bool _isLoading = true;
  List<Holiday> _holidays = [];
  
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    _holidays = await api.getHolidays();
    setState(() => _isLoading = false);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _showAddHolidayDialog([Holiday? existing]) {
    final formKey = GlobalKey<FormState>();
    String name = existing?.name ?? '';
    DateTime date = existing != null ? DateTime.parse(existing.date) : DateTime.now();
    String type = existing?.type ?? 'Festival Holiday';
    String desc = existing?.description ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Holiday' : 'Edit Holiday'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(labelText: 'Holiday Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        onSaved: (v) => name = v!,
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(date)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() => date = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'National Holiday', child: Text('National Holiday')),
                          DropdownMenuItem(value: 'Festival Holiday', child: Text('Festival Holiday')),
                          DropdownMenuItem(value: 'Company Holiday', child: Text('Company Holiday')),
                          DropdownMenuItem(value: 'Optional Holiday', child: Text('Optional Holiday')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setStateDialog(() => type = v!),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: desc,
                        decoration: const InputDecoration(labelText: 'Description (Optional)'),
                        onSaved: (v) => desc = v ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      final api = Provider.of<ApiService>(context, listen: false);
                      await api.deleteHoliday(existing.id);
                      _fetchHolidays();
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                PremiumButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      
                      final api = Provider.of<ApiService>(context, listen: false);
                      final h = Holiday(
                        id: existing?.id ?? '',
                        name: name,
                        date: DateFormat('yyyy-MM-dd').format(date),
                        type: type,
                        description: desc,
                      );
                      
                      bool success;
                      if (existing == null) {
                        success = await api.createHoliday(h);
                      } else {
                        success = await api.updateHoliday(h);
                      }
                      
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(api.errorMessage ?? 'Failed to save holiday'))
                        );
                      }
                      
                      _fetchHolidays();
                    }
                  },
                  text: 'Save',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Monday
    
    // Adjust so Sunday is 0
    final firstDayOffset = firstDayWeekday == 7 ? 0 : firstDayWeekday;

    final List<Widget> dayWidgets = [];

    // Weekday Headers
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (var d in weekdays) {
      dayWidgets.add(
        Center(
          child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
      );
    }

    // Empty slots before first day
    for (int i = 0; i < firstDayOffset; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Days
    for (int d = 1; d <= daysInMonth; d++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_currentMonth.year, _currentMonth.month, d));
      final holiday = _holidays.cast<Holiday?>().firstWhere((h) => h!.date == dateStr, orElse: () => null);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            // Only admin or manager can edit
            final role = Provider.of<ApiService>(context, listen: false).currentUser?.role ?? 'staff';
            if (['admin', 'super_admin', 'manager', 'managing_director'].contains(role) && holiday != null) {
              _showAddHolidayDialog(holiday);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: holiday != null ? AspireColors.primary.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: holiday != null ? AspireColors.primary : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$d', style: TextStyle(
                    fontWeight: holiday != null ? FontWeight.bold : FontWeight.normal,
                    color: holiday != null ? AspireColors.primary : Colors.black87,
                  )),
                  if (holiday != null)
                    const Icon(Icons.circle, size: 6, color: AspireColors.primary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<ApiService>(context, listen: false).currentUser?.role ?? 'staff';
    final canEdit = ['admin', 'super_admin', 'manager', 'managing_director'].contains(userRole);

    final currentHolidays = _holidays.where((h) {
      final date = DateTime.parse(h.date);
      return date.year == _currentMonth.year && date.month == _currentMonth.month;
    }).toList();

    return Scaffold(
      floatingActionButton: canEdit ? FloatingActionButton(
        onPressed: () => _showAddHolidayDialog(),
        backgroundColor: AspireColors.primary,
        child: const Icon(Icons.add),
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _previousMonth,
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_currentMonth),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _nextMonth,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCalendar(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Holidays this month:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (currentHolidays.isEmpty)
                    const Text('No holidays scheduled for this month.', style: TextStyle(color: Colors.grey))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentHolidays.length,
                      itemBuilder: (ctx, idx) {
                        final h = currentHolidays[idx];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AspireColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.celebration, color: AspireColors.primary),
                            ),
                            title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${h.date} • ${h.type}'),
                            trailing: canEdit ? IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () => _showAddHolidayDialog(h),
                            ) : null,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
