class AppConstants {
  // Replace this base URL with your server IP when testing on physical mobile devices
  static const String apiBaseUrl = 'https://aspire-task-pro-backend.onrender.com/api';

  // Session keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_profile';
  static const String themeModeKey = 'theme_mode';

  // Role mappings
  static const String roleManager = 'manager';
  static const String roleManagingDirector = 'managing_director';
  static const String roleTeamLeader = 'team_leader';
  static const String roleStaff = 'staff';

  // Tasks status values
  static const List<String> taskStatuses = [
    'pending',
    'assigned',
    'in_progress',
    'completed',
    'rejected',
    'overdue'
  ];

  // Lead status values
  static const List<String> leadStatuses = [
    'new_lead',
    'contacted',
    'follow_up',
    'interested',
    'not_interested',
    'booking_confirmed'
  ];

  // UI Constants for new premium mobile design
  static const double cardRadius = 24.0;
  static const double buttonRadius = 16.0;
  static const double inputRadius = 16.0;
  static const double defaultPadding = 20.0;
}
