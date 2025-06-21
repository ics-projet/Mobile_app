// lib/services/sms_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'session_manager.dart';

class SmsService {
  // Send SMS with better error handling
  static Future<Map<String, dynamic>> sendSms({
    required String recipient,
    required String message,
  }) async {
    try {
      final session = await SessionManager.getSession();
      final apiKey = session['api_key'];
      
      if (apiKey == null) {
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

      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.smsEndpoint));
      
      final response = await http.post(
        url,
        headers: ApiConfig.headersWithApiKey(apiKey),
        body: json.encode({
          'recipient': recipient.trim(),
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
      final apiKey = session['api_key'];
      
      if (apiKey == null) {
        return {
          'success': false, 
          'error': 'Not authenticated. Please login again.',
          'requires_login': true,
        };
      }

      final url = Uri.parse(ApiConfig.buildUrl(ApiConfig.smsInboxEndpoint));
      
      final response = await http.get(
        url,
        headers: ApiConfig.headersWithApiKey(apiKey),
      ).timeout(ApiConfig.requestTimeout);

      final result = _handleSmsResponse(response, 'Inbox fetched successfully');
      
      if (result['success']) {
        // Ensure messages key exists and is properly formatted
        final data = result['data'];
        if (data is Map && data.containsKey('messages')) {
          result['messages'] = data['messages'] ?? [];
        } else if (data is List) {
          result['messages'] = data;
        } else {
          result['messages'] = [];
        }
      }
      
      return result;
    } catch (e) {
      return _handleSmsError(e, 'Failed to fetch inbox');
    }
  }

  // Send bulk SMS
  static Future<Map<String, dynamic>> sendBulkSms({
    required List<String> recipients,
    required String message,
  }) async {
    try {
      final session = await SessionManager.getSession();
      final apiKey = session['api_key'];
      
      if (apiKey == null) {
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

      // Clean recipients list
      final cleanRecipients = recipients
          .where((r) => r.trim().isNotEmpty)
          .map((r) => r.trim())
          .toList();

      if (cleanRecipients.isEmpty) {
        return {
          'success': false,
          'error': 'No valid recipients found',
        };
      }

      final url = Uri.parse(ApiConfig.buildUrl('${ApiConfig.smsEndpoint}/bulk'));
      
      final response = await http.post(
        url,
        headers: ApiConfig.headersWithApiKey(apiKey),
        body: json.encode({
          'recipients': cleanRecipients,
          'message': message.trim(),
        }),
      ).timeout(ApiConfig.requestTimeout);

      return _handleSmsResponse(response, 'Bulk SMS sent successfully');
    } catch (e) {
      return _handleSmsError(e, 'Failed to send bulk SMS');
    }
  }

  // Get SMS status
  static Future<Map<String, dynamic>> getSmsStatus(String messageId) async {
    try {
      final session = await SessionManager.getSession();
      final apiKey = session['api_key'];
      
      if (apiKey == null) {
        return {
          'success': false, 
          'error': 'Not authenticated. Please login again.',
          'requires_login': true,
        };
      }

      final url = Uri.parse(ApiConfig.buildUrl('${ApiConfig.smsEndpoint}/status/$messageId'));
      
      final response = await http.get(
        url,
        headers: ApiConfig.headersWithApiKey(apiKey),
      ).timeout(ApiConfig.requestTimeout);

      return _handleSmsResponse(response, 'Status fetched successfully');
    } catch (e) {
      return _handleSmsError(e, 'Failed to fetch SMS status');
    }
  }

  // Helper method to handle SMS API responses
  static Map<String, dynamic> _handleSmsResponse(http.Response response, String successMessage) {
    try {
      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? successMessage,
          'status_code': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': responseData['detail'] ?? 
                   responseData['message'] ?? 
                   responseData['error'] ?? 
                   'SMS operation failed',
          'status_code': response.statusCode,
        };
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

  // Validate phone number format (basic validation)
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it's a valid length (between 7 and 15 digits, including country code)
    if (cleanNumber.length < 7 || cleanNumber.length > 15) {
      return false;
    }
    
    // Check if it starts with + or digit
    if (!cleanNumber.startsWith('+') && !RegExp(r'^\d').hasMatch(cleanNumber)) {
      return false;
    }
    
    return true;
  }

  // Format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanNumber.length == 10) {
      // US format: (123) 456-7890
      return '(${cleanNumber.substring(0, 3)}) ${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6)}';
    } else if (cleanNumber.length == 11 && cleanNumber.startsWith('1')) {
      // US format with country code: +1 (123) 456-7890
      return '+${cleanNumber.substring(0, 1)} (${cleanNumber.substring(1, 4)}) ${cleanNumber.substring(4, 7)}-${cleanNumber.substring(7)}';
    }
    
    // Return original for international numbers or unknown formats
    return phoneNumber;
  }
}