import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages tenant-specific operations and provides the current tenant ID
class TenantManager {
  static String? _currentTenantId;

  /// Set the current tenant ID (usually after user login)
  static void setCurrentTenantId(String tenantId) {
    _currentTenantId = tenantId;
  }

  /// Get the current tenant ID
  static String getCurrentTenantId() {
    if (_currentTenantId == null) {
      // If not explicitly set, use the current user's ID as tenant ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        return user.id;
      }
      throw Exception('No tenant ID available. User must be logged in.');
    }
    return _currentTenantId!;
  }

  /// Clear the tenant ID (usually on logout)
  static void clearCurrentTenantId() {
    _currentTenantId = null;
  }
}
