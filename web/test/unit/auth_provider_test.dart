import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:comfunds_web/providers/auth_provider.dart';
import 'package:comfunds_web/models/user.dart';

void main() {
  group('AuthProvider Unit Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('initial state should be unauthenticated', () {
      expect(authProvider.user, isNull);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.error, isNull);
    });

    test('login should set loading state and authenticate user', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';

      // Act
      final result = await authProvider.login(email, password);

      // Assert
      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user!.email, email);
      expect(authProvider.user!.name, 'John Doe');
      expect(authProvider.isLoading, false);
      expect(authProvider.error, isNull);
    });

    test('login should handle errors gracefully', () async {
      // Arrange
      const email = 'invalid@example.com';
      const password = 'wrongpassword';

      // Act
      final result = await authProvider.login(email, password);

      // Assert
      expect(result, false);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
      expect(authProvider.error, isNotNull);
    });

    test('register should create new user account', () async {
      // Arrange
      const email = 'newuser@example.com';
      const password = 'password123';
      const name = 'New User';
      const phone = '+6281234567890';

      // Act
      final result = await authProvider.register(email, password, name, phone);

      // Assert
      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user!.email, email);
      expect(authProvider.user!.name, name);
      expect(authProvider.user!.phone, phone);
    });

    test('logout should clear user data', () async {
      // Arrange
      await authProvider.login('test@example.com', 'password123');
      expect(authProvider.isAuthenticated, true);

      // Act
      authProvider.logout();

      // Assert
      expect(authProvider.user, isNull);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.error, isNull);
    });

    test('updateProfile should modify user data', () async {
      // Arrange
      await authProvider.login('test@example.com', 'password123');
      const newName = 'Updated Name';
      const newPhone = '+6289876543210';

      // Act
      final result = await authProvider.updateProfile(newName, newPhone);

      // Assert
      expect(result, true);
      expect(authProvider.user!.name, newName);
      expect(authProvider.user!.phone, newPhone);
    });

    test('user should have correct roles', () async {
      // Arrange & Act
      await authProvider.login('test@example.com', 'password123');

      // Assert
      expect(authProvider.user!.roles, contains('member'));
      expect(authProvider.user!.roles, contains('investor'));
      expect(authProvider.user!.roles.length, 2);
    });

    test('user should have correct KYC status', () async {
      // Arrange & Act
      await authProvider.login('test@example.com', 'password123');

      // Assert
      expect(authProvider.user!.kycStatus, 'verified');
    });

    test('user should be active by default', () async {
      // Arrange & Act
      await authProvider.login('test@example.com', 'password123');

      // Assert
      expect(authProvider.user!.isActive, true);
    });
  });
}
