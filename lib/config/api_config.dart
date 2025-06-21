class ApiConfig {
  // Option 2: Keep trailing slash in baseUrl
  static const String baseUrl = 'http://192.168.205.216:8000/'; 
  
  // Add leading slashes to all endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String refreshTokenEndpoint = '/refresh';
  static const String logoutEndpoint = '/logout';
  
  static const Duration requestTimeout = Duration(seconds: 30);
}