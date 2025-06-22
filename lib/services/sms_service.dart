// lib/services/sms_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'session_manager.dart';

class SmsService {
  // Send SMS with backend integration
  static Future<Map<String, dynamic>> sendSms({
    required String recipient,
    required String message,
  }) async {
    try {
      final session = await SessionManager.getSession();
      
      // FIXED: Check both access token and API key
      final accessToken = session['access_token'];
      final apiKey = session['api_key'];
      
      if (accessToken == null && apiKey == null) {
        return {
          'success': false, 
          'error': 'Not authenticated. Please login again.',
          'requires_login': true,
        };
      }

      // Validate input
      if (recipient.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Recipient phone number is required',
        };
      }

      if (message.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Message content is required',
        };
      }

      // Validate phone number format
      if (!isValidPhoneNumber(recipient)) {
        return {
          'success': false,
          'error': 'Invalid phone number format',
        };
      }

      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.smsEndpoint));
      
      // FIXED: Use proper authentication headers
      final headers = _buildAuthHeaders(accessToken, apiKey);
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'recipient': normalizePhoneNumber(recipient.trim()),
          'message': message.trim(),
        }),
      ).timeout(ApiConfig.requestTimeout);

      return _handleSmsResponse(response, 'SMS sent successfully');
    } catch (e) {
      return _handleSmsError(e, 'Failed to send SMS');
    }
  }

  // Get inbox with better error handling
  static Future<Map<String, dynamic>> getInbox() async {
    try {
      final session = await SessionManager.getSession();
      
      // FIXED: Check both access token and API key
      final accessToken = session['access_token'];
      final apiKey = session['api_key'];
      
      print('DEBUG: Session data - accessToken: ${accessToken != null ? 'present' : 'null'}, apiKey: ${apiKey != null ? 'present' : 'null'}');
      
      if (accessToken == null && apiKey == null) {
        return {
          'success': false, 
          'error': 'Not authenticated. Please login again.',
          'requires_login': true,
        };
      }

      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.smsInboxEndpoint));
      
      // FIXED: Use proper authentication headers
      final headers = _buildAuthHeaders(accessToken, apiKey);
      print('DEBUG: Request headers: $headers');
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final result = _handleSmsResponse(response, 'Inbox fetched successfully');
      
      if (result['success']) {
        // Handle different response formats from your backend
        final responseData = result['data'];
        List<dynamic> messages = [];
        
        if (responseData is Map) {
          if (responseData.containsKey('messages')) {
            messages = responseData['messages'] as List? ?? [];
          } else if (responseData.containsKey('data')) {
            messages = responseData['data'] as List? ?? [];
          }
        } else if (responseData is List) {
          messages = responseData;
        }
        
        result['messages'] = messages;
      }
      
      return result;
    } catch (e) {
      print('DEBUG: Exception in getInbox: $e');
      return _handleSmsError(e, 'Failed to fetch inbox');
    }
  }

  // FIXED: New method to build proper authentication headers
  static Map<String, String> _buildAuthHeaders(String? accessToken, String? apiKey) {
    final headers = ApiConfig.headers;
    
    // Try Bearer token first (most common for JWT)
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    // Add API key as backup or if that's what your backend expects
    if (apiKey != null) {
      // Try different API key header formats that backends commonly use
      headers['X-API-Key'] = apiKey;
      headers['API-Key'] = apiKey;
      headers['Authorization'] = 'Bearer $apiKey'; // Override if API key is used as Bearer
    }
    
    return headers;
  }

  // Get SMS logs (for the logs screen)
  static Future<Map<String, dynamic>> getLogs() async {
    try {
      final session = await SessionManager.getSession();
      
      final accessToken = session['access_token'];
      final apiKey = session['api_key'];
      
      if (accessToken == null && apiKey == null) {
        return {
          'success': false, 
          'error': 'Not authenticated. Please login again.',
          'requires_login': true,
        };
      }

      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.logsEndpoint));
      
      final headers = _buildAuthHeaders(accessToken, apiKey);
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);

      final result = _handleSmsResponse(response, 'Logs fetched successfully');
      
      if (result['success']) {
        final responseData = result['data'];
        List<dynamic> logs = [];
        
        if (responseData is Map) {
          if (responseData.containsKey('logs')) {
            logs = responseData['logs'] as List? ?? [];
          } else if (responseData.containsKey('data')) {
            logs = responseData['data'] as List? ?? [];
          }
        } else if (responseData is List) {
          logs = responseData;
        }
        
        result['logs'] = logs;
      }
      
      return result;
    } catch (e) {
      return _handleSmsError(e, 'Failed to fetch logs');
    }
  }

  // Send bulk SMS
  static Future<Map<String, dynamic>> sendBulkSms({
    required List<String> recipients,
    required String message,
  }) async {
    try {
      final session = await SessionManager.getSession();
      
      final accessToken = session['access_token'];
      final apiKey = session['api_key'];
      
      if (accessToken == null && apiKey == null) {
        return {
          'success': false, 
          'error': 'Not authenticated. Please login again.',
          'requires_login': true,
        };
      }

      // Validate input
      if (recipients.isEmpty) {
        return {
          'success': false,
          'error': 'At least one recipient is required',
        };
      }

      if (message.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Message content is required',
        };
      }

      // Clean and validate recipients list
      final cleanRecipients = recipients
          .where((r) => r.trim().isNotEmpty)
          .map((r) => normalizePhoneNumber(r.trim()))
          .where((r) => isValidPhoneNumber(r))
          .toList();

      if (cleanRecipients.isEmpty) {
        return {
          'success': false,
          'error': 'No valid recipients found',
        };
      }

      // Send individual SMS messages for bulk
      List<Map<String, dynamic>> results = [];
      int successful = 0;
      int failed = 0;

      for (String recipient in cleanRecipients) {
        final result = await sendSms(recipient: recipient, message: message);
        results.add({
          'recipient': recipient,
          'success': result['success'],
          'message_id': result['message_id'],
          'error': result['error'],
        });
        
        if (result['success']) {
          successful++;
        } else {
          failed++;
        }
        
        // Add small delay between requests to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return {
        'success': true,
        'data': {
          'total': cleanRecipients.length,
          'successful': successful,
          'failed': failed,
          'results': results,
        },
        'message': 'Bulk SMS processing completed: $successful sent, $failed failed',
      };
    } catch (e) {
      return _handleSmsError(e, 'Failed to send bulk SMS');
    }
  }

  // Get SMS status
  static Future<Map<String, dynamic>> getSmsStatus(String messageId) async {
    try {
      final session = await SessionManager.getSession();
      
      final accessToken = session['access_token'];
      final apiKey = session['api_key'];
      
      if (accessToken == null && apiKey == null) {
        return {
          'success': false, 
          'error': 'Not authenticated. Please login again.',
          'requires_login': true,
        };
      }

      final url = Uri.parse(ApiConfig.buildUrl('${ApiConfig.smsEndpoint}/status/$messageId'));
      
      final headers = _buildAuthHeaders(accessToken, apiKey);
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);

      return _handleSmsResponse(response, 'Status fetched successfully');
    } catch (e) {
      return _handleSmsError(e, 'Failed to fetch SMS status');
    }
  }

  // Helper method to handle SMS API responses based on your backend format
  static Map<String, dynamic> _handleSmsResponse(http.Response response, String successMessage) {
    try {
      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Handle your backend's response format
        String message = successMessage;
        String? messageId;
        
        if (responseData is Map) {
          message = responseData['detail'] ?? 
                   responseData['message'] ?? 
                   successMessage;
          messageId = responseData['message_id']?.toString();
        }
        
        final result = {
          'success': true,
          'data': responseData,
          'message': message,
          'status_code': response.statusCode,
        };
        
        // Add message_id if available
        if (messageId != null) {
          result['message_id'] = messageId;
        }
        
        return result;
      } else {
        String errorMessage = 'Operation failed';
        
        if (responseData is Map) {
          errorMessage = responseData['detail'] ?? 
                        responseData['message'] ?? 
                        responseData['error'] ?? 
                        errorMessage;
        }
        
        // Check for authentication errors
        bool requiresLogin = response.statusCode == 401 || 
                           response.statusCode == 403 ||
                           (responseData is Map && 
                            (responseData['detail']?.toString().toLowerCase().contains('unauthorized') ?? false));
        
        final result = {
          'success': false,
          'error': errorMessage,
          'status_code': response.statusCode,
        };
        
        if (requiresLogin) {
          result['requires_login'] = true;
        }
        
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Invalid response format from SMS service',
        'status_code': response.statusCode,
      };
    }
  }

  // Helper method to handle SMS errors
  static Map<String, dynamic> _handleSmsError(dynamic error, String defaultMessage) {
    if (error is http.ClientException) {
      return {
        'success': false,
        'error': 'Network connection failed. Please check your internet connection.',
      };
    } else if (error.toString().contains('TimeoutException')) {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } else if (error is FormatException) {
      return {
        'success': false,
        'error': 'Invalid response format from SMS service.',
      };
    } else {
      return {
        'success': false,
        'error': '$defaultMessage: ${error.toString()}',
      };
    }
  }

  // Validate phone number format (enhanced for Algerian numbers)
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it's empty
    if (cleanNumber.isEmpty) return false;
    
    // Get the number part without country code
    String numberWithoutCountryCode = cleanNumber;
    if (cleanNumber.startsWith('+213')) {
      numberWithoutCountryCode = cleanNumber.substring(4);
    } else if (cleanNumber.startsWith('213')) {
      numberWithoutCountryCode = cleanNumber.substring(3);
    } else if (cleanNumber.startsWith('0')) {
      numberWithoutCountryCode = cleanNumber.substring(1);
    }
    
    // Check if it's 9 digits after removing country code and leading zero
    if (numberWithoutCountryCode.length != 9) return false;
    
    // Check if it starts with valid prefixes for mobile numbers
    if (numberWithoutCountryCode.startsWith('5') || 
        numberWithoutCountryCode.startsWith('6') || 
        numberWithoutCountryCode.startsWith('7')) {
      return true;
    }
    
    // Check if it starts with valid prefixes for landline numbers
    final landlinePrefixes = ['21', '22', '23', '24', '25', '26', '27', '28', '29'];
    for (String prefix in landlinePrefixes) {
      if (numberWithoutCountryCode.startsWith(prefix)) {
        return true;
      }
    }
    
    return false;
  }

  // Format phone number for display (Algerian format)
  static String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Handle Algerian numbers
    if (cleanNumber.startsWith('+213')) {
      final number = cleanNumber.substring(4);
      if (number.length == 9) {
        return '+213 ${number.substring(0, 1)} ${number.substring(1, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
      }
    } else if (cleanNumber.startsWith('213')) {
      final number = cleanNumber.substring(3);
      if (number.length == 9) {
        return '+213 ${number.substring(0, 1)} ${number.substring(1, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
      }
    } else if (cleanNumber.startsWith('0') && cleanNumber.length == 10) {
      final number = cleanNumber.substring(1);
      return '0${number.substring(0, 1)} ${number.substring(1, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
    } else if (cleanNumber.length == 9) {
      return '0${cleanNumber.substring(0, 1)} ${cleanNumber.substring(1, 3)} ${cleanNumber.substring(3, 5)} ${cleanNumber.substring(5, 7)} ${cleanNumber.substring(7)}';
    }
    
    // Return original for unknown formats
    return phoneNumber;
  }

  // Normalize phone number for API calls (remove country code and leading zero)
  static String normalizePhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Remove country code if present
    if (cleanNumber.startsWith('+213')) {
      return cleanNumber.substring(4);
    } else if (cleanNumber.startsWith('213')) {
      return cleanNumber.substring(3);
    }
    
    // If it starts with 0, remove it
    if (cleanNumber.startsWith('0')) {
      return cleanNumber.substring(1);
    }
    
    return cleanNumber;
  }
}