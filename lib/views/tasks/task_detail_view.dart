import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/voice_recording_service.dart';
import '../../widgets/voice_message_bubble.dart';
import '../../config/constants.dart';
import '../../utils/media_utils.dart';

// import clean status extension
class TaskDetailView extends StatefulWidget {
  final String taskId;
  const TaskDetailView({super.key, required this.taskId});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  final _commentController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final VoiceRecordingService _voiceService = VoiceRecordingService();
  bool _isRecording = false;

  bool _isAssigning = false;
  final Set<String> _downloadingFiles = {};
  String? _downloadingAttachmentId;

  bool _isUploadingFile = false;
  bool _hasAssigned = false;
  String? _selectedEmployeeId;
  Future<List<User>>? _usersFuture;

  bool _isUpdatingTaskStatus = false;
  Task? _task;
  Future<Task?>? _taskFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_taskFuture == null) {
      final api = Provider.of<ApiService>(context, listen: false);
      _taskFuture = api.fetchTaskById(widget.taskId).then((t) {
        if (mounted) setState(() => _task = t);
        return t;
      });
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _commentController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _postComment(Task task) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final api = Provider.of<ApiService>(context, listen: false);
    final c = await api.addComment(widget.taskId, text);
    if (c != null) {
      _commentController.clear();
      setState(() {
        task.comments.add(c);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _voiceService.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }
      await _voiceService.startRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final result = await _voiceService.stopRecording();
      setState(() {
        _isRecording = false;
      });
      if (result != null && mounted) {
        final api = Provider.of<ApiService>(context, listen: false);
        final c = await api.sendVoiceMessage(
          taskId: widget.taskId,
          audioBytes: result.bytes,
          fileName: result.fileName,
          mimeType: result.mimeType,
          durationSeconds: result.durationSeconds,
        );
        if (c != null) {
          if (_task != null) {
            setState(() {
              _task!.comments.add(c);
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(api.errorMessage ?? 'Failed to send voice message')),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  void _changeStatus(String statusValue) async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.updateTask(widget.taskId, {
      'status': statusValue,
    });
    setState(() {});
  }

  void _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final selectedFile = result.files.single;

      if (selectedFile.bytes == null) {
        throw Exception('Unable to read selected file');
      }

      final api = Provider.of<ApiService>(context, listen: false);
      final success = await api.uploadTaskAttachment(
          widget.taskId, selectedFile.bytes!, selectedFile.name);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the task details to show the new attachment
        setState(
            () {}); // This will trigger FutureBuilder to re-fetch if properly architected,
        // but we just need to ensure the attachment list updates.
        // Usually we might need to await a task refresh call here.
      } else {
        final errorMessage = api.errorMessage ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $errorMessage'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print('File Picker Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _assignTask() async {
    if (_isAssigning) return;

    final employeeId = _selectedEmployeeId;

    if (employeeId == null || employeeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee'),
        ),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      debugPrint('Assigning task ${widget.taskId} to $employeeId');

      final api = Provider.of<ApiService>(context, listen: false);
      final updatedTask = await api.assignTask(widget.taskId, employeeId);

      if (!mounted) return;

      if (updatedTask != null) {
        setState(() {
          _isAssigning = false;
          _hasAssigned = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task assigned successfully'),
          ),
        );
      } else {
        throw Exception(api.errorMessage ?? 'Failed to assign task');
      }
    } catch (error, stackTrace) {
      debugPrint('Task assignment error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isAssigning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign task: $error'),
        ),
      );
    }
  }

  Widget _buildAssignWidget(Task task) {
    final isAssigned = task.assignedTo != null || _hasAssigned;

    if (isAssigned) {
      return ElevatedButton(
        onPressed: null,
        child: const Text('Assigned'),
      );
    }

    _usersFuture ??=
        Provider.of<ApiService>(context, listen: false).fetchAdminUsers();

    return FutureBuilder<List<User>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final staffList = (snapshot.data ?? <User>[])
            .where((u) =>
                (u.role == 'staff' || u.role == 'team_leader') &&
                u.departmentId == task.departmentId)
            .toList();

        if (staffList.isEmpty) {
          return const Text('No staff available in this department.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedEmployeeId,
              decoration: const InputDecoration(labelText: 'Employee Assignee'),
              items: staffList.map<DropdownMenuItem<String>>((u) {
                return DropdownMenuItem<String>(
                  value: u.id,
                  child: Text(
                      '${u.name} (${u.employeeId.isEmpty ? "N/A" : u.employeeId} - ${u.designation.isEmpty ? "Staff" : u.designation})'),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedEmployeeId = value;
                });
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isAssigning || _selectedEmployeeId == null
                  ? null
                  : _assignTask,
              child: Text(
                _isAssigning ? 'Assigning...' : 'Assign Work',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = Provider.of<ApiService>(context);
    final user = api.currentUser;
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) return const SizedBox();

    return FutureBuilder<Task?>(
      future: _taskFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _task == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Task Detailed File'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final task = _task ?? snapshot.data;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Task Detailed File'),
            ),
            body:
                const Center(child: Text('Task profile could not be loaded.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Detailed File'),
          ),
          body: Row(
            children: [
              // Left Panel: Details & Action Buttons (Adaptive Grid)
              Expanded(
                flex: 3,
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    // Title Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  task.taskId,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        AspireColors.getStatusColor(task.status)
                                            .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    getTaskStatusLabel(task.status),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AspireColors.getStatusColor(
                                            task.status),
                                        fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (task.title.isNotEmpty) ...[
                              Text(
                                task.title,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (task.titleAudioUrl != null) ...[
                              VoiceMessageBubble(
                                  audioUrl: resolveBackendMediaUrl(
                                      task.titleAudioUrl),
                                  isMe: false),
                              const SizedBox(height: 8),
                            ],
                            if (task.description.isNotEmpty) ...[
                              Text(task.description),
                              const SizedBox(height: 16),
                            ],
                            if (task.descriptionAudioUrl != null) ...[
                              VoiceMessageBubble(
                                  audioUrl: resolveBackendMediaUrl(
                                      task.descriptionAudioUrl),
                                  isMe: false),
                              const SizedBox(height: 16),
                            ],
                            const Divider(),
                            const SizedBox(height: 8),

                            // Info grid fields
                            _buildInfoRow(
                                Icons.business_center_outlined,
                                'Department',
                                task.departmentName ?? 'General Operations'),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.priority_high, 'Priority Level',
                                task.priority.toUpperCase()),
                            const SizedBox(height: 8),
                            if (user.role == 'team_leader' ||
                                user.role == 'staff') ...[
                              const SizedBox(height: 8),
                              const Text('Assigned By',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 18, color: AspireColors.secondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      task.assignedByName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: theme
                                                  .textTheme.bodyLarge?.color ??
                                              (isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text('Assigned To',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_pin_outlined,
                                      size: 18, color: AspireColors.secondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      task.assignedToName ?? 'Unassigned',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: theme
                                                  .textTheme.bodyLarge?.color ??
                                              (isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ),
                                  ),
                                ],
                              ),
                              if (user.role == 'team_leader' &&
                                  (task.assignedTo == null ||
                                      _hasAssigned)) ...[
                                const SizedBox(height: 8),
                                _buildAssignWidget(task),
                              ],
                              const SizedBox(height: 16),
                            ] else ...[
                              _buildInfoRow(Icons.person_outline, 'Assigned By',
                                  task.assignedByName),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                  Icons.person_pin_outlined,
                                  'Assigned To',
                                  task.assignedToName ?? 'Unassigned'),
                              if (task.assignedTo == null || _hasAssigned) ...[
                                const SizedBox(height: 8),
                                _buildAssignWidget(task),
                              ],
                              const SizedBox(height: 8),
                            ],
                            _buildInfoRow(Icons.event, 'Target Schedule',
                                '${task.startDate.substring(0, 10)} to ${task.dueDate.substring(0, 10)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 24),
                    _buildCompletionAction(task, user),
                    const SizedBox(height: 24),

                    // Action Controls Block (Manager approvals review)
                    if (user.role == 'manager' &&
                        task.status == 'waiting_for_review')
                      Card(
                        color: Colors.purple.shade50.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Pending Review - Manager Actions Required',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                  'This task has been set to 100% progress. Verify and approve resolution.'),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _changeStatus('completed'),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve & Close'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AspireColors.accent,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _changeStatus('rejected'),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Reject Resolution'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side:
                                            const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Right Panel: Comments Timeline & File Attachments (Visible on Desktop, or below in Mobile layouts)
              if (MediaQuery.of(context).size.width >= 900)
                const VerticalDivider(width: 1),

              // Sidebar panel
              if (MediaQuery.of(context).size.width >= 900)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: isDark ? Colors.transparent : Colors.grey.shade50,
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TabBar(
                            labelColor: AspireColors.primary,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: AspireColors.accent,
                            tabs: const [
                              Tab(
                                  icon:
                                      Icon(Icons.chat_bubble_outline, size: 18),
                                  text: 'Task Chat'),
                              Tab(
                                  icon: Icon(Icons.attach_file, size: 18),
                                  text: 'Files'),
                              Tab(
                                  icon: Icon(Icons.list_alt_rounded, size: 18),
                                  text: 'Activity Log'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildTaskChatWidget(context, task, user),
                                _buildAttachmentsWidget(context, task, user),
                                _buildActivityLogWidget(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Bottom panel drawer for mobile devices
          bottomSheet: MediaQuery.of(context).size.width >= 900
              ? null
              : Container(
                  height: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: isDark
                                ? AspireColors.darkBorder
                                : AspireColors.lightBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            _showMobileDrawer(context, 'Task Chat',
                                _buildTaskChatWidget(context, task, user));
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Task Chat'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            _showMobileDrawer(context, 'Attachments',
                                _buildAttachmentsWidget(context, task, user));
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Files'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            _showMobileDrawer(context, 'Activity Log',
                                _buildActivityLogWidget(context));
                          },
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('Activity Log'),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _markTaskCompleted(Task task, User user) async {
    final isManager = isManagerRole(user.role);
    final title = isManager ? 'Approve Task' : 'Submit for Review';
    final content = isManager
        ? 'Approve this task and mark it as completed?'
        : 'Submit this task for manager review?';
    final confirmText = isManager ? 'Approve' : 'Submit';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isUpdatingTaskStatus = true;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.markTaskAsCompleted(taskId: task.id);

      if (!mounted) return;

      setState(() {
        _task = Task.fromJson(response['task']);
        _isUpdatingTaskStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ?? 'Task updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingTaskStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildCompletionAction(Task task, User user) {
    final buttonEnabled = canUpdateCompletionStatus(
      role: user.role,
      status: task.status,
    );

    final buttonLabel = completionButtonLabel(
      role: user.role,
      status: task.status,
    );

    final isCompleted = task.status == 'completed';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: isCompleted ? Colors.green.shade200 : Colors.grey.shade300,
            width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      color: isCompleted
          ? Colors.green.withValues(alpha: 0.05)
          : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: buttonEnabled && !_isUpdatingTaskStatus
                  ? () => _markTaskCompleted(task, user)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCompleted ? Colors.green : AspireColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.green.shade300,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _isUpdatingTaskStatus
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ))
                  : Icon(isCompleted
                      ? Icons.check_circle
                      : Icons.check_circle_outline),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAttachment(Task task, TaskAttachment attachment) async {
    if (_downloadingAttachmentId != null) return;

    debugPrint('DOWNLOAD CLICKED');
    debugPrint('Task ID: ${task.id}');
    debugPrint('Attachment ID: ${attachment.id}');
    debugPrint('Original name: ${attachment.originalName}');
    debugPrint('File URL: ${attachment.fileUrl}');

    setState(() {
      _downloadingAttachmentId = attachment.id;
    });

    try {
      final downloadName = attachment.originalName.isNotEmpty
          ? attachment.originalName
          : attachment.fileName;

      final api = Provider.of<ApiService>(context, listen: false);
      final savedPath = await api.downloadTaskAttachment(
          task.id, attachment.id, downloadName);

      if (!mounted) return;

      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File downloaded successfully'),
          ),
        );
      } else {
        final error = api.errorMessage ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file: $error')),
        );
      }
    } catch (error) {
      debugPrint('Download error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingAttachmentId = null;
        });
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13))),
        Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AspireColors.secondary),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAttachmentsWidget(
      BuildContext context, Task task, User currentUser) {
    bool canUpload = false;
    final allowedRoles = ['super_admin', 'admin', 'manager', 'team_leader'];
    if (allowedRoles.contains(currentUser.role)) {
      canUpload = true;
    } else if (currentUser.role == 'staff') {
      if (task.assignedTo == currentUser.id ||
          task.assignedBy == currentUser.id) {
        canUpload = true;
      }
    }

    return Column(
      children: [
        // Upload trigger
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: OutlinedButton.icon(
            onPressed: canUpload ? _pickAndUploadFile : null,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Upload Document'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40)),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: task.attachments.isEmpty
              ? const Center(
                  child: Text('No attachments uploaded.',
                      style: TextStyle(fontSize: 12)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: task.attachments.length,
                  itemBuilder: (context, index) {
                    final item = task.attachments[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file,
                            color: Colors.amber),
                        title: Text(item.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text('By: ${item.uploadedByName}',
                            style: const TextStyle(fontSize: 10)),
                        trailing: _downloadingAttachmentId == item.id
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.download, size: 18),
                                onPressed: () =>
                                    _downloadAttachment(task, item),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskChatWidget(
      BuildContext context, Task task, User currentUser) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Column(
      children: [
        Expanded(
          child: task.comments.isEmpty
              ? const Center(
                  child: Text('No messages yet.\nStart the conversation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey)))
              : ListView.builder(
                  controller: _chatScrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: task.comments.length,
                  itemBuilder: (context, index) {
                    final c = task.comments[index];
                    final isMe = c.userId == currentUser.id;

                    // Basic Date Separator logic
                    bool showDate = false;
                    if (index == 0) {
                      showDate = true;
                    } else {
                      final prevDate =
                          DateTime.parse(task.comments[index - 1].createdAt)
                              .toLocal();
                      final currDate = DateTime.parse(c.createdAt).toLocal();
                      if (prevDate.year != currDate.year ||
                          prevDate.month != currDate.month ||
                          prevDate.day != currDate.day) {
                        showDate = true;
                      }
                    }

                    String dateLabel = '';
                    if (showDate) {
                      final currDate = DateTime.parse(c.createdAt).toLocal();
                      final now = DateTime.now();
                      if (currDate.year == now.year &&
                          currDate.month == now.month &&
                          currDate.day == now.day) {
                        dateLabel = 'Today';
                      } else if (currDate.year == now.year &&
                          currDate.month == now.month &&
                          currDate.day == now.day - 1) {
                        dateLabel = 'Yesterday';
                      } else {
                        dateLabel =
                            '${currDate.day}/${currDate.month}/${currDate.year}';
                      }
                    }

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(dateLabel,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold)),
                          ),
                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).primaryColor
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[800]
                                        : Colors.grey[200]),
                                borderRadius:
                                    BorderRadius.circular(16).copyWith(
                                  bottomRight: isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(16),
                                  bottomLeft: !isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(c.userName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12)),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.userRole.toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  if (!isMe) const SizedBox(height: 4),
                                  if (c.messageType == 'voice')
                                    VoiceMessageBubble(
                                      audioUrl: c.audioUrl != null &&
                                              c.audioUrl!.startsWith('http')
                                          ? c.audioUrl
                                          : '${AppConstants.apiBaseUrl.replaceAll('/api', '')}${c.audioUrl}',
                                      isMe: isMe,
                                    )
                                  else
                                    Text(c.comment,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: isMe ? Colors.white : null)),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      '${DateTime.parse(c.createdAt).toLocal().hour.toString().padLeft(2, '0')}:${DateTime.parse(c.createdAt).toLocal().minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Chat input field
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop_circle : Icons.mic,
                  color: _isRecording ? Colors.red : Colors.grey,
                  size: _isRecording ? 28 : 24,
                ),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  enabled: !_isRecording,
                  decoration: InputDecoration(
                    hintText: _isRecording
                        ? 'Recording voice message...'
                        : 'Type a message...',
                    border: const OutlineInputBorder(),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _postComment(task),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () => _postComment(task),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  void _showMobileDrawer(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: content,
          ),
        );
      },
    );
  }

  String _activityMessage(ActivityLogItem item) {
    switch (item.action) {
      case 'task_created':
      case 'created':
        return '${item.userName} created this task';

      case 'task_assigned':
        return '${item.userName} assigned this task to ${item.newValue ?? 'an employee'}';

      case 'task_reassigned':
      case 'reassigned':
        return '${item.userName} reassigned this task from ${item.oldValue ?? 'previous employee'} to ${item.newValue ?? 'new employee'}';

      case 'status_changed':
        return '${item.userName} changed task status from ${getTaskStatusLabel(item.oldValue ?? '')} to ${getTaskStatusLabel(item.newValue ?? '')}';

      case 'submitted_for_review':
        return '${item.userName} submitted this task for Management review';

      case 'task_completed':
        return '${item.userName} approved and completed this task';

      case 'voice_message_sent':
        return '${item.userName} sent a voice message';

      case 'file_uploaded':
        return '${item.userName} uploaded “${item.newValue ?? 'file'}”';

      case 'file_downloaded':
        return '${item.userName} downloaded “${item.newValue ?? 'file'}”';

      case 'progress_updated':
        return '${item.userName} updated task progress';

      case 'priority_changed':
        return '${item.userName} changed task priority';

      default:
        return '${item.userName} performed ${item.action}';
    }
  }

  Widget _buildActivityLogWidget(BuildContext context) {
    final api = Provider.of<ApiService>(context, listen: false);
    return FutureBuilder<List<ActivityLogItem>>(
      future: api.fetchTaskHistory(widget.taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Text('Unable to load activity log'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                )
              ]));
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const Center(
              child: Text('No activity recorded for this task yet.',
                  style: TextStyle(fontSize: 12)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            IconData icon = Icons.info_outline;
            Color iconColor = Colors.grey;

            switch (log.action) {
              case 'task_created':
              case 'created':
                icon = Icons.add_circle_outline;
                iconColor = Colors.green;
                break;
              case 'task_assigned':
                icon = Icons.person_add_alt_1;
                iconColor = Colors.blueAccent;
                break;
              case 'task_reassigned':
              case 'reassigned':
                icon = Icons.swap_horiz;
                iconColor = Colors.purple;
                break;
              case 'status_changed':
                icon = Icons.sync_alt;
                iconColor = Colors.blue;
                break;
              case 'submitted_for_review':
                icon = Icons.rate_review_outlined;
                iconColor = Colors.orangeAccent;
                break;
              case 'task_completed':
                icon = Icons.check_circle_outline;
                iconColor = Colors.green;
                break;
              case 'voice_message_sent':
                icon = Icons.mic_none_rounded;
                iconColor = Colors.teal;
                break;
              case 'file_uploaded':
                icon = Icons.upload_file_rounded;
                iconColor = Colors.deepPurple;
                break;
              case 'file_downloaded':
                icon = Icons.download_rounded;
                iconColor = Colors.indigo;
                break;
              case 'priority_changed':
                icon = Icons.priority_high;
                iconColor = Colors.orange;
                break;
              case 'progress_updated':
                icon = Icons.trending_up;
                iconColor = Colors.teal;
                break;
            }

            final dateStr =
                "${log.createdAt.day} ${_getMonth(log.createdAt.month)} ${log.createdAt.year} • ${_formatTime(log.createdAt)}";

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activityMessage(log),
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour;
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    String minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
