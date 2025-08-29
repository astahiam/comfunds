import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('End-to-End Regression Tests', () {
    const String baseUrl = 'http://localhost:8080/api/v1';
    String? authToken;
    String? userId;
    String? cooperativeId;
    String? businessId;
    String? projectId;
    String? investmentId;

    setUpAll(() async {
      // Setup test data and authentication
      await _setupTestEnvironment();
    });

    tearDownAll(() async {
      // Cleanup test data
      await _cleanupTestData();
    });

    group('Complete User Registration and Onboarding Flow', () {
      test('should complete full user registration and onboarding process', () async {
        // Step 1: Register new user
        final userData = {
          'email': 'e2e-test@example.com',
          'password': 'password123',
          'name': 'E2E Test User',
          'phone': '+6281234567890',
          'address': 'Jakarta, Indonesia',
          'cooperative_id': cooperativeId,
        };

        final registerResponse = await http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(userData),
        );

        expect(registerResponse.statusCode, 201);
        final registerData = jsonDecode(registerResponse.body);
        userId = registerData['data']['id'];

        // Step 2: Login with new user
        final loginResponse = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': userData['email'],
            'password': userData['password'],
          }),
        );

        expect(loginResponse.statusCode, 200);
        final loginData = jsonDecode(loginResponse.body);
        authToken = loginData['data']['token'];

        // Step 3: Verify user profile
        final profileResponse = await http.get(
          Uri.parse('$baseUrl/auth/profile'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(profileResponse.statusCode, 200);
        final profileData = jsonDecode(profileResponse.body);
        expect(profileData['data']['email'], userData['email']);
        expect(profileData['data']['name'], userData['name']);

        // Step 4: Update user profile
        final updateData = {
          'name': 'Updated E2E Test User',
          'phone': '+6289876543210',
        };

        final updateResponse = await http.put(
          Uri.parse('$baseUrl/auth/profile'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(updateData),
        );

        expect(updateResponse.statusCode, 200);
        final updatedProfileData = jsonDecode(updateResponse.body);
        expect(updatedProfileData['data']['name'], updateData['name']);
        expect(updatedProfileData['data']['phone'], updateData['phone']);
      });
    });

    group('Complete Business Creation and Management Flow', () {
      test('should create and manage business successfully', () async {
        // Step 1: Create business
        final businessData = {
          'name': 'E2E Test Business',
          'type': 'Technology',
          'description': 'A test business for end-to-end testing',
          'registration_number': 'BUS-E2E-001',
          'address': 'Jakarta, Indonesia',
          'cooperative_id': cooperativeId,
        };

        final createBusinessResponse = await http.post(
          Uri.parse('$baseUrl/businesses'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(businessData),
        );

        expect(createBusinessResponse.statusCode, 201);
        final businessResponseData = jsonDecode(createBusinessResponse.body);
        businessId = businessResponseData['data']['id'];

        // Step 2: Get business details
        final getBusinessResponse = await http.get(
          Uri.parse('$baseUrl/businesses/$businessId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(getBusinessResponse.statusCode, 200);
        final businessDetails = jsonDecode(getBusinessResponse.body);
        expect(businessDetails['data']['name'], businessData['name']);

        // Step 3: Update business
        final updateBusinessData = {
          'name': 'Updated E2E Test Business',
          'description': 'Updated description for end-to-end testing',
        };

        final updateBusinessResponse = await http.put(
          Uri.parse('$baseUrl/businesses/$businessId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(updateBusinessData),
        );

        expect(updateBusinessResponse.statusCode, 200);
        final updatedBusinessData = jsonDecode(updateBusinessResponse.body);
        expect(updatedBusinessData['data']['name'], updateBusinessData['name']);

        // Step 4: Submit business for approval
        final submitApprovalResponse = await http.post(
          Uri.parse('$baseUrl/businesses/$businessId/submit-approval'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(submitApprovalResponse.statusCode, 200);
      });
    });

    group('Complete Project Creation and Funding Flow', () {
      test('should create project and manage funding process', () async {
        // Step 1: Create project
        final projectData = {
          'title': 'E2E Test Project',
          'description': 'A test project for end-to-end funding testing',
          'target_amount': 2000000,
          'category': 'Technology',
          'cooperative_id': cooperativeId,
          'business_id': businessId,
        };

        final createProjectResponse = await http.post(
          Uri.parse('$baseUrl/projects'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(projectData),
        );

        expect(createProjectResponse.statusCode, 201);
        final projectResponseData = jsonDecode(createProjectResponse.body);
        projectId = projectResponseData['data']['id'];

        // Step 2: Get project details
        final getProjectResponse = await http.get(
          Uri.parse('$baseUrl/projects/$projectId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(getProjectResponse.statusCode, 200);
        final projectDetails = jsonDecode(getProjectResponse.body);
        expect(projectDetails['data']['title'], projectData['title']);

        // Step 3: Update project
        final updateProjectData = {
          'title': 'Updated E2E Test Project',
          'description': 'Updated description for end-to-end testing',
        };

        final updateProjectResponse = await http.put(
          Uri.parse('$baseUrl/projects/$projectId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(updateProjectData),
        );

        expect(updateProjectResponse.statusCode, 200);
        final updatedProjectData = jsonDecode(updateProjectResponse.body);
        expect(updatedProjectData['data']['title'], updateProjectData['title']);

        // Step 4: Get project funding progress
        final progressResponse = await http.get(
          Uri.parse('$baseUrl/investments/project/$projectId/progress'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(progressResponse.statusCode, 200);
        final progressData = jsonDecode(progressResponse.body);
        expect(progressData['data']['target_amount'], projectData['target_amount']);
      });
    });

    group('Complete Investment and Portfolio Management Flow', () {
      test('should create investment and manage portfolio', () async {
        // Step 1: Create investment
        final investmentData = {
          'project_id': projectId,
          'amount': 500000,
          'payment_method': 'bank_transfer',
        };

        final createInvestmentResponse = await http.post(
          Uri.parse('$baseUrl/investments'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(investmentData),
        );

        expect(createInvestmentResponse.statusCode, 201);
        final investmentResponseData = jsonDecode(createInvestmentResponse.body);
        investmentId = investmentResponseData['data']['id'];

        // Step 2: Get investment details
        final getInvestmentResponse = await http.get(
          Uri.parse('$baseUrl/investments/$investmentId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(getInvestmentResponse.statusCode, 200);
        final investmentDetails = jsonDecode(getInvestmentResponse.body);
        expect(investmentDetails['data']['amount'], investmentData['amount']);

        // Step 3: Get investor portfolio
        final portfolioResponse = await http.get(
          Uri.parse('$baseUrl/investments/portfolio'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(portfolioResponse.statusCode, 200);
        final portfolioData = jsonDecode(portfolioResponse.body);
        expect(portfolioData['data']['investments'], isList);

        // Step 4: Get my investments
        final myInvestmentsResponse = await http.get(
          Uri.parse('$baseUrl/investments/my-investments'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(myInvestmentsResponse.statusCode, 200);
        final myInvestmentsData = jsonDecode(myInvestmentsResponse.body);
        expect(myInvestmentsData['data']['investments'], isList);
      });
    });

    group('Complete Cooperative Management Flow', () {
      test('should manage cooperative operations', () async {
        // Step 1: Get cooperative details
        final getCooperativeResponse = await http.get(
          Uri.parse('$baseUrl/cooperatives/$cooperativeId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(getCooperativeResponse.statusCode, 200);
        final cooperativeDetails = jsonDecode(getCooperativeResponse.body);
        expect(cooperativeDetails['data']['id'], cooperativeId);

        // Step 2: Get cooperative members
        final membersResponse = await http.get(
          Uri.parse('$baseUrl/cooperatives/$cooperativeId/members'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(membersResponse.statusCode, 200);
        final membersData = jsonDecode(membersResponse.body);
        expect(membersData['data']['members'], isList);

        // Step 3: Get cooperative projects
        final cooperativeProjectsResponse = await http.get(
          Uri.parse('$baseUrl/cooperative/projects'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(cooperativeProjectsResponse.statusCode, 200);
        final cooperativeProjectsData = jsonDecode(cooperativeProjectsResponse.body);
        expect(cooperativeProjectsData['data']['projects'], isList);
      });
    });

    group('Complete Fund Management Flow', () {
      test('should manage fund disbursements and usage', () async {
        // Step 1: Create fund disbursement
        final disbursementData = {
          'project_id': projectId,
          'amount': 1000000,
          'purpose': 'Initial project funding',
          'disbursement_date': DateTime.now().toIso8601String(),
        };

        final createDisbursementResponse = await http.post(
          Uri.parse('$baseUrl/funds/disbursements'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(disbursementData),
        );

        expect(createDisbursementResponse.statusCode, 201);
        final disbursementResponseData = jsonDecode(createDisbursementResponse.body);
        final disbursementId = disbursementResponseData['data']['id'];

        // Step 2: Get disbursement details
        final getDisbursementResponse = await http.get(
          Uri.parse('$baseUrl/funds/disbursements/$disbursementId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(getDisbursementResponse.statusCode, 200);
        final disbursementDetails = jsonDecode(getDisbursementResponse.body);
        expect(disbursementDetails['data']['amount'], disbursementData['amount']);

        // Step 3: Create fund usage record
        final usageData = {
          'disbursement_id': disbursementId,
          'amount': 500000,
          'purpose': 'Equipment purchase',
          'usage_date': DateTime.now().toIso8601String(),
        };

        final createUsageResponse = await http.post(
          Uri.parse('$baseUrl/funds/usage'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(usageData),
        );

        expect(createUsageResponse.statusCode, 201);

        // Step 4: Get project disbursements
        final projectDisbursementsResponse = await http.get(
          Uri.parse('$baseUrl/funds/projects/$projectId/disbursements'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(projectDisbursementsResponse.statusCode, 200);
        final projectDisbursementsData = jsonDecode(projectDisbursementsResponse.body);
        expect(projectDisbursementsData['data']['disbursements'], isList);
      });
    });

    group('Complete Profit Sharing Flow', () {
      test('should manage profit sharing calculations and distributions', () async {
        // Step 1: Create profit calculation
        final calculationData = {
          'project_id': projectId,
          'total_profit': 500000,
          'calculation_date': DateTime.now().toIso8601String(),
          'profit_sharing_ratio': 0.7, // 70% to investors
        };

        final createCalculationResponse = await http.post(
          Uri.parse('$baseUrl/profit-sharing/calculations'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(calculationData),
        );

        expect(createCalculationResponse.statusCode, 201);
        final calculationResponseData = jsonDecode(createCalculationResponse.body);
        final calculationId = calculationResponseData['data']['id'];

        // Step 2: Get profit calculation details
        final getCalculationResponse = await http.get(
          Uri.parse('$baseUrl/profit-sharing/calculations/$calculationId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(getCalculationResponse.statusCode, 200);
        final calculationDetails = jsonDecode(getCalculationResponse.body);
        expect(calculationDetails['data']['total_profit'], calculationData['total_profit']);

        // Step 3: Create profit distribution
        final distributionData = {
          'calculation_id': calculationId,
          'distribution_date': DateTime.now().toIso8601String(),
          'total_distributed': 350000, // 70% of 500000
        };

        final createDistributionResponse = await http.post(
          Uri.parse('$baseUrl/profit-sharing/distributions'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(distributionData),
        );

        expect(createDistributionResponse.statusCode, 201);
        final distributionResponseData = jsonDecode(createDistributionResponse.body);
        final distributionId = distributionResponseData['data']['id'];

        // Step 4: Get project profit distributions
        final projectDistributionsResponse = await http.get(
          Uri.parse('$baseUrl/profit-sharing/projects/$projectId/distributions'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(projectDistributionsResponse.statusCode, 200);
        final projectDistributionsData = jsonDecode(projectDistributionsResponse.body);
        expect(projectDistributionsData['data']['distributions'], isList);
      });
    });

    group('Data Integrity and Consistency Tests', () {
      test('should maintain data consistency across all operations', () async {
        // Verify user data consistency
        final userProfileResponse = await http.get(
          Uri.parse('$baseUrl/auth/profile'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(userProfileResponse.statusCode, 200);
        final userProfile = jsonDecode(userProfileResponse.body);
        expect(userProfile['data']['id'], userId);

        // Verify business data consistency
        final businessResponse = await http.get(
          Uri.parse('$baseUrl/businesses/$businessId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(businessResponse.statusCode, 200);
        final businessData = jsonDecode(businessResponse.body);
        expect(businessData['data']['owner_id'], userId);

        // Verify project data consistency
        final projectResponse = await http.get(
          Uri.parse('$baseUrl/projects/$projectId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(projectResponse.statusCode, 200);
        final projectData = jsonDecode(projectResponse.body);
        expect(projectData['data']['business_id'], businessId);
        expect(projectData['data']['cooperative_id'], cooperativeId);

        // Verify investment data consistency
        final investmentResponse = await http.get(
          Uri.parse('$baseUrl/investments/$investmentId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        expect(investmentResponse.statusCode, 200);
        final investmentData = jsonDecode(investmentResponse.body);
        expect(investmentData['data']['investor_id'], userId);
        expect(investmentData['data']['project_id'], projectId);
      });
    });

    // Helper functions
    Future<void> _setupTestEnvironment() async {
      // Create test cooperative if needed
      final cooperativeData = {
        'name': 'E2E Test Cooperative',
        'registration_number': 'COOP-E2E-001',
        'address': 'Jakarta, Indonesia',
        'contact_email': 'contact@e2etestcoop.com',
        'contact_phone': '+6281234567890',
      };

      final cooperativeResponse = await http.post(
        Uri.parse('$baseUrl/cooperatives'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cooperativeData),
      );

      if (cooperativeResponse.statusCode == 201) {
        final cooperativeResponseData = jsonDecode(cooperativeResponse.body);
        cooperativeId = cooperativeResponseData['data']['id'];
      } else {
        // Use existing cooperative if creation fails
        cooperativeId = 'coop-1';
      }
    }

    Future<void> _cleanupTestData() async {
      // Cleanup test data in reverse order
      if (investmentId != null) {
        await http.delete(
          Uri.parse('$baseUrl/investments/$investmentId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );
      }

      if (projectId != null) {
        await http.delete(
          Uri.parse('$baseUrl/projects/$projectId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );
      }

      if (businessId != null) {
        await http.delete(
          Uri.parse('$baseUrl/businesses/$businessId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );
      }

      if (userId != null) {
        await http.delete(
          Uri.parse('$baseUrl/admin/users/$userId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );
      }
    }
  });
}
