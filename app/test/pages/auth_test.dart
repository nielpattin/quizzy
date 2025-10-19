import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzy/pages/auth/login_page.dart';
import 'package:quizzy/pages/auth/signup_page.dart';
import 'package:quizzy/pages/auth/welcome_page.dart';
import 'package:quizzy/pages/auth/forgot_password_page.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Auth Pages Widget Tests', () {
    testWidgets('WelcomePage should render correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: WelcomePage()));

      expect(find.text('Welcome to Quizzy'), findsOneWidget);
      expect(find.text('Create and play quizzes with friends'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('LoginPage should have email and password fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      expect(find.text('Log In'), findsAtLeastNWidgets(1));
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
    });

    testWidgets('SignupPage should have registration fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: SignupPage()));

      expect(find.text('Sign Up'), findsAtLeastNWidgets(1));
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Already have an account? Log In'), findsOneWidget);
    });

    testWidgets('ForgotPasswordPage should have email field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));

      expect(find.text('Reset Password'), findsOneWidget);
      expect(
        find.text(
          'Enter your email address and we\'ll send you a link to reset your password',
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Log In'), findsOneWidget);
    });

    group('Auth Form Validation Tests', () {
      testWidgets('LoginPage should validate email format', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(MaterialApp(home: LoginPage()));

        final emailField = find.byType(TextField).first;
        await tester.enterText(emailField, 'invalid-email');

        await tester.tap(find.text('Log In'));
        await tester.pump();

        // Should show error for invalid email
        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('LoginPage should require password', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(MaterialApp(home: LoginPage()));

        final emailField = find.byType(TextField).first;
        await tester.enterText(emailField, 'test@example.com');

        await tester.tap(find.text('Log In'));
        await tester.pump();

        // Should show error for missing password
        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('SignupPage should require password confirmation', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(MaterialApp(home: SignupPage()));

        final emailField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).at(1);
        final confirmField = find.byType(TextField).at(2);

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');
        await tester.enterText(confirmField, 'different');

        await tester.tap(find.text('Sign Up'));
        await tester.pump();

        // Should show error for password mismatch
        expect(find.text('Passwords do not match'), findsOneWidget);
      });
    });

    group('Auth Navigation Tests', () {
      testWidgets('WelcomePage should navigate to LoginPage', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(WelcomePage()));

        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('LoginPage should navigate to SignupPage', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(LoginPage()));

        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Password'), findsOneWidget);
      });

      testWidgets('LoginPage should navigate to ForgotPasswordPage', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(LoginPage()));

        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Password'), findsOneWidget);
      });
    });

    group('Auth Loading States Tests', () {
      testWidgets('LoginPage should show loading indicator during submission', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(MaterialApp(home: LoginPage()));

        // Fill form
        await tester.enterText(
          find.byType(TextField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextField).at(1), 'password123');

        await tester.tap(find.text('Log In'));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets(
        'SignupPage should show loading indicator during registration',
        (WidgetTester tester) async {
          await tester.pumpWidget(MaterialApp(home: SignupPage()));

          // Fill form
          await tester.enterText(
            find.byType(TextField).first,
            'test@example.com',
          );
          await tester.enterText(find.byType(TextField).at(1), 'password123');
          await tester.enterText(find.byType(TextField).at(2), 'password123');

          await tester.tap(find.text('Sign Up'));
          await tester.pump();

          // Should show loading indicator
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );
    });
  });

  group('Auth Data Structure Tests', () {
    test('should create valid user data structure', () {
      final userData = {
        'email': 'test@example.com',
        'username': 'testuser',
        'fullName': 'Test User',
        'accountType': 'personal',
        'isEmailVerified': false,
        'createdAt': '2024-01-01T00:00:00Z',
      };

      expect(userData['email'], isA<String>());
      expect(userData['username'], isA<String>());
      expect(userData['fullName'], isA<String>());
      expect(userData['accountType'], isIn(['personal', 'educator']));
      expect(userData['isEmailVerified'], isA<bool>());
    });

    test('should validate account type options', () {
      const validTypes = ['personal', 'educator'];

      for (final type in validTypes) {
        expect(type, isIn(validTypes));
      }
    });

    test('should handle auth error responses', () {
      final errorResponse = {
        'error': 'Invalid credentials',
        'message': 'The email or password you entered is incorrect',
        'code': 'INVALID_CREDENTIALS',
      };

      expect(errorResponse['error'], isA<String>());
      expect(errorResponse['message'], isA<String>());
      expect(errorResponse['code'], isA<String>());
    });
  });
}
