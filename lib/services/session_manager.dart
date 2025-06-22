// lib/services/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _loginTimeKey = 'login_time';
  static const String _apiKeyKey = 'api_key';

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String username,
    required String apiKey,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_apiKeyKey, apiKey);
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
    await prefs.setString(_loginTimeKey, DateTime.now().toIso8601String());
  }

  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'access_token': prefs.getString(_accessTokenKey),
      'refresh_token': prefs.getString(_refreshTokenKey),
      'username': prefs.getString(_usernameKey),
      'user_id': prefs.getString(_userIdKey),
      'login_time': prefs.getString(_loginTimeKey),
      'api_key': prefs.getString(_apiKeyKey),
    };
  }

  static Future<void> updateTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_apiKeyKey);
  }

  static Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session['access_token'] != null && 
           session['refresh_token'] != null && 
           session['username'] != null;
  }

  // FIXED: Remove automatic token expiration check
  // The backend should handle token validation, not the client
  static Future<bool> isTokenExpired() async {
    // Always return false - let the backend decide if token is expired
    // The app will handle 401/403 responses from API calls
    return false;
  }

  // Helper method to get API key
  static Future<String?> getApiKey() async {
    final session = await getSession();
    return session['api_key'];
  }

  // Helper method to get access token
  static Future<String?> getAccessToken() async {
    final session = await getSession();
    return session['access_token'];
  }

  // Add method to check if session data exists without expiration logic
  static Future<bool> hasValidSessionData() async {
    final session = await getSession();
    return session['access_token'] != null && 
           session['api_key'] != null && 
           session['username'] != null;
  }
}