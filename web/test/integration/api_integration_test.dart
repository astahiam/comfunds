import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('API Integration Tests', () {
    const String baseUrl = 'http://localhost:8080/api/v1';
    String? authToken;

    setUpAll(() async {
      // Get authentication token for tests
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'test@example.com',
          'password': 'password123',
        }),
      );

      if (loginResponse.statusCode == 200) {
        final responseData = jsonDecode(loginResponse.body);
        authToken = responseData['data']['token'];
      }
    });

    group('Authentication API Tests', () {
      test('should register new user successfully', () async {
        // Arrange
        final userData = {
          'email': 'newuser@example.com',
          'password': 'password123',
          'name': 'New Test User',
          'phone': '+6281234567890',
          'address': 'Jakarta, Indonesia',
          'cooperative_id': 'coop-1',
        };

        // Act
        final response = await http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(userData),
        );

        // Assert
        expect(response.statusCode, 201);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['email'], userData['email']);
        expect(responseData['data']['name'], userData['name']);
      });

      test('should login user successfully', () async {
        // Arrange
        final loginData = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        // Act
        final response = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(loginData),
        );

        // Assert
        expect(response.statusCode, 200);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['token'], isNotNull);
        expect(responseData['data']['user']['email'], loginData['email']);
      });

      test('should get user profile successfully', () async {
        // Arrange
        expect(authToken, isNotNull);

        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/auth/profile'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        // Assert
        expect(response.statusCode, 200);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['email'], 'test@example.com');
      });
    });

    group('Project API Tests', () {
      test('should get public projects successfully', () async {
        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/public/projects'),
          headers: {'Content-Type': 'application/json'},
        );

        // Assert
        expect(response.statusCode, 200);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['projects'], isList);
      });

      test('should create new project successfully', () async {
        // Arrange
        expect(authToken, isNotNull);
        final projectData = {
          'title': 'Test Integration Project',
          'description': 'A test project created via API integration test',
          'target_amount': 1000000,
          'category': 'Technology',
          'cooperative_id': 'coop-1',
          'business_id': 'business-1',
        };

        // Act
        final response = await http.post(
          Uri.parse('$baseUrl/projects'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(projectData),
        );

        // Assert
        expect(response.statusCode, 201);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['title'], projectData['title']);
        expect(responseData['data']['description'], projectData['description']);
      });

      test('should get user projects successfully', () async {
        // Arrange
        expect(authToken, isNotNull);

        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/user/projects'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        // Assert
        expect(response.statusCode, 200);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['projects'], isList);
      });
    });

    group('Investment API Tests', () {
      test('should create investment successfully', () async {
        // Arrange
        expect(authToken, isNotNull);
        final investmentData = {
          'project_id': 'test-project-id',
          'amount': 500000,
          'payment_method': 'bank_transfer',
        };

        // Act
        final response = await http.post(
          Uri.parse('$baseUrl/investments'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(investmentData),
        );

        // Assert
        expect(response.statusCode, 201);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['amount'], investmentData['amount']);
      });

      test('should get investor portfolio successfully', () async {
        // Arrange
        expect(authToken, isNotNull);

        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/investments/portfolio'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        // Assert
        expect(response.statusCode, 200);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['investments'], isList);
      });
    });

    group('Cooperative API Tests', () {
      test('should get cooperatives successfully', () async {
        // Arrange
        expect(authToken, isNotNull);

        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/cooperatives'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        // Assert
        expect(response.statusCode, 200);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['cooperatives'], isList);
      });

      test('should create cooperative successfully (admin only)', () async {
        // Arrange
        expect(authToken, isNotNull);
        final cooperativeData = {
          'name': 'Test Cooperative',
          'registration_number': 'COOP-2024-001',
          'address': 'Jakarta, Indonesia',
          'contact_email': 'contact@testcoop.com',
          'contact_phone': '+6281234567890',
        };

        // Act
        final response = await http.post(
          Uri.parse('$baseUrl/cooperatives'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(cooperativeData),
        );

        // Assert
        // Note: This might fail if user doesn't have admin role
        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          expect(responseData['status'], 'success');
          expect(responseData['data']['name'], cooperativeData['name']);
        } else {
          expect(response.statusCode, 403); // Forbidden - not admin
        }
      });
    });

    group('Business API Tests', () {
      test('should create business successfully', () async {
        // Arrange
        expect(authToken, isNotNull);
        final businessData = {
          'name': 'Test Business',
          'type': 'Technology',
          'description': 'A test business for integration testing',
          'registration_number': 'BUS-2024-001',
          'address': 'Jakarta, Indonesia',
          'cooperative_id': 'coop-1',
        };

        // Act
        final response = await http.post(
          Uri.parse('$baseUrl/businesses'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(businessData),
        );

        // Assert
        expect(response.statusCode, 201);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['name'], businessData['name']);
        expect(responseData['data']['type'], businessData['type']);
      });

      test('should get business details successfully', () async {
        // Arrange
        expect(authToken, isNotNull);
        const businessId = 'test-business-id';

        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/businesses/$businessId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        // Assert
        expect(response.statusCode, 200);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'success');
        expect(responseData['data']['id'], businessId);
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid authentication', () async {
        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/auth/profile'),
          headers: {
            'Authorization': 'Bearer invalid-token',
            'Content-Type': 'application/json',
          },
        );

        // Assert
        expect(response.statusCode, 401);
      });

      test('should handle invalid project creation data', () async {
        // Arrange
        expect(authToken, isNotNull);
        final invalidProjectData = {
          'title': '', // Empty title should fail validation
          'description': 'Test description',
          'target_amount': -1000, // Negative amount should fail validation
        };

        // Act
        final response = await http.post(
          Uri.parse('$baseUrl/projects'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(invalidProjectData),
        );

        // Assert
        expect(response.statusCode, 400);
        final responseData = jsonDecode(response.body);
        expect(responseData['status'], 'error');
      });

      test('should handle non-existent resource', () async {
        // Arrange
        expect(authToken, isNotNull);

        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/projects/non-existent-id'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        // Assert
        expect(response.statusCode, 404);
      });
    });

    group('Performance Tests', () {
      test('should respond within acceptable time for health check', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/health'),
          headers: {'Content-Type': 'application/json'},
        );

        stopwatch.stop();

        // Assert
        expect(response.statusCode, 200);
        expect(stopwatch.elapsedMilliseconds, lessThan(200)); // NFR-001: < 200ms
      });

      test('should handle concurrent requests', () async {
        // Arrange
        final futures = List.generate(10, (index) {
          return http.get(
            Uri.parse('$baseUrl/public/projects'),
            headers: {'Content-Type': 'application/json'},
          );
        });

        // Act
        final responses = await Future.wait(futures);

        // Assert
        for (final response in responses) {
          expect(response.statusCode, 200);
        }
      });
    });
  });
}
