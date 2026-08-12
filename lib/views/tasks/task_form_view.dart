import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../services/voice_recording_service.dart';
import '../../models/user.dart';
import '../../models/project.dart';
import '../../models/department.dart';

class TaskFormView extends StatefulWidget {
  final String? prefilledProjectId;
  const TaskFormView({super.key, this.prefilledProjectId});

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _priority = 'medium';
  String? _selectedDeptId;
  String? _selectedAssigneeId;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));

  // Bulk assignment configuration
  bool _isBulkAssign = false;
  final List<String> _selectedAssigneeIds = [];

  final VoiceRecordingService _voiceService = VoiceRecordingService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecordingTitleVoice = false;
  bool _isRecordingDescriptionVoice = false;

  Uint8List? _titleVoiceBytes;
  String? _titleVoiceFileName;
  String? _titleVoiceMimeType;
  int _titleVoiceDurationSeconds = 0;

  Uint8List? _descriptionVoiceBytes;
  String? _descriptionVoiceFileName;
  String? _descriptionVoiceMimeType;
  int _descriptionVoiceDurationSeconds = 0;

  bool _isPlaying = false;
  String? _playingType; // 'title' or 'description'

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playingType = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _toggleTitleRecording() async {
    if (_isRecordingTitleVoice) {
      final result = await _voiceService.stopRecording();
      setState(() {
        _isRecordingTitleVoice = false;
        if (result != null) {
          _titleVoiceBytes = result.bytes;
          _titleVoiceFileName = result.fileName;
          _titleVoiceMimeType = result.mimeType;
          _titleVoiceDurationSeconds = result.durationSeconds;
        }
      });
    } else {
      await _voiceService.startRecording();
      setState(() {
        _isRecordingTitleVoice = true;
        _isRecordingDescriptionVoice = false; // Stop other if running
      });
    }
  }

  Future<void> _toggleDescriptionRecording() async {
    if (_isRecordingDescriptionVoice) {
      final result = await _voiceService.stopRecording();
      setState(() {
        _isRecordingDescriptionVoice = false;
        if (result != null) {
          _descriptionVoiceBytes = result.bytes;
          _descriptionVoiceFileName = result.fileName;
          _descriptionVoiceMimeType = result.mimeType;
          _descriptionVoiceDurationSeconds = result.durationSeconds;
        }
      });
    } else {
      await _voiceService.startRecording();
      setState(() {
        _isRecordingDescriptionVoice = true;
        _isRecordingTitleVoice = false;
      });
    }
  }

  Future<void> _playBytes(Uint8List bytes, String type) async {
    if (_isPlaying && _playingType == type) {
      await _audioPlayer.pause();
      return;
    }

    await _audioPlayer.play(BytesSource(bytes));
    setState(() {
      _playingType = type;
    });
  }

  void _submitForm() async {
    if (_titleController.text.trim().isEmpty && _titleVoiceBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please enter a task title or record a title voice note')),
      );
      return;
    }
    if (_descController.text.trim().isEmpty && _descriptionVoiceBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enter a description or record a description voice note')),
      );
      return;
    }

    // Validate other fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final api = Provider.of<ApiService>(context, listen: false);

    Map<String, dynamic> requestData = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'department_id': _selectedDeptId,
      'priority': _priority,
      'start_date': _startDate.toString(),
      'due_date': _dueDate.toString(),
    };

    if (_titleVoiceBytes != null) {
      requestData['title_audio'] = http.MultipartFile.fromBytes(
        'title_audio',
        _titleVoiceBytes!,
        filename: _titleVoiceFileName,
      );
      requestData['title_audio_duration_seconds'] = _titleVoiceDurationSeconds;
    }

    if (_descriptionVoiceBytes != null) {
      requestData['description_audio'] = http.MultipartFile.fromBytes(
        'description_audio',
        _descriptionVoiceBytes!,
        filename: _descriptionVoiceFileName,
      );
      requestData['description_audio_duration_seconds'] =
          _descriptionVoiceDurationSeconds;
    }

    bool success = false;

    if (_isBulkAssign) {
      requestData['assigned_to_list'] = _selectedAssigneeIds;
      success = await api.bulkAssign(requestData);
    } else {
      requestData['assigned_to'] = _selectedAssigneeId;
      final task = await api.createTask(requestData);
      success = task != null;
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Task(s) dispatched successfully!'),
            backgroundColor: AspireColors.accent),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildAudioPreview(String label, Uint8List bytes, int durationSeconds,
      VoidCallback onPlay, VoidCallback onDelete, String type) {
    bool isCurrentlyPlaying = _isPlaying && _playingType == type;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AspireColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                color: AspireColors.primary),
            onPressed: onPlay,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label (00:${durationSeconds.toString().padLeft(2, '0')})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
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
        title: const Text('Create Work Task'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          api.fetchProjects(),
          api.fetchUsers(),
          api.fetchDepartments(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allUsers = (snapshot.data?[1] as List<User>?) ?? [];
          final departmentsList =
              (snapshot.data?[2] as List<Department>?) ?? [];

          final currentUserRole = api.currentUser?.role ?? '';
          final List<User> staffList;
          if (currentUserRole == 'manager') {
            staffList = allUsers
                .where((u) =>
                    u.role == 'managing_director' ||
                    u.role == 'team_leader' ||
                    u.role == 'staff')
                .toList();
          } else if (currentUserRole == 'managing_director') {
            staffList = allUsers
                .where((u) => u.role == 'team_leader' || u.role == 'staff')
                .toList();
          } else if (currentUserRole == 'team_leader') {
            staffList = allUsers.where((u) => u.role == 'staff').toList();
          } else {
            staffList = allUsers
                .where((u) =>
                    u.role == 'manager' ||
                    u.role == 'managing_director' ||
                    u.role == 'team_leader' ||
                    u.role == 'staff')
                .toList();
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title (or use voice)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isRecordingTitleVoice
                            ? Icons.stop_circle_rounded
                            : Icons.mic_rounded,
                      ),
                      color: _isRecordingTitleVoice ? Colors.red : null,
                      onPressed: _toggleTitleRecording,
                    ),
                  ),
                ),
                if (_isRecordingTitleVoice)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 12),
                    child: Text('Recording Title Voice Note...',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                if (_titleVoiceBytes != null)
                  _buildAudioPreview(
                      'Title Voice Note',
                      _titleVoiceBytes!,
                      _titleVoiceDurationSeconds,
                      () => _playBytes(_titleVoiceBytes!, 'title'), () {
                    setState(() => _titleVoiceBytes = null);
                  }, 'title'),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Task Description (or use voice)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isRecordingDescriptionVoice
                            ? Icons.stop_circle_rounded
                            : Icons.mic_rounded,
                      ),
                      color: _isRecordingDescriptionVoice ? Colors.red : null,
                      onPressed: _toggleDescriptionRecording,
                    ),
                  ),
                ),
                if (_isRecordingDescriptionVoice)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 12),
                    child: Text('Recording Description Voice Note...',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                if (_descriptionVoiceBytes != null)
                  _buildAudioPreview(
                      'Description Voice Note',
                      _descriptionVoiceBytes!,
                      _descriptionVoiceDurationSeconds,
                      () => _playBytes(_descriptionVoiceBytes!, 'description'),
                      () {
                    setState(() => _descriptionVoiceBytes = null);
                  }, 'description'),
                const SizedBox(height: 16),

                // Row 1: Dept & Priority selectors
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDeptId,
                        decoration:
                            const InputDecoration(labelText: 'Department'),
                        items: departmentsList.map((d) {
                          return DropdownMenuItem(
                              value: d.id, child: Text(d.name));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDeptId = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _priority,
                        decoration:
                            const InputDecoration(labelText: 'Priority Level'),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(
                              value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _priority = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 2: Date Pickers
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Date',
                            style: TextStyle(fontSize: 12)),
                        subtitle:
                            Text('${_startDate.toLocal()}'.substring(0, 10)),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 30)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListTile(
                        title: const Text('Due Date',
                            style: TextStyle(fontSize: 12)),
                        subtitle:
                            Text('${_dueDate.toLocal()}'.substring(0, 10)),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _dueDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Checkbox: Bulk Assignment configuration
                SwitchListTile(
                  title: const Text('Bulk Team Distribution',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Assign copies of this blueprint to multiple staff members simultaneously'),
                  value: _isBulkAssign,
                  onChanged: (val) {
                    setState(() {
                      _isBulkAssign = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Assignee selection card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isBulkAssign
                              ? 'Select Target Team Members'
                              : 'Select Primary Assignee',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _isBulkAssign
                            ? Column(
                                children: staffList.map((u) {
                                  final isChecked =
                                      _selectedAssigneeIds.contains(u.id);
                                  return CheckboxListTile(
                                    title: Text(u.name),
                                    subtitle: Text(
                                        '${u.designation} (${u.role.toUpperCase()})'),
                                    value: isChecked,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedAssigneeIds.add(u.id);
                                        } else {
                                          _selectedAssigneeIds.remove(u.id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              )
                            : DropdownButtonFormField<String>(
                                value: _selectedAssigneeId,
                                decoration: const InputDecoration(
                                    labelText: 'Employee Assignee'),
                                items: staffList.map((u) {
                                  return DropdownMenuItem(
                                      value: u.id,
                                      child:
                                          Text('${u.name} (${u.designation})'));
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedAssigneeId = val;
                                  });
                                },
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Action Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AspireColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Publish Work Assignment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
