// lib/services/log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LogService {
static const String baseUrl = 'https://8a9e-154-121-80-207.ngrok-free.app';
static const String apiKey = ''; 


  static Future<List<SMSLog>> fetchLogs({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    String? type,
    String? search,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};
      
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String();
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      // Build URL with query parameters
      String url = '$baseUrl/logs';
      if (queryParams.isNotEmpty) {
        String queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url += '?$queryString';
      }
      
      // Make HTTP request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'api-key': apiKey,
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Handle different response formats
        List<dynamic> logsData;
        if (responseData is String) {
          // If response is a string, try to parse it as JSON
          logsData = json.decode(responseData);
        } else if (responseData is List) {
          logsData = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          logsData = responseData['data'];
        } else {
          throw Exception('Unexpected response format');
        }
        
        // Convert to SMSLog objects
        return logsData.map((logData) => SMSLog.fromJson(logData)).toList();
        
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        throw Exception('Validation Error: ${errorData['detail']}');
      } else {
        throw Exception('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// Enhanced SMSLog class with JSON serialization
class SMSLog {
  final String id;
  final String phoneNumber;
  final String message;
  final LogStatus status;
  final LogType type;
  final DateTime timestamp;
  final double deliveryTime;

  SMSLog({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.status,
    required this.type,
    required this.timestamp,
    required this.deliveryTime,
  });

  factory SMSLog.fromJson(Map<String, dynamic> json) {
    return SMSLog(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      message: json['message'] ?? '',
      status: _parseStatus(json['status']),
      type: _parseType(json['type']),
      timestamp: _parseDateTime(json['timestamp'] ?? json['created_at']),
      deliveryTime: _parseDouble(json['delivery_time'] ?? json['deliveryTime']),
    );
  }

  static LogStatus _parseStatus(dynamic status) {
    if (status == null) return LogStatus.pending;
    
    switch (status.toString().toLowerCase()) {
      case 'sent':
      case 'delivered':
      case 'success':
        return LogStatus.sent;
      case 'failed':
      case 'error':
        return LogStatus.failed;
      case 'pending':
      case 'processing':
      default:
        return LogStatus.pending;
    }
  }

  static LogType _parseType(dynamic type) {
    if (type == null) return LogType.outbound;
    
    switch (type.toString().toLowerCase()) {
      case 'inbound':
      case 'incoming':
      case 'received':
        return LogType.inbound;
      case 'outbound':
      case 'outgoing':
      case 'sent':
      default:
        return LogType.outbound;
    }
  }

  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    } else if (timestamp is int) {
      // Assume Unix timestamp
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    
    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'message': message,
      'status': status.name,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'delivery_time': deliveryTime,
    };
  }
}

enum LogStatus { sent, failed, pending }
enum LogType { outbound, inbound }