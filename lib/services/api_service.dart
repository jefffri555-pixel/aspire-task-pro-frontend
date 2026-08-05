import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../models/lead.dart';
import '../models/dashboard_stats.dart';
import '../models/department.dart';
import '../models/attendance.dart';
import '../models/leave_request.dart';
import 'storage_service.dart';
import '../utils/download_helper.dart';

class ApiService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _useMockFallback = false;

  // Mock Database State (for standalone frontend demo mode)
  List<User> _mockUsers = [];
  List<Project> _mockProjects = [];
  List<Task> _mockTasks = [];
  List<Lead> _mockLeads = [];
  List<Department> _mockDepartments = [];
  List<Attendance> _mockAttendance = [];
  List<LeaveRequest> _mockLeaves = [];

  ApiService() {
    _currentUser = StorageService.getUser();
    final token = StorageService.getToken();
    if (token != null &&
        (token.startsWith('mock_jwt_token_for_') ||
            token == 'mock_jwt_token')) {
      _useMockFallback = true;
    }
    _initializeMockDatabase();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUsingMockFallback => _useMockFallback;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // HTTP Helper headers
  Map<String, String> _getHeaders() {
    final token = StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // AUTHENTICATION API
  // ==========================================

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'loginIdentifier': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = User.fromJson(data['user']);

        await StorageService.setToken(token);
        await StorageService.setUser(user);

        _currentUser = user;
        _useMockFallback = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['error'] ?? 'Login failed';
      }
    } catch (e) {
      print('API Error (login), falling back to mock login: $e');
      // Simulated fallback auth logic
      final matchedMock = _mockUsers.firstWhere(
        (u) => u.email == identifier || u.phone == identifier,
        orElse: () => throw Exception('Employee record not found in database.'),
      );

      _currentUser = matchedMock;
      await StorageService.setToken('mock_jwt_token_for_${matchedMock.email}');
      await StorageService.setUser(matchedMock);

      _useMockFallback = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await StorageService.clearSession();
    _currentUser = null;
    _useMockFallback = false;
    notifyListeners();
  }

  Future<bool> forgotPassword(String identifier) async {
    try {
      if (_useMockFallback) return true;
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'loginIdentifier': identifier}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return true; // Simulate success
    }
  }

  // ==========================================
  // DASHBOARD & ANALYTICS API
  // ==========================================

  Future<DashboardStats?> fetchDashboardStats() async {
    if (_useMockFallback) {
      return _generateMockStats();
    }

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/reports/dashboard'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return DashboardStats.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('Dashboard API failed, falling back: $e');
    }
    return _generateMockStats();
  }

  // ==========================================
  // EMPLOYEE/USER REGISTRY API
  // ==========================================

  Future<List<User>> fetchUsers({String? departmentId}) async {
    if (_useMockFallback) {
      if (departmentId != null) {
        return _mockUsers.where((u) => u.departmentId == departmentId).toList();
      }
      return _mockUsers;
    }

    try {
      String url = '${AppConstants.apiBaseUrl}/users';
      if (departmentId != null) {
        url += '?department_id=$departmentId';
      }
      final res = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => User.fromJson(item)).toList();
      }
    } catch (e) {
      print('Users Fetch Error: $e');
    }
    return _mockUsers;
  }

  Future<User?> createUser(Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final newUser = User(
        id: 'user_mock_${DateTime.now().millisecondsSinceEpoch}',
        employeeId: 'EMP-${1000 + _mockUsers.length + 1}',
        name: data['name'],
        email: data['email'],
        phone: data['phone'],
        role: data['role'],
        designation: data['designation'],
        departmentId: data['department_id'],
        departmentName: _getDeptName(data['department_id']),
        joiningDate: data['joining_date'] ?? DateTime.now().toString(),
        reportingManagerId: data['reporting_manager_id'],
        teamLeaderId: data['team_leader_id'],
        performanceScore: 100.0,
      );
      _mockUsers.add(newUser);
      notifyListeners();
      return newUser;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/users'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        return User.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<User?> updateUser(String id, Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final index = _mockUsers.indexWhere((u) => u.id == id);
      if (index != -1) {
        final existing = _mockUsers[index];
        final updated = User(
          id: existing.id,
          employeeId: existing.employeeId,
          name: data['name'] ?? existing.name,
          email: data['email'] ?? existing.email,
          phone: data['phone'] ?? existing.phone,
          role: data['role'] ?? existing.role,
          designation: data['designation'] ?? existing.designation,
          departmentId: data['department_id'] ?? existing.departmentId,
          departmentName: data['department_id'] != null
              ? _getDeptName(data['department_id'])
              : existing.departmentName,
          joiningDate: existing.joiningDate,
          reportingManagerId:
              data['reporting_manager_id'] ?? existing.reportingManagerId,
          teamLeaderId: data['team_leader_id'] ?? existing.teamLeaderId,
          performanceScore: data['performance_score'] != null
              ? double.parse(data['performance_score'].toString())
              : existing.performanceScore,
        );
        _mockUsers[index] = updated;
        if (_currentUser?.id == id) {
          _currentUser = updated;
          StorageService.setUser(updated);
        }
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/users/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        final updated = User.fromJson(jsonDecode(res.body));
        if (_currentUser?.id == id) {
          _currentUser = updated;
          StorageService.setUser(updated);
        }
        notifyListeners();
        return updated;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<bool> deleteUser(String id) async {
    if (_useMockFallback) {
      _mockUsers.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    }
    try {
      final res = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/users/$id'),
        headers: _getHeaders(),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // SUPER ADMIN API
  // ==========================================

  Future<DashboardStats?> fetchAdminDashboard() async {
    if (_useMockFallback) {
      return _generateMockStats();
    }
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/dashboard'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final totals = decoded['totals'] ?? {};
        return DashboardStats(
          role: 'admin',
          managerCards: {
            'totalProjects': totals['projects'] ?? 0,
            'activeProjects': totals['projects'] ?? 0,
            'completedProjects': 0,
            'totalEmployees': totals['users'] ?? 0,
            'totalTeamLeaders': 0,
            'pendingTasksCount': totals['tasks'] ?? 0,
          },
          managerSummary: {
            'totalTasks': totals['tasks'] ?? 0,
            'completedTasks': 0,
            'pendingTasks': totals['tasks'] ?? 0,
            'inProgressTasks': 0,
            'overdueTasks': 0,
            'completionPercentage': 0,
          },
        );
      }
    } catch (e) {
      print('Admin Dashboard Fetch Error: $e');
    }
    return _generateMockStats();
  }

  Future<Map<String, dynamic>?> fetchAdminStatistics() async {
    if (_useMockFallback) {
      return {
        'taskStatusStats': [
          {'status': 'pending', 'count': 1},
          {'status': 'in_progress', 'count': 1},
          {'status': 'waiting_for_review', 'count': 1},
          {'status': 'completed', 'count': 1}
        ],
        'leadStatusStats': [
          {'status': 'new_lead', 'count': 1},
          {'status': 'follow_up', 'count': 1},
          {'status': 'booking_confirmed', 'count': 1}
        ],
        'departmentStats': [
          {
            'department_name': 'Sales & Marketing',
            'user_count': 2,
            'project_count': 1
          },
          {
            'department_name': 'Operations & Bookings',
            'user_count': 1,
            'project_count': 1
          },
          {
            'department_name': 'Finance & Administration',
            'user_count': 2,
            'project_count': 1
          }
        ],
        'topPerformers': [
          {
            'name': 'Vikram Malhotra',
            'designation': 'General Manager',
            'performance_score': 98.50
          },
          {
            'name': 'Anjali Sharma',
            'designation': 'Sales Team Leader',
            'performance_score': 92.00
          },
          {
            'name': 'Rohan Das',
            'designation': 'Senior Sales Executive',
            'performance_score': 88.00
          }
        ]
      };
    }
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/statistics'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (e) {
      print('Admin Statistics Fetch Error: $e');
    }
    return null;
  }

  Future<List<User>> fetchAdminUsers() async {
    if (_useMockFallback) return _mockUsers;
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/users'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => User.fromJson(item)).toList();
      }
    } catch (e) {
      print('Admin Fetch Users Error: $e');
    }
    return _mockUsers;
  }

  Future<User?> createAdminUser(Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final newUser = User(
        id: 'user_mock_${DateTime.now().millisecondsSinceEpoch}',
        employeeId: 'EMP-${1000 + _mockUsers.length + 1}',
        name: data['name'],
        email: data['email'],
        phone: data['phone'],
        role: data['role'],
        designation: data['designation'],
        departmentId: data['department_id'],
        departmentName: _getDeptName(data['department_id']),
        joiningDate: data['joining_date'] ?? DateTime.now().toString(),
        reportingManagerId: data['reporting_manager_id'],
        teamLeaderId: data['team_leader_id'],
        performanceScore: 100.0,
        status: data['status'] ?? 'active',
        profileImage: data['profile_image'],
      );
      _mockUsers.add(newUser);
      notifyListeners();
      return newUser;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/users'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        return User.fromJson(jsonDecode(res.body));
      } else if (res.statusCode == 409) {
        final err = jsonDecode(res.body);
        throw Exception(err['message'] ?? 'Employee ID already exists');
      } else {
        final err = jsonDecode(res.body);
        _errorMessage =
            err['error'] ?? err['message'] ?? 'Failed to create user';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<User?> updateAdminUser(String id, Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final index = _mockUsers.indexWhere((u) => u.id == id);
      if (index != -1) {
        final existing = _mockUsers[index];
        final updated = User(
          id: existing.id,
          employeeId: existing.employeeId,
          name: data['name'] ?? existing.name,
          email: data['email'] ?? existing.email,
          phone: data['phone'] ?? existing.phone,
          role: data['role'] ?? existing.role,
          designation: data['designation'] ?? existing.designation,
          departmentId: data['department_id'] ?? existing.departmentId,
          departmentName: data['department_id'] != null
              ? _getDeptName(data['department_id'])
              : existing.departmentName,
          joiningDate: existing.joiningDate,
          reportingManagerId:
              data['reporting_manager_id'] ?? existing.reportingManagerId,
          teamLeaderId: data['team_leader_id'] ?? existing.teamLeaderId,
          performanceScore: data['performance_score'] != null
              ? double.parse(data['performance_score'].toString())
              : existing.performanceScore,
          status: data['status'] ?? existing.status,
          profileImage: data.containsKey('profile_image')
              ? data['profile_image']
              : existing.profileImage,
        );
        _mockUsers[index] = updated;
        if (_currentUser?.id == id) {
          _currentUser = updated;
          StorageService.setUser(updated);
        }
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/users/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        final updated = User.fromJson(jsonDecode(res.body));
        if (_currentUser?.id == id) {
          _currentUser = updated;
          StorageService.setUser(updated);
        }
        notifyListeners();
        return updated;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to update user';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<bool> deleteAdminUser(String id) async {
    if (_useMockFallback) {
      _mockUsers.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    }
    try {
      final res = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/users/$id'),
        headers: _getHeaders(),
      );
      return res.statusCode == 200;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> adminResetPassword(String userId, String newPassword) async {
    if (_useMockFallback) {
      return true;
    }
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/reset-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'newPassword': newPassword,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deactivateUser(String id) async {
    if (_useMockFallback) {
      final index = _mockUsers.indexWhere((u) => u.id == id);
      if (index != -1) {
        final existing = _mockUsers[index];
        _mockUsers[index] = User(
          id: existing.id,
          employeeId: existing.employeeId,
          name: existing.name,
          email: existing.email,
          phone: existing.phone,
          role: existing.role,
          designation: existing.designation,
          departmentId: existing.departmentId,
          departmentName: existing.departmentName,
          joiningDate: existing.joiningDate,
          reportingManagerId: existing.reportingManagerId,
          teamLeaderId: existing.teamLeaderId,
          performanceScore: existing.performanceScore,
          status: 'deactivated',
          profileImage: existing.profileImage,
        );
        notifyListeners();
        return true;
      }
      return false;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/users/$id/deactivate'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  Future<bool> activateUser(String id) async {
    if (_useMockFallback) {
      final index = _mockUsers.indexWhere((u) => u.id == id);
      if (index != -1) {
        final existing = _mockUsers[index];
        _mockUsers[index] = User(
          id: existing.id,
          employeeId: existing.employeeId,
          name: existing.name,
          email: existing.email,
          phone: existing.phone,
          role: existing.role,
          designation: existing.designation,
          departmentId: existing.departmentId,
          departmentName: existing.departmentName,
          joiningDate: existing.joiningDate,
          reportingManagerId: existing.reportingManagerId,
          teamLeaderId: existing.teamLeaderId,
          performanceScore: existing.performanceScore,
          status: 'active',
          profileImage: existing.profileImage,
        );
        notifyListeners();
        return true;
      }
      return false;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/users/$id/activate'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  Future<String?> uploadProfilePhoto(List<int> bytes, String filename) async {
    if (_useMockFallback) {
      return '/uploads/profile_mock_${DateTime.now().millisecondsSinceEpoch}_$filename';
    }

    try {
      final uri =
          Uri.parse('${AppConstants.apiBaseUrl}/admin/users/upload-image');
      final request = http.MultipartRequest('POST', uri);

      final token = StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'];
      } else {
        print('Upload failed status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload Profile Image Exception: $e');
    }
    return null;
  }

  // ==========================================
  // PROJECT MANAGEMENT API
  // ==========================================

  Future<List<Project>> fetchProjects(
      {String? status, String? priority}) async {
    if (_useMockFallback) {
      var projects = _mockProjects;
      if (_currentUser?.role == 'team_leader' ||
          _currentUser?.role == 'staff') {
        projects = projects
            .where((p) => p.assignedTeamId == _currentUser?.departmentId)
            .toList();
      }
      if (status != null && status.isNotEmpty) {
        projects = projects.where((p) => p.status == status).toList();
      }
      if (priority != null && priority.isNotEmpty) {
        projects = projects.where((p) => p.priority == priority).toList();
      }
      return projects;
    }

    try {
      String queryParams = '?';
      if (status != null && status.isNotEmpty) queryParams += 'status=$status&';
      if (priority != null && priority.isNotEmpty)
        queryParams += 'priority=$priority&';

      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/projects$queryParams'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Project.fromJson(item)).toList();
      }
    } catch (e) {
      print('Projects Fetch Error: $e');
    }
    return _mockProjects;
  }

  Future<Project?> fetchProjectById(String id) async {
    if (_useMockFallback) {
      final index = _mockProjects.indexWhere((p) => p.id == id);
      if (index != -1) {
        final project = _mockProjects[index];
        // Populate tasks under project
        final projectTasks =
            _mockTasks.where((t) => t.projectId == id).toList();
        return Project(
          id: project.id,
          projectId: project.projectId,
          name: project.name,
          clientName: project.clientName,
          startDate: project.startDate,
          dueDate: project.dueDate,
          priority: project.priority,
          status: project.status,
          assignedTeamId: project.assignedTeamId,
          assignedTeamName: project.assignedTeamName,
          progressPercentage: project.progressPercentage,
          createdAt: project.createdAt,
          updatedAt: project.updatedAt,
          tasks: projectTasks,
        );
      }
      return null;
    }

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/projects/$id'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return Project.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('Project Detail Fetch Error: $e');
    }
    return null;
  }

  Future<Project?> createProject(Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final newProject = Project(
        id: 'prj_mock_${DateTime.now().millisecondsSinceEpoch}',
        projectId: 'PRJ-${1000 + _mockProjects.length + 1}',
        name: data['name'],
        clientName: data['client_name'],
        startDate: data['start_date'],
        dueDate: data['due_date'],
        priority: data['priority'] ?? 'medium',
        status: 'not_started',
        assignedTeamId: data['assigned_team_id'],
        assignedTeamName: _getDeptName(data['assigned_team_id']),
        progressPercentage: 0,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      );
      _mockProjects.add(newProject);
      notifyListeners();
      return newProject;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/projects'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        final newProject = Project.fromJson(jsonDecode(res.body));
        notifyListeners();
        return newProject;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<Project?> updateProject(String id, Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final index = _mockProjects.indexWhere((p) => p.id == id);
      if (index != -1) {
        final existing = _mockProjects[index];
        final updated = Project(
          id: existing.id,
          projectId: existing.projectId,
          name: data['name'] ?? existing.name,
          clientName: data['client_name'] ?? existing.clientName,
          startDate: data['start_date'] ?? existing.startDate,
          dueDate: data['due_date'] ?? existing.dueDate,
          priority: data['priority'] ?? existing.priority,
          status: data['status'] ?? existing.status,
          assignedTeamId: data['assigned_team_id'] ?? existing.assignedTeamId,
          assignedTeamName: data['assigned_team_id'] != null
              ? _getDeptName(data['assigned_team_id'])
              : existing.assignedTeamName,
          progressPercentage: data['progress_percentage'] != null
              ? int.parse(data['progress_percentage'].toString())
              : existing.progressPercentage,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now().toString(),
        );
        _mockProjects[index] = updated;
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/projects/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        final updatedProject = Project.fromJson(jsonDecode(res.body));
        notifyListeners();
        return updatedProject;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<bool> deleteProject(String id) async {
    if (_useMockFallback) {
      _mockProjects.removeWhere((p) => p.id == id);
      _mockTasks.removeWhere((t) => t.projectId == id);
      notifyListeners();
      return true;
    }
    try {
      final res = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/projects/$id'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  // ==========================================
  // TASK MANAGEMENT API
  // ==========================================

  Future<Map<String, dynamic>?> fetchEmployeeTaskHistory(
      String employeeId) async {
    if (_useMockFallback) {
      try {
        final user = _mockUsers.firstWhere((u) => u.id == employeeId);
        final tasks =
            _mockTasks.where((t) => t.assignedTo == employeeId).toList();
        return {
          'employee': user,
          'summary': {
            'total': tasks.length,
            'completed': tasks.where((t) => t.status == 'completed').length,
            'pending': tasks.where((t) => t.status == 'pending').length,
            'in_progress': tasks.where((t) => t.status == 'in_progress').length,
            'waiting_for_review':
                tasks.where((t) => t.status == 'waiting_for_review').length,
          },
          'tasks': tasks,
        };
      } catch (e) {
        return null;
      }
    }

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/users/$employeeId/tasks'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'employee': User.fromJson(data['employee']),
          'summary': data['summary'],
          'tasks':
              (data['tasks'] as List).map((t) => Task.fromJson(t)).toList(),
        };
      }
    } catch (e) {
      print('Fetch Employee Task History Error: $e');
    }
    return null;
  }

  Future<List<Task>> fetchTasks({String? status, String? priority}) async {
    if (_useMockFallback) {
      var tasks = _mockTasks;
      if (_currentUser?.role == 'staff') {
        tasks = tasks.where((t) => t.assignedTo == _currentUser?.id).toList();
      }
      if (status != null && status.isNotEmpty) {
        tasks = tasks.where((t) => t.status == status).toList();
      }
      if (priority != null && priority.isNotEmpty) {
        tasks = tasks.where((t) => t.priority == priority).toList();
      }
      return tasks;
    }

    try {
      String queryParams = '?';
      if (status != null) queryParams += 'status=$status&';
      if (priority != null) queryParams += 'priority=$priority&';

      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks$queryParams'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Task.fromJson(item)).toList();
      }
    } catch (e) {
      print('Tasks API Error: $e');
    }
    return _mockTasks;
  }

  Future<List<Task>> fetchCalendarTasks(
      {String? startDate, String? endDate}) async {
    if (_useMockFallback) {
      var tasks = _mockTasks;
      if (_currentUser?.role == 'staff') {
        tasks = tasks.where((t) => t.assignedTo == _currentUser?.id).toList();
      } else if (_currentUser?.role == 'team_leader') {
        tasks = tasks
            .where((t) =>
                t.departmentId == _currentUser?.departmentId ||
                t.assignedTo == _currentUser?.id ||
                t.assignedBy == _currentUser?.id)
            .toList();
      }

      if (startDate != null && endDate != null) {
        final start = DateTime.tryParse(startDate);
        final end = DateTime.tryParse(endDate);
        if (start != null && end != null) {
          tasks = tasks.where((t) {
            final dueDate = DateTime.tryParse(t.dueDate ?? '');
            if (dueDate == null) return false;
            return !dueDate.isBefore(start) && !dueDate.isAfter(end);
          }).toList();
        }
      }
      return tasks;
    }

    try {
      String queryParams = '?';
      if (startDate != null) queryParams += 'start_date=$startDate&';
      if (endDate != null) queryParams += 'end_date=$endDate&';

      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/calendar$queryParams'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Task.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load calendar tasks');
      }
    } catch (e) {
      print('Calendar Tasks API Error: $e');
      rethrow;
    }
  }

  Future<Task?> fetchTaskById(String id) async {
    if (_useMockFallback) {
      return _mockTasks.firstWhere((t) => t.id == id);
    }
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/$id'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return Task.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('Task Detail Error: $e');
    }
    return _mockTasks.firstWhere((t) => t.id == id);
  }

  Future<Task?> createTask(Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final newTask = Task(
        id: 'task_mock_${DateTime.now().millisecondsSinceEpoch}',
        taskId: 'TSK-${10000 + _mockTasks.length + 1}',
        title: data['title'],
        description: data['description'] ?? '',
        departmentId: data['department_id'],
        departmentName: _getDeptName(data['department_id']),
        priority: data['priority'] ?? 'medium',
        status: 'pending',
        startDate: data['start_date'],
        dueDate: data['due_date'],
        assignedBy: _currentUser?.id ?? '',
        assignedByName: _currentUser?.name ?? 'System',
        assignedTo: data['assigned_to'],
        assignedToName: _getUserName(data['assigned_to']),
        progressPercentage: 0,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      );
      _mockTasks.add(newTask);
      notifyListeners();
      return newTask;
    }

    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/tasks');
      final request = http.MultipartRequest('POST', uri);

      final token = StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      data.forEach((key, value) {
        if (value is http.MultipartFile) {
          request.files.add(value);
        } else if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final task = Task.fromJson(jsonDecode(response.body));
        notifyListeners();
        return task;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['error'] ?? 'Failed to create task';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<Task?> updateTask(String id, Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final idx = _mockTasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        final t = _mockTasks[idx];

        int progress = data['progress_percentage'] ?? t.progressPercentage;
        String status = data['status'] ?? t.status;

        if (progress == 0)
          status = 'pending';
        else if (progress > 0 && progress < 100)
          status = 'in_progress';
        else if (progress == 100 && status != 'completed')
          status = 'waiting_for_review';

        final updated = Task(
          id: t.id,
          taskId: t.taskId,
          title: data['title'] ?? t.title,
          description: data['description'] ?? t.description,
          departmentId: data['department_id'] ?? t.departmentId,
          departmentName: data['department_id'] != null
              ? _getDeptName(data['department_id'])
              : t.departmentName,
          priority: data['priority'] ?? t.priority,
          status: status,
          startDate: data['start_date'] ?? t.startDate,
          dueDate: data['due_date'] ?? t.dueDate,
          assignedBy: t.assignedBy,
          assignedByName: t.assignedByName,
          assignedTo: data['assigned_to'] ?? t.assignedTo,
          assignedToName: data['assigned_to'] != null
              ? _getUserName(data['assigned_to'])
              : t.assignedToName,
          progressPercentage: progress,
          completionNotes: data['completion_notes'] ?? t.completionNotes,
          createdAt: t.createdAt,
          updatedAt: DateTime.now().toString(),
          comments: t.comments,
          attachments: t.attachments,
        );
        _mockTasks[idx] = updated;
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        final task = Task.fromJson(jsonDecode(res.body));
        notifyListeners();
        return task;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>> markTaskAsCompleted({
    required String taskId,
  }) async {
    if (_useMockFallback) {
      // Mock fallback: just update locally
      final idx = _mockTasks.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        final t = _mockTasks[idx];
        String newStatus = t.status == 'in_review' ? 'completed' : 'in_review';
        _mockTasks[idx] = Task(
          id: t.id,
          taskId: t.taskId,
          title: t.title,
          description: t.description,
          departmentId: t.departmentId,
          departmentName: t.departmentName,
          priority: t.priority,
          status: newStatus,
          startDate: t.startDate,
          dueDate: t.dueDate,
          assignedBy: t.assignedBy,
          assignedByName: t.assignedByName,
          assignedTo: t.assignedTo,
          assignedToName: t.assignedToName,
          progressPercentage:
              newStatus == 'completed' ? 100 : t.progressPercentage,
          createdAt: t.createdAt,
          updatedAt: DateTime.now().toString(),
          comments: t.comments,
          attachments: t.attachments,
        );
        notifyListeners();
        return {
          'success': true,
          'task': {'id': taskId, 'status': newStatus} // minimal mock response
        };
      }
      throw Exception('Task not found');
    }

    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/$taskId/mark-completed'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Invalid server response');
      } else {
        String message = 'Unable to update task status';
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
        throw Exception(message);
      }
    } catch (error) {
      if (error is Exception) {
        throw error;
      }
      throw Exception('Unable to update task status: $error');
    }
  }

  Future<bool> deleteTask(String id) async {
    if (_useMockFallback) {
      _mockTasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    }
    try {
      final res = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/$id'),
        headers: _getHeaders(),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Task?> assignTask(String id, String assigneeId) async {
    if (_useMockFallback) {
      final idx = _mockTasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        final t = _mockTasks[idx];
        final updated = Task(
          id: t.id,
          taskId: t.taskId,
          title: t.title,
          description: t.description,
          departmentId: t.departmentId,
          departmentName: t.departmentName,
          priority: t.priority,
          status: 'pending', // Per requirements, keep it pending
          startDate: t.startDate,
          dueDate: t.dueDate,
          assignedBy: _currentUser?.id ?? '',
          assignedByName: _currentUser?.name ?? 'System',
          assignedTo: assigneeId,
          assignedToName: _getUserName(assigneeId),
          progressPercentage: t.progressPercentage,
          completionNotes: t.completionNotes,
          createdAt: t.createdAt,
          updatedAt: DateTime.now().toString(),
          comments: t.comments,
          attachments: t.attachments,
        );
        _mockTasks[idx] = updated;
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.patch(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/$id/assign'),
        headers: _getHeaders(),
        body: jsonEncode({'assigned_to': assigneeId}),
      );

      debugPrint('Assignment status: ${res.statusCode}');
      debugPrint('Assignment response: ${res.body}');

      if (res.statusCode != 200) {
        final Map<String, dynamic> errorData = jsonDecode(res.body);
        throw Exception(errorData['message'] ?? 'Failed to assign task');
      }

      final Map<String, dynamic> responseData = jsonDecode(res.body);
      final taskData = responseData['task'] ?? responseData;
      final task = Task.fromJson(taskData);
      notifyListeners();
      return task;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<bool> duplicateTask(String id) async {
    final original = await fetchTaskById(id);
    if (original == null) return false;

    final cloneMap = {
      'title': 'Copy of - ${original.title}',
      'description': original.description,
      'department_id': original.departmentId,
      'priority': original.priority,
      'start_date': DateTime.now().toString(),
      'due_date': DateTime.now().add(const Duration(days: 3)).toString(),
      'assigned_to': original.assignedTo
    };
    return await createTask(cloneMap) != null;
  }

  Future<bool> bulkAssign(Map<String, dynamic> data) async {
    final assignees = List<String>.from(data['assigned_to_list'] ?? []);
    bool status = true;
    for (var staffId in assignees) {
      final singleTask = {...data, 'assigned_to': staffId};
      final t = await createTask(singleTask);
      if (t == null) status = false;
    }
    return status;
  }

  Future<TaskComment?> addComment(String taskId, String content) async {
    if (_useMockFallback) {
      final taskIdx = _mockTasks.indexWhere((t) => t.id == taskId);
      if (taskIdx != -1) {
        final newComment = TaskComment(
          id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
          taskId: taskId,
          userId: _currentUser?.id ?? '',
          userName: _currentUser?.name ?? 'System',
          userRole: _currentUser?.role ?? 'staff',
          designation: _currentUser?.designation ?? '',
          comment: content,
          createdAt: DateTime.now().toString(),
        );
        final list = List<TaskComment>.from(_mockTasks[taskIdx].comments)
          ..add(newComment);
        _mockTasks[taskIdx] = Task(
          id: _mockTasks[taskIdx].id,
          taskId: _mockTasks[taskIdx].taskId,
          title: _mockTasks[taskIdx].title,
          description: _mockTasks[taskIdx].description,
          priority: _mockTasks[taskIdx].priority,
          status: _mockTasks[taskIdx].status,
          startDate: _mockTasks[taskIdx].startDate,
          dueDate: _mockTasks[taskIdx].dueDate,
          assignedBy: _mockTasks[taskIdx].assignedBy,
          assignedByName: _mockTasks[taskIdx].assignedByName,
          assignedTo: _mockTasks[taskIdx].assignedTo,
          assignedToName: _mockTasks[taskIdx].assignedToName,
          progressPercentage: _mockTasks[taskIdx].progressPercentage,
          createdAt: _mockTasks[taskIdx].createdAt,
          updatedAt: _mockTasks[taskIdx].updatedAt,
          comments: list,
          attachments: _mockTasks[taskIdx].attachments,
        );
        notifyListeners();
        return newComment;
      }
      return null;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/$taskId/comments'),
        headers: _getHeaders(),
        body: jsonEncode({'comment': content}),
      );
      if (res.statusCode == 201) {
        return TaskComment.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<TaskComment?> sendVoiceMessage({
    required String taskId,
    required Uint8List audioBytes,
    required String fileName,
    required String mimeType,
    required int durationSeconds,
  }) async {
    if (_useMockFallback) {
      final taskIdx = _mockTasks.indexWhere((t) => t.id == taskId);
      if (taskIdx != -1) {
        final newComment = TaskComment(
          id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
          taskId: taskId,
          userId: _currentUser?.id ?? '',
          userName: _currentUser?.name ?? 'System',
          userRole: _currentUser?.role ?? 'staff',
          designation: _currentUser?.designation ?? '',
          comment: '',
          messageType: 'voice',
          audioUrl: '/mock/audio.webm',
          audioFileName: fileName,
          audioMimeType: mimeType,
          audioDurationSeconds: durationSeconds,
          createdAt: DateTime.now().toString(),
        );
        final list = List<TaskComment>.from(_mockTasks[taskIdx].comments)
          ..add(newComment);
        _mockTasks[taskIdx] = Task(
          id: _mockTasks[taskIdx].id,
          taskId: _mockTasks[taskIdx].taskId,
          title: _mockTasks[taskIdx].title,
          description: _mockTasks[taskIdx].description,
          priority: _mockTasks[taskIdx].priority,
          status: _mockTasks[taskIdx].status,
          startDate: _mockTasks[taskIdx].startDate,
          dueDate: _mockTasks[taskIdx].dueDate,
          assignedBy: _mockTasks[taskIdx].assignedBy,
          assignedByName: _mockTasks[taskIdx].assignedByName,
          assignedTo: _mockTasks[taskIdx].assignedTo,
          assignedToName: _mockTasks[taskIdx].assignedToName,
          progressPercentage: _mockTasks[taskIdx].progressPercentage,
          createdAt: _mockTasks[taskIdx].createdAt,
          updatedAt: _mockTasks[taskIdx].updatedAt,
          comments: list,
          attachments: _mockTasks[taskIdx].attachments,
        );
        notifyListeners();
        return newComment;
      }
      return null;
    }

    try {
      final uri =
          Uri.parse('${AppConstants.apiBaseUrl}/tasks/$taskId/voice-messages');
      final request = http.MultipartRequest('POST', uri);

      final token = StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['duration_seconds'] = durationSeconds.toString();

      final multipartFile = http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return TaskComment.fromJson(jsonDecode(response.body));
      } else {
        print(
            'Upload failed status code: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      print('Send voice message exception: $e');
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<TaskAttachment?> addAttachmentMock(
      String taskId, String fileName) async {
    // Generates simulated attachment inside mock framework
    final taskIdx = _mockTasks.indexWhere((t) => t.id == taskId);
    if (taskIdx != -1) {
      final data = {
        'original_name': fileName,
        'file_name': fileName,
      };

      final newAttach = TaskAttachment(
        id: 'attach_${DateTime.now().millisecondsSinceEpoch}',
        taskId: taskId,
        fileUrl: 'https://cloudinary.mock.com/files/$fileName',
        fileName: fileName,
        originalName: data['original_name']?.toString() ??
            data['originalName']?.toString() ??
            data['file_name']?.toString() ??
            data['fileName']?.toString() ??
            'attachment',
        mimeType: 'application/octet-stream',
        uploadedBy: _currentUser?.id ?? 'system-id',
        uploadedByName: _currentUser?.name ?? 'System',
        createdAt: DateTime.now().toString(),
      );
      final list = List<TaskAttachment>.from(_mockTasks[taskIdx].attachments)
        ..add(newAttach);
      _mockTasks[taskIdx] = Task(
        id: _mockTasks[taskIdx].id,
        taskId: _mockTasks[taskIdx].taskId,
        title: _mockTasks[taskIdx].title,
        description: _mockTasks[taskIdx].description,
        priority: _mockTasks[taskIdx].priority,
        status: _mockTasks[taskIdx].status,
        startDate: _mockTasks[taskIdx].startDate,
        dueDate: _mockTasks[taskIdx].dueDate,
        assignedBy: _mockTasks[taskIdx].assignedBy,
        assignedByName: _mockTasks[taskIdx].assignedByName,
        assignedTo: _mockTasks[taskIdx].assignedTo,
        assignedToName: _mockTasks[taskIdx].assignedToName,
        progressPercentage: _mockTasks[taskIdx].progressPercentage,
        createdAt: _mockTasks[taskIdx].createdAt,
        updatedAt: _mockTasks[taskIdx].updatedAt,
        comments: _mockTasks[taskIdx].comments,
        attachments: list,
      );
      notifyListeners();
      return newAttach;
    }
    return null;
  }

  Future<bool> uploadTaskAttachment(
      String taskId, List<int> bytes, String filename) async {
    if (_useMockFallback) {
      await addAttachmentMock(taskId, filename);
      return true;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/$taskId/attachments'),
      );
      request.headers.addAll(_getHeaders());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
      final response = await request.send();
      if (response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        try {
          final errMap = jsonDecode(respStr);
          _errorMessage = errMap['message'] ?? 'Failed to upload attachment';
        } catch (_) {
          _errorMessage = 'Failed to upload attachment';
        }
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  Future<String?> downloadTaskAttachment(
      String taskId, String attachmentId, String filename) async {
    if (_useMockFallback) {
      return null;
    }

    try {
      final res = await http.get(
        Uri.parse(
            '${AppConstants.apiBaseUrl}/tasks/$taskId/attachments/$attachmentId/download'),
        headers: _getHeaders(),
      );

      if (res.statusCode == 200) {
        final mimeType =
            res.headers['content-type'] ?? 'application/octet-stream';
        final savedPath =
            await downloadAndSaveFile(res.bodyBytes, filename, mimeType);
        return savedPath;
      } else {
        _errorMessage = 'Failed to download file';
      }
    } catch (e) {
      debugPrint('API download error: $e');
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<List<ActivityLogItem>> fetchTaskHistory(String taskId) async {
    if (_useMockFallback) {
      return [
        ActivityLogItem(
          id: 'mock_h_1',
          taskId: taskId,
          userName: 'Super Admin',
          userRole: 'Super Admin',
          action: 'created',
          newValue: 'Task initialized',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        )
      ];
    }

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/tasks/$taskId/history'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => ActivityLogItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Task History Fetch Error: $e');
    }
    return [];
  }

  // ==========================================
  // LEAD MANAGEMENT API
  // ==========================================

  Future<List<Lead>> fetchLeads() async {
    if (_useMockFallback) return _mockLeads;

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/leads'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Lead.fromJson(item)).toList();
      }
    } catch (e) {
      print('Leads Fetch Error: $e');
    }
    return _mockLeads;
  }

  Future<Lead?> fetchLeadById(String id) async {
    if (_useMockFallback) {
      return _mockLeads.firstWhere((l) => l.id == id);
    }
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/leads/$id'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return Lead.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('Lead Detail Error: $e');
    }
    return _mockLeads.firstWhere((l) => l.id == id);
  }

  Future<Lead?> createLead(Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final newLead = Lead(
        id: 'lead_mock_${DateTime.now().millisecondsSinceEpoch}',
        leadName: data['lead_name'],
        mobileNumber: data['mobile_number'],
        destination: data['destination'],
        packageInterested: data['package_interested'],
        budget: double.parse(data['budget'].toString()),
        source: data['source'] ?? 'Direct Enquiry',
        status: 'new_lead',
        assignedStaffId: data['assigned_staff_id'],
        assignedStaffName: _getUserName(data['assigned_staff_id']),
        notes: data['notes'],
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      );
      _mockLeads.add(newLead);
      notifyListeners();
      return newLead;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/leads'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        final lead = Lead.fromJson(jsonDecode(res.body));
        notifyListeners();
        return lead;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<Lead?> updateLead(String id, Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final idx = _mockLeads.indexWhere((l) => l.id == id);
      if (idx != -1) {
        final existing = _mockLeads[idx];
        final updated = Lead(
          id: existing.id,
          leadName: data['lead_name'] ?? existing.leadName,
          mobileNumber: data['mobile_number'] ?? existing.mobileNumber,
          destination: data['destination'] ?? existing.destination,
          packageInterested:
              data['package_interested'] ?? existing.packageInterested,
          budget: data['budget'] != null
              ? double.parse(data['budget'].toString())
              : existing.budget,
          source: data['source'] ?? existing.source,
          status: data['status'] ?? existing.status,
          assignedStaffId:
              data['assigned_staff_id'] ?? existing.assignedStaffId,
          assignedStaffName: data['assigned_staff_id'] != null
              ? _getUserName(data['assigned_staff_id'])
              : existing.assignedStaffName,
          notes: data['notes'] ?? existing.notes,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now().toString(),
          followUps: existing.followUps,
        );
        _mockLeads[idx] = updated;
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/leads/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        final lead = Lead.fromJson(jsonDecode(res.body));
        notifyListeners();
        return lead;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<LeadFollowUp?> addFollowUp(String leadId, String notes) async {
    if (_useMockFallback) {
      final leadIdx = _mockLeads.indexWhere((l) => l.id == leadId);
      if (leadIdx != -1) {
        final newFollow = LeadFollowUp(
          id: 'follow_${DateTime.now().millisecondsSinceEpoch}',
          leadId: leadId,
          followUpDate: DateTime.now().toString(),
          notes: notes,
          createdAt: DateTime.now().toString(),
        );
        final list = List<LeadFollowUp>.from(_mockLeads[leadIdx].followUps)
          ..add(newFollow);
        _mockLeads[leadIdx] = Lead(
          id: _mockLeads[leadIdx].id,
          leadName: _mockLeads[leadIdx].leadName,
          mobileNumber: _mockLeads[leadIdx].mobileNumber,
          destination: _mockLeads[leadIdx].destination,
          packageInterested: _mockLeads[leadIdx].packageInterested,
          budget: _mockLeads[leadIdx].budget,
          source: _mockLeads[leadIdx].source,
          status: _mockLeads[leadIdx].status,
          assignedStaffId: _mockLeads[leadIdx].assignedStaffId,
          assignedStaffName: _mockLeads[leadIdx].assignedStaffName,
          notes: _mockLeads[leadIdx].notes,
          createdAt: _mockLeads[leadIdx].createdAt,
          updatedAt: DateTime.now().toString(),
          followUps: list,
        );
        notifyListeners();
        return newFollow;
      }
      return null;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/leads/$leadId/follow-up'),
        headers: _getHeaders(),
        body: jsonEncode({
          'follow_up_date': DateTime.now().toString(),
          'notes': notes,
        }),
      );
      if (res.statusCode == 201) {
        return LeadFollowUp.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  // ==========================================
  // LOCAL MOCK SIMULATOR SETUP
  // ==========================================

  void _initializeMockDatabase() {
    // 1. Setup departments & employees
    _mockUsers = [
      User(
        id: 'admin_1',
        employeeId: 'EMP-1000',
        name: 'Administrator',
        email: 'admin@aspire.com',
        phone: '9999999999',
        role: 'admin',
        designation: 'Super Admin',
        departmentId: 'dept_admin',
        departmentName: 'Finance & Administration',
        joiningDate: '2024-01-01',
        performanceScore: 100.00,
      ),
      User(
        id: 'mgr_1',
        employeeId: 'EMP-1001',
        name: 'Vikram Malhotra',
        email: 'manager@aspire.com',
        phone: '+919876543210',
        role: 'manager',
        designation: 'General Manager',
        departmentId: 'dept_admin',
        departmentName: 'Finance & Administration',
        joiningDate: '2024-01-15',
        performanceScore: 98.50,
      ),
      User(
        id: 'tl_1',
        employeeId: 'EMP-1002',
        name: 'Anjali Sharma',
        email: 'tl@aspire.com',
        phone: '+919876543211',
        role: 'team_leader',
        designation: 'Sales Team Leader',
        departmentId: 'dept_sales',
        departmentName: 'Sales & Marketing',
        joiningDate: '2024-06-10',
        reportingManagerId: 'mgr_1',
        performanceScore: 92.00,
      ),
      User(
        id: 'staff_1',
        employeeId: 'EMP-1003',
        name: 'Rohan Das',
        email: 'staff@aspire.com',
        phone: '+919876543212',
        role: 'staff',
        designation: 'Senior Sales Executive',
        departmentId: 'dept_sales',
        departmentName: 'Sales & Marketing',
        joiningDate: '2025-01-10',
        reportingManagerId: 'mgr_1',
        teamLeaderId: 'tl_1',
        performanceScore: 88.00,
      ),
      User(
        id: 'staff_2',
        employeeId: 'EMP-1004',
        name: 'Pooja Nair',
        email: 'pooja@aspire.com',
        phone: '+919876543213',
        role: 'staff',
        designation: 'Operations Associate',
        departmentId: 'dept_ops',
        departmentName: 'Operations & Bookings',
        joiningDate: '2025-02-01',
        reportingManagerId: 'mgr_1',
        teamLeaderId: 'tl_1',
        performanceScore: 85.50,
      ),
    ];

    // 2. Setup Tasks
    _mockTasks = [
      Task(
          id: 't_1',
          taskId: 'TSK-00001',
          projectId: 'prj_1',
          projectName: 'Europe Summer Extravaganza',
          title: 'Finalize Europe Summer Packages',
          description:
              'Create itinerary, cost sheet, and marketing banners for Switzerland and Paris summer tours.',
          departmentId: 'dept_sales',
          departmentName: 'Sales & Marketing',
          priority: 'high',
          status: 'in_progress',
          startDate:
              DateTime.now().subtract(const Duration(days: 2)).toString(),
          dueDate: DateTime.now().add(const Duration(days: 3)).toString(),
          assignedBy: 'mgr_1',
          assignedByName: 'Vikram Malhotra',
          assignedTo: 'tl_1',
          assignedToName: 'Anjali Sharma',
          progressPercentage: 45,
          createdAt:
              DateTime.now().subtract(const Duration(days: 2)).toString(),
          updatedAt: DateTime.now().toString(),
          comments: [
            TaskComment(
              id: 'c_1',
              taskId: 't_1',
              userId: 'tl_1',
              userName: 'Anjali Sharma',
              userRole: 'team_leader',
              designation: 'Sales Team Leader',
              comment:
                  'Spoke to Swiss tourism board. We will get special discount rates for group booking.',
              createdAt:
                  DateTime.now().subtract(const Duration(hours: 4)).toString(),
            ),
            TaskComment(
              id: 'c_2',
              taskId: 't_1',
              userId: 'mgr_1',
              userName: 'Vikram Malhotra',
              userRole: 'manager',
              designation: 'General Manager',
              comment:
                  'Excellent. Make sure we include family discount packages as well.',
              createdAt:
                  DateTime.now().subtract(const Duration(hours: 2)).toString(),
            ),
          ]),
      Task(
          id: 't_2',
          taskId: 'TSK-00002',
          projectId: 'prj_2',
          projectName: 'Maldives Luxury Group Bookings',
          title: 'Client Booking Confirmation - Mr. Mehta',
          description:
              'Follow up with hotel partners in Maldives to confirm ocean villa booking and airport transfers.',
          departmentId: 'dept_ops',
          departmentName: 'Operations & Bookings',
          priority: 'medium',
          status: 'waiting_for_review',
          startDate:
              DateTime.now().subtract(const Duration(days: 4)).toString(),
          dueDate: DateTime.now().subtract(const Duration(hours: 1)).toString(),
          assignedBy: 'tl_1',
          assignedByName: 'Anjali Sharma',
          assignedTo: 'staff_1',
          assignedToName: 'Rohan Das',
          progressPercentage: 100,
          completionNotes:
              'Hotel confirmed, waiting for receipt voucher upload.',
          createdAt:
              DateTime.now().subtract(const Duration(days: 4)).toString(),
          updatedAt: DateTime.now().toString(),
          comments: [
            TaskComment(
              id: 'c_3',
              taskId: 't_2',
              userId: 'staff_1',
              userName: 'Rohan Das',
              userRole: 'staff',
              designation: 'Senior Sales Executive',
              comment:
                  'Villas are fully booked. Managed to secure a free upgrade to Water Suite.',
              createdAt:
                  DateTime.now().subtract(const Duration(days: 1)).toString(),
            ),
          ]),
      Task(
        id: 't_3',
        taskId: 'TSK-00003',
        title: 'Monthly GST Filing',
        description:
            'Prepare and file GST reports for June bookings and generate transaction statements.',
        departmentId: 'dept_admin',
        departmentName: 'Finance & Administration',
        priority: 'low',
        status: 'completed',
        startDate: DateTime.now().subtract(const Duration(days: 10)).toString(),
        dueDate: DateTime.now().subtract(const Duration(days: 5)).toString(),
        assignedBy: 'mgr_1',
        assignedByName: 'Vikram Malhotra',
        assignedTo: 'mgr_1',
        assignedToName: 'Vikram Malhotra',
        progressPercentage: 100,
        completionNotes: 'GST Filed. Ack number is GST998273612.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)).toString(),
        updatedAt: DateTime.now().toString(),
      ),
    ];

    // 3. Setup Leads
    _mockLeads = [
      Lead(
        id: 'l_1',
        leadName: 'Rajesh Kumar',
        mobileNumber: '+919999888811',
        destination: 'Maldives',
        packageInterested: '5D/4N Water Villa Couple Package',
        budget: 150000.0,
        source: 'Website Enquiry',
        status: 'new_lead',
        assignedStaffId: 'staff_1',
        assignedStaffName: 'Rohan Das',
        notes: 'Wants standard flights + villa upgrade options.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toString(),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)).toString(),
      ),
      Lead(
          id: 'l_2',
          leadName: 'Sarah Jenkins',
          mobileNumber: '+919999888822',
          destination: 'Bali & Ubud',
          packageInterested: '7D/6N Honeymoon Luxury Package',
          budget: 220000.0,
          source: 'Instagram Ads',
          status: 'follow_up',
          assignedStaffId: 'staff_1',
          assignedStaffName: 'Rohan Das',
          notes: 'Follow up regarding customized private pool villa rates.',
          createdAt:
              DateTime.now().subtract(const Duration(days: 3)).toString(),
          updatedAt: DateTime.now().toString(),
          followUps: [
            LeadFollowUp(
              id: 'lf_1',
              leadId: 'l_2',
              followUpDate:
                  DateTime.now().subtract(const Duration(days: 1)).toString(),
              notes:
                  'Called Sarah. She requested a detailed itinerary by tomorrow afternoon.',
              createdAt:
                  DateTime.now().subtract(const Duration(days: 1)).toString(),
            )
          ]),
      Lead(
        id: 'l_3',
        leadName: 'Deepika Padukone',
        mobileNumber: '+919999888844',
        destination: 'Dubai',
        packageInterested: '4D/3N Shopping Festival Deal',
        budget: 90000.0,
        source: 'Walk-in',
        status: 'booking_confirmed',
        assignedStaffId: 'staff_1',
        assignedStaffName: 'Rohan Das',
        notes: 'Flight tickets and Visa generated. Invoice paid.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)).toString(),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)).toString(),
      )
    ];

    // 4. Setup Projects
    _mockProjects = [
      Project(
        id: 'prj_1',
        projectId: 'PRJ-00001',
        name: 'Europe Summer Extravaganza',
        clientName: 'Internal Promotion',
        startDate: DateTime.now().subtract(const Duration(days: 10)).toString(),
        dueDate: DateTime.now().add(const Duration(days: 20)).toString(),
        priority: 'high',
        status: 'in_progress',
        assignedTeamId: 'dept_sales',
        assignedTeamName: 'Sales & Marketing',
        progressPercentage: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 10)).toString(),
        updatedAt: DateTime.now().toString(),
      ),
      Project(
        id: 'prj_2',
        projectId: 'PRJ-00002',
        name: 'Maldives Luxury Group Bookings',
        clientName: 'Club Mahindra Resorts',
        startDate: DateTime.now().subtract(const Duration(days: 5)).toString(),
        dueDate: DateTime.now().add(const Duration(days: 15)).toString(),
        priority: 'medium',
        status: 'in_progress',
        assignedTeamId: 'dept_ops',
        assignedTeamName: 'Operations & Bookings',
        progressPercentage: 50,
        createdAt: DateTime.now().subtract(const Duration(days: 5)).toString(),
        updatedAt: DateTime.now().toString(),
      ),
      Project(
        id: 'prj_3',
        projectId: 'PRJ-00003',
        name: 'Customer Support Portal Setup',
        clientName: 'Aspire Internal',
        startDate: DateTime.now().subtract(const Duration(days: 1)).toString(),
        dueDate: DateTime.now().add(const Duration(days: 30)).toString(),
        priority: 'low',
        status: 'not_started',
        assignedTeamId: 'dept_support',
        assignedTeamName: 'Customer Support',
        progressPercentage: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toString(),
        updatedAt: DateTime.now().toString(),
      ),
    ];

    // Seed mock departments
    _mockDepartments = [
      Department(
          id: 'dept_sales',
          name: 'Sales & Marketing',
          userCount: 2,
          projectCount: 1,
          isActive: true),
      Department(
          id: 'dept_ops',
          name: 'Operations & Bookings',
          userCount: 1,
          projectCount: 1,
          isActive: true),
      Department(
          id: 'dept_support',
          name: 'Customer Support',
          userCount: 0,
          projectCount: 1,
          isActive: true),
      Department(
          id: 'dept_admin',
          name: 'Finance & Administration',
          userCount: 2,
          projectCount: 1,
          isActive: true),
    ];

    // Seed mock attendance logs
    _mockAttendance = [
      Attendance(
        id: 'att_1',
        userId: 'staff_1',
        employeeName: 'Rashiban',
        employeeId: 'EMP-1003',
        departmentName: 'Digital Marketing',
        date: DateTime.now().toString().split(' ')[0],
        status: 'present',
        checkInTime:
            DateTime.now().subtract(const Duration(hours: 2)).toString(),
        checkOutTime: null,
      )
    ];

    // Seed mock leave requests
    _mockLeaves = [
      LeaveRequest(
        id: 'l_1',
        userId: 'staff_1',
        employeeName: 'Rashiban',
        employeeId: 'EMP-1003',
        departmentName: 'Digital Marketing',
        leaveType: 'sick',
        startDate: DateTime.now()
            .add(const Duration(days: 1))
            .toString()
            .split(' ')[0],
        endDate: DateTime.now()
            .add(const Duration(days: 2))
            .toString()
            .split(' ')[0],
        status: 'pending',
        reason: 'Fever and throat infection. Need rest.',
        createdAt: DateTime.now().toString(),
      )
    ];
  }

  // Helpers
  String _getDeptName(String? id) {
    if (id == 'dept_sales') return 'Sales & Marketing';
    if (id == 'dept_ops') return 'Operations & Bookings';
    if (id == 'dept_support') return 'Customer Support';
    if (id == 'dept_admin') return 'Finance & Administration';
    return 'General';
  }

  String _getUserName(String? id) {
    if (id == null) return 'Unassigned';
    return _mockUsers
        .firstWhere((u) => u.id == id,
            orElse: () => User(
                id: '',
                employeeId: '',
                name: 'Unknown',
                email: '',
                phone: '',
                role: '',
                designation: '',
                performanceScore: 0))
        .name;
  }

  DashboardStats _generateMockStats() {
    final role = _currentUser?.role ?? 'staff';

    if (role == 'admin') {
      return DashboardStats(
        role: 'admin',
        managerCards: {
          'totalProjects': _mockProjects.length,
          'activeProjects': _mockProjects
              .where((p) => p.status != 'completed' && p.status != 'on_hold')
              .length,
          'completedProjects':
              _mockProjects.where((p) => p.status == 'completed').length,
          'totalEmployees': _mockUsers.where((u) => u.role == 'staff').length,
          'totalTeamLeaders':
              _mockUsers.where((u) => u.role == 'team_leader').length,
          'pendingTasksCount':
              _mockTasks.where((t) => t.status != 'completed').length,
        },
        managerSummary: {
          'totalTasks': _mockTasks.length,
          'completedTasks':
              _mockTasks.where((t) => t.status == 'completed').length,
          'pendingTasks': _mockTasks.where((t) => t.status == 'pending').length,
          'inProgressTasks':
              _mockTasks.where((t) => t.status == 'in_progress').length,
          'overdueTasks': _mockTasks.where((t) => t.status == 'overdue').length,
          'completionPercentage': _mockTasks.isNotEmpty
              ? ((_mockTasks.where((t) => t.status == 'completed').length /
                          _mockTasks.length) *
                      100)
                  .round()
              : 0
        },
      );
    } else if (role == 'manager') {
      final total = _mockTasks.length;
      final completed = _mockTasks.where((t) => t.status == 'completed').length;
      final pending = _mockTasks.where((t) => t.status == 'pending').length;
      final inProgress =
          _mockTasks.where((t) => t.status == 'in_progress').length;
      final overdue = _mockTasks.where((t) => t.status == 'overdue').length;

      final totalProjects = _mockProjects.length;
      final activeProjects = _mockProjects
          .where((p) => p.status != 'completed' && p.status != 'on_hold')
          .length;
      final completedProjects =
          _mockProjects.where((p) => p.status == 'completed').length;

      return DashboardStats(
        role: role,
        managerCards: {
          'totalProjects': totalProjects,
          'activeProjects': activeProjects,
          'completedProjects': completedProjects,
          'totalEmployees': _mockUsers.where((u) => u.role == 'staff').length,
          'totalTeamLeaders':
              _mockUsers.where((u) => u.role == 'team_leader').length,
          'pendingTasksCount': pending + inProgress,
        },
        managerSummary: {
          'totalTasks': total,
          'completedTasks': completed,
          'pendingTasks': pending,
          'inProgressTasks': inProgress,
          'overdueTasks': overdue,
          'completionPercentage':
              total > 0 ? ((completed / total) * 100).round() : 0
        },
        monthlyProductivity: [
          {'month': 'May', 'count': 4},
          {'month': 'Jun', 'count': 6},
          {'month': 'Jul', 'count': total}
        ],
        topPerformers: _mockUsers.map((u) => u.toJson()).toList()
          ..sort((a, b) =>
              b['performance_score'].compareTo(a['performance_score'])),
        teamPerformance: [
          {'team_name': 'Sales & Marketing', 'avg_progress': 45.0},
          {'team_name': 'Operations & Bookings', 'avg_progress': 50.0},
          {'team_name': 'Customer Support', 'avg_progress': 0.0},
        ],
      );
    } else if (role == 'team_leader') {
      final deptTasks = _mockTasks
          .where((t) => t.departmentId == _currentUser?.departmentId)
          .toList();
      final total = deptTasks.length;
      final completed = deptTasks.where((t) => t.status == 'completed').length;
      final pending = deptTasks
          .where((t) => t.status == 'pending' || t.status == 'in_progress')
          .length;

      final deptProjects = _mockProjects
          .where((p) => p.assignedTeamId == _currentUser?.departmentId)
          .toList();
      final projectsAssigned = deptProjects.length;
      final double teamProgress = deptProjects.isNotEmpty
          ? deptProjects
                  .map((p) => p.progressPercentage)
                  .reduce((a, b) => a + b) /
              deptProjects.length
          : 0.0;

      return DashboardStats(
          role: role,
          tlAssignedByManager:
              _mockTasks.where((t) => t.assignedTo == _currentUser?.id).length,
          tlAssignedToStaff: _mockTasks
              .where((t) =>
                  t.assignedBy == _currentUser?.id &&
                  t.assignedTo != _currentUser?.id)
              .length,
          tlProjectsAssigned: projectsAssigned,
          tlTeamProgress: teamProgress,
          tlSummary: {
            'totalTeamTasks': total,
            'completedTeamTasks': completed,
            'pendingTeamTasks': pending,
            'teamCompletionPercentage':
                total > 0 ? ((completed / total) * 100).round() : 0
          },
          tlStaffWorkload: _mockUsers
              .where((u) => u.teamLeaderId == _currentUser?.id)
              .map((u) => {
                    'name': u.name,
                    'task_count': _mockTasks
                        .where((t) =>
                            t.assignedTo == u.id && t.status != 'completed')
                        .length
                  })
              .toList());
    } else {
      final myTasks =
          _mockTasks.where((t) => t.assignedTo == _currentUser?.id).toList();
      final total = myTasks.length;
      final completed = myTasks.where((t) => t.status == 'completed').length;
      final pending = myTasks
          .where((t) => t.status == 'pending' || t.status == 'in_progress')
          .length;
      final overdue = myTasks.where((t) => t.status == 'overdue').length;

      return DashboardStats(role: role, staffSummary: {
        'myTasksCount': total,
        'dueTodayCount': 1,
        'overdueCount': overdue,
        'completedCount': completed,
        'pendingCount': pending,
        'personalProductivity': _currentUser?.performanceScore ?? 90.0
      });
    }
  }

  // ==========================================
  // DEPARTMENTS API
  // ==========================================

  Future<List<Department>> fetchDepartments({bool activeOnly = false}) async {
    if (_useMockFallback) {
      if (activeOnly)
        return _mockDepartments.where((d) => d.isActive != false).toList();
      return _mockDepartments;
    }

    try {
      final String queryParam = activeOnly ? '?activeOnly=true' : '';
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/departments$queryParam'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Department.fromJson(item)).toList();
      }
    } catch (e) {
      print('Departments Fetch Error: $e');
    }
    return _mockDepartments;
  }

  Future<Department?> createDepartment(String name) async {
    if (_useMockFallback) {
      final newDept = Department(
        id: 'dept_mock_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        userCount: 0,
        projectCount: 0,
        createdAt: DateTime.now().toString(),
      );
      _mockDepartments.add(newDept);
      notifyListeners();
      return newDept;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/departments'),
        headers: _getHeaders(),
        body: jsonEncode({'name': name}),
      );
      if (res.statusCode == 201) {
        final newDept = Department.fromJson(jsonDecode(res.body));
        notifyListeners();
        return newDept;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to create department';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<Department?> updateDepartment(String id, String name) async {
    if (_useMockFallback) {
      final idx = _mockDepartments.indexWhere((d) => d.id == id);
      if (idx != -1) {
        final updated = Department(
          id: id,
          name: name,
          userCount: _mockDepartments[idx].userCount,
          projectCount: _mockDepartments[idx].projectCount,
          isActive: _mockDepartments[idx].isActive,
          createdAt: _mockDepartments[idx].createdAt,
        );
        _mockDepartments[idx] = updated;
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/departments/$id'),
        headers: _getHeaders(),
        body: jsonEncode({'name': name}),
      );
      if (res.statusCode == 200) {
        final updatedDept = Department.fromJson(jsonDecode(res.body));
        notifyListeners();
        return updatedDept;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to update department';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<bool> deleteDepartment(String id) async {
    if (_useMockFallback) {
      _mockDepartments.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    }

    try {
      final res = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/departments/$id'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to delete department';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  Future<bool> toggleDepartmentStatus(String id, bool isActive) async {
    if (_useMockFallback) {
      final idx = _mockDepartments.indexWhere((d) => d.id == id);
      if (idx != -1) {
        final existing = _mockDepartments[idx];
        _mockDepartments[idx] = Department(
          id: existing.id,
          name: existing.name,
          userCount: existing.userCount,
          projectCount: existing.projectCount,
          isActive: isActive,
          createdAt: existing.createdAt,
        );
        notifyListeners();
        return true;
      }
      return false;
    }

    try {
      final res = await http.patch(
        Uri.parse('${AppConstants.apiBaseUrl}/departments/$id/status'),
        headers: _getHeaders(),
        body: jsonEncode({'is_active': isActive}),
      );
      if (res.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to update status';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  Future<bool> assignEmployeesToDepartment(
      String id, List<String> userIds) async {
    if (_useMockFallback) {
      notifyListeners();
      return true;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/departments/$id/assign'),
        headers: _getHeaders(),
        body: jsonEncode({'userIds': userIds}),
      );
      if (res.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to assign employees';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  Future<Map<String, dynamic>?> fetchDepartmentStats(String id) async {
    if (_useMockFallback) {
      return {
        'total_employees': 3,
        'avg_performance': 92.5,
        'total_projects': 2,
        'task_stats': {'pending': 2, 'in_progress': 1, 'completed': 5}
      };
    }

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/departments/$id/statistics'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Department stats fetch error: $e');
    }
    return null;
  }

  // ==========================================
  // ATTENDANCE API
  // ==========================================

  Future<List<Attendance>> fetchAttendance(
      {String? date, String? userId}) async {
    if (_useMockFallback) {
      var list = _mockAttendance;
      if (date != null && date.isNotEmpty) {
        list = list.where((a) => a.date == date).toList();
      }
      if (userId != null && userId.isNotEmpty) {
        list = list.where((a) => a.userId == userId).toList();
      }
      return list;
    }

    try {
      String queryParams = '?';
      if (date != null && date.isNotEmpty) queryParams += 'date=$date&';
      if (userId != null && userId.isNotEmpty) queryParams += 'userId=$userId&';

      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/attendance$queryParams'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Attendance.fromJson(item)).toList();
      }
    } catch (e) {
      print('Attendance Fetch Error: $e');
    }
    return _mockAttendance;
  }

  Future<Attendance?> fetchTodayAttendanceStatus() async {
    if (_useMockFallback) {
      final todayStr = DateTime.now().toString().split(' ')[0];
      final record = _mockAttendance.firstWhere(
        (a) => a.userId == _currentUser?.id && a.date == todayStr,
        orElse: () => Attendance(id: '', userId: '', date: '', status: ''),
      );
      return record.id.isEmpty ? null : record;
    }

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/attendance/today'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        return Attendance.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('Today Attendance Fetch Error: $e');
    }
    return null;
  }

  Future<Attendance?> markAttendance(String action) async {
    if (_useMockFallback) {
      final todayStr = DateTime.now().toString().split(' ')[0];
      final idx = _mockAttendance.indexWhere(
          (a) => a.userId == _currentUser?.id && a.date == todayStr);

      if (action == 'clock_in') {
        if (idx != -1) return _mockAttendance[idx];
        final record = Attendance(
          id: 'att_mock_${DateTime.now().millisecondsSinceEpoch}',
          userId: _currentUser?.id ?? 'staff_1',
          employeeName: _currentUser?.name ?? 'Employee',
          employeeId: _currentUser?.employeeId ?? 'EMP-1003',
          departmentName: _currentUser?.departmentName,
          date: todayStr,
          status: 'present',
          checkInTime: DateTime.now().toString(),
          checkOutTime: null,
        );
        _mockAttendance.add(record);
        notifyListeners();
        return record;
      } else {
        if (idx == -1) return null;
        final record = Attendance(
          id: _mockAttendance[idx].id,
          userId: _mockAttendance[idx].userId,
          employeeName: _mockAttendance[idx].employeeName,
          employeeId: _mockAttendance[idx].employeeId,
          departmentName: _mockAttendance[idx].departmentName,
          date: _mockAttendance[idx].date,
          status: _mockAttendance[idx].status,
          checkInTime: _mockAttendance[idx].checkInTime,
          checkOutTime: DateTime.now().toString(),
        );
        _mockAttendance[idx] = record;
        notifyListeners();
        return record;
      }
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/attendance/mark'),
        headers: _getHeaders(),
        body: jsonEncode({'action': action}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final record = Attendance.fromJson(jsonDecode(res.body));
        notifyListeners();
        return record;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to mark attendance';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<Attendance?> updateAttendance(
      String id, Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final idx = _mockAttendance.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final existing = _mockAttendance[idx];
        final updated = Attendance(
          id: existing.id,
          userId: existing.userId,
          employeeName: existing.employeeName,
          employeeId: existing.employeeId,
          departmentName: existing.departmentName,
          date: existing.date,
          status: data['status'] ?? existing.status,
          checkInTime: data['check_in_time'] ?? existing.checkInTime,
          checkOutTime: data['check_out_time'] ?? existing.checkOutTime,
        );
        _mockAttendance[idx] = updated;
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/attendance/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        final updated = Attendance.fromJson(jsonDecode(res.body));
        notifyListeners();
        return updated;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to update attendance';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  // ==========================================
  // LEAVE MANAGEMENT API
  // ==========================================

  Future<List<LeaveRequest>> fetchLeaves({String? status}) async {
    if (_useMockFallback) {
      var list = _mockLeaves;
      if (status != null && status.isNotEmpty) {
        list = list.where((l) => l.status == status).toList();
      }
      return list;
    }

    try {
      String queryParams = '';
      if (status != null && status.isNotEmpty) queryParams = '?status=$status';

      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/leaves$queryParams'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => LeaveRequest.fromJson(item)).toList();
      }
    } catch (e) {
      print('Leaves Fetch Error: $e');
    }
    return _mockLeaves;
  }

  Future<LeaveRequest?> createLeaveRequest(Map<String, dynamic> data) async {
    if (_useMockFallback) {
      final newLeave = LeaveRequest(
        id: 'leave_mock_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser?.id ?? 'staff_1',
        employeeName: _currentUser?.name ?? 'Employee',
        employeeId: _currentUser?.employeeId ?? 'EMP-1003',
        departmentName: _currentUser?.departmentName,
        leaveType: data['leave_type'],
        startDate: data['start_date'],
        endDate: data['end_date'],
        status: 'pending',
        reason: data['reason'] ?? '',
        createdAt: DateTime.now().toString(),
      );
      _mockLeaves.add(newLeave);
      notifyListeners();
      return newLeave;
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/leaves'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        final leave = LeaveRequest.fromJson(jsonDecode(res.body));
        notifyListeners();
        return leave;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to apply for leave';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<LeaveRequest?> approveRejectLeave(String id, String status,
      {String? adminNotes}) async {
    if (_useMockFallback) {
      final idx = _mockLeaves.indexWhere((l) => l.id == id);
      if (idx != -1) {
        final existing = _mockLeaves[idx];
        final updated = LeaveRequest(
          id: existing.id,
          userId: existing.userId,
          employeeName: existing.employeeName,
          employeeId: existing.employeeId,
          departmentName: existing.departmentName,
          leaveType: existing.leaveType,
          startDate: existing.startDate,
          endDate: existing.endDate,
          status: status,
          reason: existing.reason,
          adminNotes: adminNotes ?? existing.adminNotes,
          createdAt: existing.createdAt,
        );
        _mockLeaves[idx] = updated;
        notifyListeners();
        return updated;
      }
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/leaves/$id'),
        headers: _getHeaders(),
        body: jsonEncode({'status': status, 'admin_notes': adminNotes}),
      );
      if (res.statusCode == 200) {
        final updated = LeaveRequest.fromJson(jsonDecode(res.body));
        notifyListeners();
        return updated;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['error'] ?? 'Failed to update leave request';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchSystemSettings() async {
    if (_useMockFallback) {
      return {
        'company_name': 'Aspire (Mock)',
        'company_logo': '/uploads/logo_default.png',
        'working_hours_start': '09:00',
        'working_hours_end': '18:00',
        'password_min_length': '8',
        'smtp_host': 'smtp.mailtrap.io',
        'smtp_port': '2525',
        'smtp_secure': 'false',
        'backup_frequency': 'daily'
      };
    }
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/settings'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return {};
  }

  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    if (_useMockFallback) return true;
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/settings'),
        headers: _getHeaders(),
        body: jsonEncode(settings),
      );
      return res.statusCode == 200;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<String?> uploadCompanyLogo(List<int> bytes, String filename) async {
    if (_useMockFallback) return '/uploads/logo_default.png';
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/admin/settings/logo');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getHeaders());
      request.files.add(http.MultipartFile.fromBytes(
        'logo',
        bytes,
        filename: filename,
      ));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['logoUrl'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>?> triggerBackup() async {
    if (_useMockFallback) {
      return {
        'message': 'Backup generated (Mock Mode)',
        'fileName': 'backup_mock.sql',
        'url': '/backups/backup_mock.sql'
      };
    }
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/backup'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  Future<List<dynamic>> fetchNotifications() async {
    if (_useMockFallback) {
      return [
        {
          'id': '1',
          'title': 'Mock Notification',
          'message': 'Simulated alert log.',
          'type': 'system',
          'read': false,
          'created_at': DateTime.now().toString()
        }
      ];
    }
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/notifications'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(res.body));
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return [];
  }

  Future<bool> markNotificationRead(String id) async {
    if (_useMockFallback) return true;
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/notifications/$id/read'),
        headers: _getHeaders(),
      );
      return res.statusCode == 200;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_useMockFallback) return true;
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/change-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<List<dynamic>> fetchReportDepartments() async {
    if (_useMockFallback) return [];
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/reports/departments'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(res.body));
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return [];
  }

  Future<Uint8List> downloadDepartmentPdf({String? departmentId}) async {
    if (_useMockFallback) throw Exception('Mock fallback active');
    final endpoint = departmentId == null
        ? '/reports/all/pdf'
        : '/reports/department/$departmentId/pdf';
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: _getHeaders(),
    );

    debugPrint('PDF response status: ${response.statusCode}');
    debugPrint(
        'PDF response content-type: ${response.headers['content-type']}');
    debugPrint('PDF response bytes: ${response.bodyBytes.length}');

    if (response.statusCode != 200) {
      String message = 'Unable to generate PDF report';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
    return response.bodyBytes;
  }

  Future<Uint8List> downloadDepartmentExcel({String? departmentId}) async {
    if (_useMockFallback) throw Exception('Mock fallback active');
    final endpoint = departmentId == null
        ? '/reports/all/excel'
        : '/reports/department/$departmentId/excel';
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: _getHeaders(),
    );

    debugPrint('EXCEL response status: ${response.statusCode}');
    debugPrint(
        'EXCEL response content-type: ${response.headers['content-type']}');
    debugPrint('EXCEL response bytes: ${response.bodyBytes.length}');

    if (response.statusCode != 200) {
      String message = 'Unable to generate Excel report';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
    return response.bodyBytes;
  }
}
