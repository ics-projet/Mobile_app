// lib/config/api_config.dart
class ApiConfig {
  // Base URL without trailing slash
  static const String baseUrl = 'https://abfe-154-121-111-119.ngrok-free.app';
  // Alternative: Use ngrok URL for testing
  // static const String baseUrl = 'https://abfe-154-121-111-119.ngrok-free.app';
  
  // Endpoints with leading slash
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String refreshTokenEndpoint = '/refresh';
  static const String logoutEndpoint = '/logout';
  static const String smsEndpoint = '/sms';
  static const String smsInboxEndpoint = '/sms/inbox';
  static const String logsEndpoint = '/logs';
  
  // Timeout configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Helper method to build full URLs
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Default headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  // Headers with API key
  static Map<String, String> headersWithApiKey(String apiKey) => {
    ...defaultHeaders,
    'api_key': apiKey,
  };
}