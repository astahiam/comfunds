import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  group('Performance and Load Tests', () {
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

    group('API Performance Tests (NFR-001)', () {
      test('should respond within 200ms for 95% of requests', () async {
        // Arrange
        const int requestCount = 100;
        final List<int> responseTimes = [];
        final List<http.Response> responses = [];

        // Act
        for (int i = 0; i < requestCount; i++) {
          final stopwatch = Stopwatch()..start();
          
          final response = await http.get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          );
          
          stopwatch.stop();
          responseTimes.add(stopwatch.elapsedMilliseconds);
          responses.add(response);
        }

        // Assert
        expect(responses.length, requestCount);
        
        // Check that all responses are successful
        for (final response in responses) {
          expect(response.statusCode, 200);
        }

        // Calculate 95th percentile
        responseTimes.sort();
        final percentile95 = responseTimes[(responseTimes.length * 0.95).floor()];
        
        expect(percentile95, lessThan(200), reason: '95th percentile response time should be < 200ms');
        
        // Log performance metrics
        final avgResponseTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
        final minResponseTime = responseTimes.first;
        final maxResponseTime = responseTimes.last;
        
        print('Performance Test Results:');
        print('Average Response Time: ${avgResponseTime.toStringAsFixed(2)}ms');
        print('Min Response Time: ${minResponseTime}ms');
        print('Max Response Time: ${maxResponseTime}ms');
        print('95th Percentile: ${percentile95}ms');
      });

      test('should handle concurrent users (NFR-002)', () async {
        // Arrange
        const int concurrentUsers = 50;
        final List<Future<http.Response>> futures = [];

        // Act
        for (int i = 0; i < concurrentUsers; i++) {
          futures.add(http.get(
            Uri.parse('$baseUrl/public/projects'),
            headers: {'Content-Type': 'application/json'},
          ));
        }

        final responses = await Future.wait(futures);

        // Assert
        expect(responses.length, concurrentUsers);
        
        int successCount = 0;
        for (final response in responses) {
          if (response.statusCode == 200) {
            successCount++;
          }
        }

        final successRate = (successCount / concurrentUsers) * 100;
        expect(successRate, greaterThan(95), reason: 'Success rate should be > 95%');
        
        print('Concurrent Users Test Results:');
        print('Total Requests: $concurrentUsers');
        print('Successful Requests: $successCount');
        print('Success Rate: ${successRate.toStringAsFixed(2)}%');
      });

      test('should handle database operations efficiently', () async {
        // Arrange
        expect(authToken, isNotNull);
        const int operationCount = 50;
        final List<int> responseTimes = [];

        // Act
        for (int i = 0; i < operationCount; i++) {
          final stopwatch = Stopwatch()..start();
          
          final response = await http.get(
            Uri.parse('$baseUrl/user/projects'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          );
          
          stopwatch.stop();
          responseTimes.add(stopwatch.elapsedMilliseconds);
          
          expect(response.statusCode, 200);
        }

        // Assert
        final avgResponseTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
        expect(avgResponseTime, lessThan(500), reason: 'Average database operation should be < 500ms');
        
        print('Database Performance Test Results:');
        print('Average Response Time: ${avgResponseTime.toStringAsFixed(2)}ms');
      });
    });

    group('Load Testing (NFR-002)', () {
      test('should handle sustained load', () async {
        // Arrange
        const int totalRequests = 1000;
        const int batchSize = 10;
        final List<int> responseTimes = [];
        final List<http.Response> responses = [];

        // Act
        for (int batch = 0; batch < totalRequests / batchSize; batch++) {
          final batchFutures = <Future<http.Response>>[];
          
          for (int i = 0; i < batchSize; i++) {
            batchFutures.add(http.get(
              Uri.parse('$baseUrl/health'),
              headers: {'Content-Type': 'application/json'},
            ));
          }
          
          final batchResponses = await Future.wait(batchFutures);
          responses.addAll(batchResponses);
          
          // Small delay between batches to simulate realistic load
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Assert
        expect(responses.length, totalRequests);
        
        int successCount = 0;
        for (final response in responses) {
          if (response.statusCode == 200) {
            successCount++;
          }
        }

        final successRate = (successCount / totalRequests) * 100;
        expect(successRate, greaterThan(99), reason: 'Success rate should be > 99% under sustained load');
        
        print('Sustained Load Test Results:');
        print('Total Requests: $totalRequests');
        print('Successful Requests: $successCount');
        print('Success Rate: ${successRate.toStringAsFixed(2)}%');
      });

      test('should handle burst traffic', () async {
        // Arrange
        const int burstSize = 100;
        final List<Future<http.Response>> futures = [];

        // Act
        for (int i = 0; i < burstSize; i++) {
          futures.add(http.get(
            Uri.parse('$baseUrl/public/projects'),
            headers: {'Content-Type': 'application/json'},
          ));
        }

        final stopwatch = Stopwatch()..start();
        final responses = await Future.wait(futures);
        stopwatch.stop();

        // Assert
        expect(responses.length, burstSize);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000), reason: 'Burst should be handled within 5 seconds');
        
        int successCount = 0;
        for (final response in responses) {
          if (response.statusCode == 200) {
            successCount++;
          }
        }

        final successRate = (successCount / burstSize) * 100;
        expect(successRate, greaterThan(95), reason: 'Success rate should be > 95% under burst load');
        
        print('Burst Traffic Test Results:');
        print('Burst Size: $burstSize');
        print('Total Time: ${stopwatch.elapsedMilliseconds}ms');
        print('Successful Requests: $successCount');
        print('Success Rate: ${successRate.toStringAsFixed(2)}%');
      });
    });

    group('Memory and Resource Tests', () {
      test('should not have memory leaks during repeated operations', () async {
        // Arrange
        expect(authToken, isNotNull);
        const int operationCount = 100;
        final List<Map<String, dynamic>> responses = [];

        // Act
        for (int i = 0; i < operationCount; i++) {
          final response = await http.get(
            Uri.parse('$baseUrl/user/projects'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          );
          
          responses.add(jsonDecode(response.body));
          expect(response.statusCode, 200);
        }

        // Assert
        expect(responses.length, operationCount);
        
        // Check that response sizes are consistent (no memory growth)
        final firstResponseSize = responses.first.toString().length;
        final lastResponseSize = responses.last.toString().length;
        final sizeDifference = (lastResponseSize - firstResponseSize).abs();
        
        expect(sizeDifference, lessThan(1000), reason: 'Response size should remain consistent');
        
        print('Memory Test Results:');
        print('First Response Size: $firstResponseSize characters');
        print('Last Response Size: $lastResponseSize characters');
        print('Size Difference: $sizeDifference characters');
      });

      test('should handle large data sets efficiently', () async {
        // Arrange
        expect(authToken, isNotNull);
        final stopwatch = Stopwatch()..start();

        // Act
        final response = await http.get(
          Uri.parse('$baseUrl/public/projects?limit=100'),
          headers: {'Content-Type': 'application/json'},
        );
        
        stopwatch.stop();

        // Assert
        expect(response.statusCode, 200);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000), reason: 'Large dataset should load within 1 second');
        
        final responseData = jsonDecode(response.body);
        expect(responseData['data']['projects'], isList);
        
        print('Large Dataset Test Results:');
        print('Response Time: ${stopwatch.elapsedMilliseconds}ms');
        print('Projects Count: ${responseData['data']['projects'].length}');
      });
    });

    group('Error Handling Under Load', () {
      test('should handle errors gracefully under load', () async {
        // Arrange
        const int requestCount = 50;
        final List<http.Response> responses = [];

        // Act
        for (int i = 0; i < requestCount; i++) {
          final response = await http.get(
            Uri.parse('$baseUrl/projects/non-existent-id'),
            headers: {'Content-Type': 'application/json'},
          );
          
          responses.add(response);
        }

        // Assert
        expect(responses.length, requestCount);
        
        for (final response in responses) {
          expect(response.statusCode, 404);
        }
        
        print('Error Handling Test Results:');
        print('All requests returned proper 404 status');
      });

      test('should handle authentication errors under load', () async {
        // Arrange
        const int requestCount = 50;
        final List<http.Response> responses = [];

        // Act
        for (int i = 0; i < requestCount; i++) {
          final response = await http.get(
            Uri.parse('$baseUrl/auth/profile'),
            headers: {
              'Authorization': 'Bearer invalid-token',
              'Content-Type': 'application/json',
            },
          );
          
          responses.add(response);
        }

        // Assert
        expect(responses.length, requestCount);
        
        for (final response in responses) {
          expect(response.statusCode, 401);
        }
        
        print('Authentication Error Test Results:');
        print('All requests returned proper 401 status');
      });
    });

    group('Scalability Tests', () {
      test('should maintain performance with increasing load', () async {
        // Arrange
        const List<int> loadLevels = [10, 25, 50, 100];
        final Map<int, double> performanceMetrics = {};

        // Act
        for (final loadLevel in loadLevels) {
          final List<int> responseTimes = [];
          final List<Future<http.Response>> futures = [];

          for (int i = 0; i < loadLevel; i++) {
            futures.add(http.get(
              Uri.parse('$baseUrl/health'),
              headers: {'Content-Type': 'application/json'},
            ));
          }

          final stopwatch = Stopwatch()..start();
          final responses = await Future.wait(futures);
          stopwatch.stop();

          int successCount = 0;
          for (final response in responses) {
            if (response.statusCode == 200) {
              successCount++;
            }
          }

          final successRate = (successCount / loadLevel) * 100;
          performanceMetrics[loadLevel] = successRate;
        }

        // Assert
        for (final loadLevel in loadLevels) {
          final successRate = performanceMetrics[loadLevel]!;
          expect(successRate, greaterThan(90), reason: 'Success rate should be > 90% at load level $loadLevel');
        }
        
        print('Scalability Test Results:');
        for (final loadLevel in loadLevels) {
          print('Load Level $loadLevel: ${performanceMetrics[loadLevel]!.toStringAsFixed(2)}% success rate');
        }
      });

      test('should handle database connection pooling', () async {
        // Arrange
        expect(authToken, isNotNull);
        const int concurrentDbOperations = 20;
        final List<Future<http.Response>> futures = [];

        // Act
        for (int i = 0; i < concurrentDbOperations; i++) {
          futures.add(http.get(
            Uri.parse('$baseUrl/user/projects'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          ));
        }

        final responses = await Future.wait(futures);

        // Assert
        expect(responses.length, concurrentDbOperations);
        
        int successCount = 0;
        for (final response in responses) {
          if (response.statusCode == 200) {
            successCount++;
          }
        }

        final successRate = (successCount / concurrentDbOperations) * 100;
        expect(successRate, greaterThan(95), reason: 'Database operations should succeed > 95% of the time');
        
        print('Database Connection Pooling Test Results:');
        print('Concurrent Operations: $concurrentDbOperations');
        print('Successful Operations: $successCount');
        print('Success Rate: ${successRate.toStringAsFixed(2)}%');
      });
    });

    group('Frontend Performance Tests', () {
      test('should load landing page efficiently', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        final response = await http.get(
          Uri.parse('http://localhost:3000'),
          headers: {'Content-Type': 'text/html'},
        );
        
        stopwatch.stop();

        // Assert
        expect(response.statusCode, 200);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000), reason: 'Landing page should load within 1 second');
        
        print('Frontend Performance Test Results:');
        print('Landing Page Load Time: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle multiple concurrent frontend requests', () async {
        // Arrange
        const int concurrentRequests = 20;
        final List<Future<http.Response>> futures = [];

        // Act
        for (int i = 0; i < concurrentRequests; i++) {
          futures.add(http.get(
            Uri.parse('http://localhost:3000'),
            headers: {'Content-Type': 'text/html'},
          ));
        }

        final responses = await Future.wait(futures);

        // Assert
        expect(responses.length, concurrentRequests);
        
        for (final response in responses) {
          expect(response.statusCode, 200);
        }
        
        print('Frontend Concurrent Requests Test Results:');
        print('All $concurrentRequests requests succeeded');
      });
    });
  });
}
