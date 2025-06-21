import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _loginTimeKey = 'login_time';

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String username,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_usernameKey, username);
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
  }

  static Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session['access_token'] != null && 
           session['refresh_token'] != null && 
           session['username'] != null;
  }

  static Future<bool> isTokenExpired() async {
    final session = await getSession();
    final loginTimeStr = session['login_time'];
    
    if (loginTimeStr == null) return true;
    
    final loginTime = DateTime.parse(loginTimeStr);
    final now = DateTime.now();
    final difference = now.difference(loginTime);
    
    // Assume token expires after 24 hours (adjust based on your backend)
    return difference.inHours >= 24;
  }
}