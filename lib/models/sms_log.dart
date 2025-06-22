// lib/models/sms_log.dart
enum LogStatus {
  sent,
  failed,
  pending,
}

enum LogType {
  outbound,
  inbound,
}

class SMSLog {
  final String id;
  final String phoneNumber;
  final String message;
  final LogStatus status;
  final LogType type;
  final DateTime timestamp;

  SMSLog({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.status,
    required this.type,
    required this.timestamp,
  });

  factory SMSLog.fromJson(Map<String, dynamic> json) {
    return SMSLog(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? json['recipient']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: _parseStatus(json['status']?.toString()),
      type: _parseType(json['type']?.toString()),
      timestamp: _parseTimestamp(json['timestamp'] ?? json['created_at']),
    );
  }

  static LogStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
      case 'delivered':
      case 'success':
        return LogStatus.sent;
      case 'failed':
      case 'error':
        return LogStatus.failed;
      case 'pending':
      case 'processing':
        return LogStatus.pending;
      default:
        return LogStatus.pending;
    }
  }

  static LogType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'outbound':
      case 'sent':
      case 'outgoing':
        return LogType.outbound;
      case 'inbound':
      case 'received':
      case 'incoming':
        return LogType.inbound;
      default:
        return LogType.outbound;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    if (timestamp is int) {
      // Handle Unix timestamp (seconds or milliseconds)
      if (timestamp.toString().length == 10) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'message': message,
      'status': status.name,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}