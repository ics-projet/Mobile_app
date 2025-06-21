import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'session_manager.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Add this URL construction code:
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint.substring(1)}');
     
      
      final response = await http.post(
        url, // Use the constructed URL here
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'username=$username&password=$password',
      ).timeout(ApiConfig.requestTimeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Login successful',
        };
      } else {
        return {
          'success': false,
          'error': responseData['detail'] ?? 'Login failed',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'An error occurred: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> register(String username, String password, String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
          'phone_number': phoneNumber,
        }),
      ).timeout(ApiConfig.requestTimeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? responseData['detail'] ?? 'Registration failed',
          'status_code': response.statusCode,
        };
      }
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'error': 'Network connection failed. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'error': 'Invalid response format from server.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshTokenEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      ).timeout(ApiConfig.requestTimeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Token refresh failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Token refresh failed: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> logout(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Logged out successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Logout failed',
        };
      }
    } catch (e) {
      return {
        'success': true, // Still consider it successful locally
        'message': 'Logged out locally',
      };
    }
  }

  // Generic API call method with authentication
  static Future<Map<String, dynamic>> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final session = await SessionManager.getSession();
      final accessToken = session['access_token'];

      if (accessToken == null) {
        return {
          'success': false,
          'error': 'No access token found. Please login again.',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        ...?additionalHeaders,
      };

      http.Response response;
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(ApiConfig.requestTimeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(ApiConfig.requestTimeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(ApiConfig.requestTimeout);
          break;
        default:
          return {
            'success': false,
            'error': 'Unsupported HTTP method: $method',
          };
      }

      // Handle token expiration
      if (response.statusCode == 401) {
        final refreshResult = await _handleTokenRefresh();
        if (refreshResult['success']) {
          // Retry the request with new token
          final newSession = await SessionManager.getSession();
          headers['Authorization'] = 'Bearer ${newSession['access_token']}';
          
          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);
              break;
            case 'POST':
              response = await http.post(
                uri,
                headers: headers,
                body: body != null ? json.encode(body) : null,
              ).timeout(ApiConfig.requestTimeout);
              break;
            case 'PUT':
              response = await http.put(
                uri,
                headers: headers,
                body: body != null ? json.encode(body) : null,
              ).timeout(ApiConfig.requestTimeout);
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: headers).timeout(ApiConfig.requestTimeout);
              break;
          }
        } else {
          return {
            'success': false,
            'error': 'Session expired. Please login again.',
            'requires_login': true,
          };
        }
      }

      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'status_code': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? responseData['detail'] ?? 'Request failed',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Request failed: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> _handleTokenRefresh() async {
    final session = await SessionManager.getSession();
    final refreshToken = session['refresh_token'];

    if (refreshToken == null) {
      return {'success': false, 'error': 'No refresh token found'};
    }

    final result = await ApiService.refreshToken(refreshToken);
    
    if (result['success']) {
      await SessionManager.updateTokens(
        result['data']['access_token'],
        result['data']['refresh_token'] ?? refreshToken,
      );
    }

    return result;
  }
}