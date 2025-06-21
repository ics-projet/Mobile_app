// lib/services/log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sms_log.dart';

class LogService {
  static const String baseUrl = 'http://127.0.0.1:8080';
  static const String apiKey = '11fdb993-f28c-4048-9998-659f0bd9ee8b';

  static Future<List<SMSLog>> fetchLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/logs'),
        headers: {
          'api-key': apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => SMSLog.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching logs: $e');
    }
  }
}