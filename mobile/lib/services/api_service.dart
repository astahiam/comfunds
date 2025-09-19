import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String password,
    required String phone,
    required String address,
    required List<String> roles,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'name': name,
          'password': password,
          'phone': phone,
          'address': address,
          'roles': roles,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getProjects({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public/projects?page=$page&limit=$limit'),
        headers: _getHeaders(),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  Future<Map<String, dynamic>> getCooperatives({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public/cooperatives?page=$page&limit=$limit'),
        headers: _getHeaders(),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Failed to fetch cooperatives: $e');
    }
  }

  Future<Map<String, dynamic>> getHealthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _getHeaders(),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }
}
