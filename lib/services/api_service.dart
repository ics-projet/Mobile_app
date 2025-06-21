// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'session_manager.dart';

class ApiService {
  // Login method
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.loginEndpoint));
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'username=$username&password=$password',
      ).timeout(ApiConfig.requestTimeout);

      return _handleResponse(response, 'Login successful');
    } catch (e) {
      return _handleError(e, 'Login failed');
    }
  }

  // Send SMS method
  static Future<Map<String, dynamic>> sendSms({
    required String recipient,
    required String message,
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.smsEndpoint));
      
      final response = await http.post(
        url,
        headers: ApiConfig.headersWithApiKey(apiKey),
        body: json.encode({
          'recipient': recipient,
          'message': message,
        }),
      ).timeout(ApiConfig.requestTimeout);

      return _handleResponse(response, 'SMS sent successfully');
    } catch (e) {
      return _handleError(e, 'Failed to send SMS');
    }
  }

  // Get SMS inbox
  static Future<Map<String, dynamic>> getSmsInbox({
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.smsInboxEndpoint));
      
      final response = await http.get(
        url,
        headers: ApiConfig.headersWithApiKey(apiKey),
      ).timeout(ApiConfig.requestTimeout);

      final result = _handleResponse(response, 'Inbox fetched successfully');
      
      if (result['success']) {
        // Handle different response structures
        final data = result['data'];
        if (data is Map && data.containsKey('messages')) {
          result['messages'] = data['messages'];
        } else if (data is List) {
          result['messages'] = data;
        } else {
          result['messages'] = [];
        }
      }
      
      return result;
    } catch (e) {
      return _handleError(e, 'Failed to fetch inbox');
    }
  }

  // Get communication logs - Updated with proper authentication
  static Future<Map<String, dynamic>> getCommunicationLogs({
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.logsEndpoint));
      
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'api-key': apiKey, // Use exact header name from curl
        },
      ).timeout(ApiConfig.requestTimeout);

      final result = _handleResponse(response, 'Logs fetched successfully');
      
      if (result['success']) {
        // Handle different response structures
        final data = result['data'];
        if (data is List) {
          result['logs'] = data; // Backend returns array directly
        } else if (data is Map && data.containsKey('logs')) {
          result['logs'] = data['logs'];
        } else {
          result['logs'] = [];
        }
      }
      
      return result;
    } catch (e) {
      return _handleError(e, 'Failed to fetch logs');
    }
  }

  // Helper method for authenticated requests with token refresh
  static Future<Map<String, dynamic>> _makeAuthenticatedRequest({
    required String endpoint,
    required String method,
    String? apiKey,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final session = await SessionManager.getSession();
    String? accessToken = session['access_token'];
    final refreshTokenValue = session['refresh_token']; // Renamed for clarity
    
    // Build headers with both token and API key
    Map<String, String> headers = {
      ...ApiConfig.defaultHeaders,
      ...?additionalHeaders,
    };
    
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    if (apiKey != null) {
      headers['api-key'] = apiKey; // Use the exact format expected by backend
    }

    final uri = Uri.parse(ApiConfig.buildUrl(endpoint));
    http.Response response;

    try {
      // Make the initial request
      response = await _makeHttpRequest(uri, method, headers, body);
      
      // If we get 401 or 403, try to refresh token and retry
      if ((response.statusCode == 401 || response.statusCode == 403) && 
          refreshTokenValue != null) {
        
        // Try to refresh the token - FIXED: Call the static method correctly
        final refreshResult = await ApiService.refreshToken(refreshTokenValue);
        
        if (refreshResult['success']) {
          // Update the access token and retry
          final newAccessToken = refreshResult['data']['access_token'];
          final newRefreshToken = refreshResult['data']['refresh_token'];
          
          // Save new tokens
          await SessionManager.updateTokens(newAccessToken, newRefreshToken);
          
          // Update headers with new token
          headers['Authorization'] = 'Bearer $newAccessToken';
          
          // Retry the request
          response = await _makeHttpRequest(uri, method, headers, body);
        }
      }
      
      return _handleResponse(response, 'Request successful');
      
    } catch (e) {
      return _handleError(e, 'Request failed');
    }
  }

  // Helper method to make HTTP requests
  static Future<http.Response> _makeHttpRequest(
    Uri uri, 
    String method, 
    Map<String, String> headers, 
    Map<String, dynamic>? body
  ) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ).timeout(ApiConfig.requestTimeout);
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ).timeout(ApiConfig.requestTimeout);
      case 'DELETE':
        return await http.delete(uri, headers: headers).timeout(ApiConfig.requestTimeout);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Register method
  static Future<Map<String, dynamic>> register(
    String username, 
    String password, 
    String phoneNumber
  ) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.registerEndpoint));
      
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'username': username,
          'password': password,
          'phone_number': phoneNumber,
        }),
      ).timeout(ApiConfig.requestTimeout);

      return _handleResponse(response, 'Registration successful');
    } catch (e) {
      return _handleError(e, 'Registration failed');
    }
  }

  // Refresh token method
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.refreshTokenEndpoint));
      
      final response = await http.post(
        url,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $refreshToken',
        },
      ).timeout(ApiConfig.requestTimeout);

      return _handleResponse(response, 'Token refreshed successfully');
    } catch (e) {
      return _handleError(e, 'Token refresh failed');
    }
  }

  // Logout method
  static Future<Map<String, dynamic>> logout(String accessToken) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.logoutEndpoint));
      
      final response = await http.post(
        url,
        headers: {
          ...ApiConfig.defaultHeaders,
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
          'error': 'Logout failed on server',
        };
      }
    } catch (e) {
      // Even if server logout fails, we can still logout locally
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  // Generic authenticated request method - Updated
  static Future<Map<String, dynamic>> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final session = await SessionManager.getSession();
      final accessToken = session['access_token'];
      final apiKey = session['api_key'];

      if (accessToken == null && apiKey == null) {
        return {
          'success': false,
          'error': 'No authentication token found. Please login again.',
          'requires_login': true,
        };
      }

      return await _makeAuthenticatedRequest(
        endpoint: endpoint,
        method: method,
        apiKey: apiKey,
        body: body,
        additionalHeaders: additionalHeaders,
      );
    } catch (e) {
      return _handleError(e, 'Request failed');
    }
  }

  // Helper method to handle HTTP responses
  static Map<String, dynamic> _handleResponse(http.Response response, String successMessage) {
    try {
      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'message': successMessage,
          'status_code': response.statusCode,
        };
      } else {
        String errorMessage = 'Request failed';
        
        if (responseData is Map) {
          errorMessage = responseData['detail']?.toString() ?? 
                        responseData['message']?.toString() ?? 
                        responseData['error']?.toString() ?? 
                        'Request failed';
        }
        
        // Add specific handling for 403 errors
        if (response.statusCode == 403) {
          errorMessage = 'Access denied. Please check your permissions or login again.';
        }
        
        return {
          'success': false,
          'error': errorMessage,
          'status_code': response.statusCode,
          'requires_login': response.statusCode == 401 || response.statusCode == 403,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Invalid response format: ${response.body}',
        'status_code': response.statusCode,
      };
    }
  }

  // Helper method to handle errors
  static Map<String, dynamic> _handleError(dynamic error, String defaultMessage) {
    if (error is http.ClientException) {
      return {
        'success': false,
        'error': 'Network connection failed. Please check your internet connection.',
      };
    } else if (error is FormatException) {
      return {
        'success': false,
        'error': 'Invalid response format from server.',
      };
    } else {
      return {
        'success': false,
        'error': '$defaultMessage: ${error.toString()}',
      };
    }
  }
}