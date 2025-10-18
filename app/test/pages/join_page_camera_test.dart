import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quizzy/pages/social/join_page.dart';
import 'package:quizzy/pages/social/qr_tab.dart';

// Mock MobileScannerController for testing
class MockMobileScannerController extends MobileScannerController {
  bool _isStarted = false;
  bool _throwControllerInitializingError = false;
  int _startCallCount = 0;
  int _stopCallCount = 0;

  MockMobileScannerController({super.autoStart = false});

  @override
  Future<void> start({CameraFacing? cameraDirection}) async {
    _startCallCount++;
    if (_throwControllerInitializingError) {
      _throwControllerInitializingError = false;
      throw Exception('MobileScannerException(controllerInitializing)');
    }
    _isStarted = true;
  }

  @override
  Future<void> stop() async {
    _stopCallCount++;
    _isStarted = false;
  }

  bool get isStarted => _isStarted;
  int get startCallCount => _startCallCount;
  int get stopCallCount => _stopCallCount;

  void setThrowControllerInitializingError(bool value) {
    _throwControllerInitializingError = value;
  }
}

void main() {
  group('JoinPage Camera Lifecycle Management Tests', () {
    late Widget testWidget;

    setUp(() {
      testWidget = MaterialApp(home: JoinPage(showBottomNav: false));
    });

    testWidgets('Camera UI switches when changing tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);

      // Initially Enter Code tab should be selected
      expect(find.text('Enter Game Code'), findsOneWidget);
      expect(find.byType(MobileScanner), findsNothing);

      // Find and tap the QR Code tab
      final qrTabFinder = find.text('Scan QR Code');
      expect(qrTabFinder, findsOneWidget);
      await tester.tap(qrTabFinder);
      await tester.pump();

      // Now QR scanner should be visible
      expect(find.byType(MobileScanner), findsOneWidget);

      // Switch back to Enter Code tab
      final enterCodeTabFinder = find.text('Enter Code');
      await tester.tap(enterCodeTabFinder);
      await tester.pump();

      // QR scanner should no longer be visible
      expect(find.byType(MobileScanner), findsNothing);
    });

    testWidgets('Navigation buttons are present and functional', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);

      // Check for navigation buttons
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      // Test search button
      final searchButtonFinder = find.byIcon(Icons.search);
      await tester.tap(searchButtonFinder);
      await tester.pump();

      // Should show search functionality
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('App lifecycle changes are handled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);

      // Switch to QR tab first
      final qrTabFinder = find.text('Scan QR Code');
      await tester.tap(qrTabFinder);
      await tester.pump();

      // QR scanner should be visible
      expect(find.byType(MobileScanner), findsOneWidget);

      // Simulate app going to background
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        StringCodec().encodeMessage('AppLifecycleState.paused'),
        (data) {},
      );
      await tester.pump();

      // Simulate app coming to foreground
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        StringCodec().encodeMessage('AppLifecycleState.resumed'),
        (data) {},
      );
      await tester.pump();

      // QR scanner should still be visible after resume
      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('Rapid tab switching works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);

      // Rapidly switch between tabs
      final qrTabFinder = find.text('Scan QR Code');
      final enterCodeTabFinder = find.text('Enter Code');

      for (int i = 0; i < 5; i++) {
        await tester.tap(qrTabFinder);
        await tester.pump(); // Don't wait for debounce
        await tester.tap(enterCodeTabFinder);
        await tester.pump(); // Don't wait for debounce
      }

      // Wait for all operations to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Should be on Enter Code tab (last tapped)
      expect(find.text('Enter Game Code'), findsOneWidget);
      expect(find.byType(MobileScanner), findsNothing);
    });

    testWidgets('QR scanner controls are present', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);

      // Switch to QR tab
      final qrTabFinder = find.text('Scan QR Code');
      await tester.tap(qrTabFinder);
      await tester.pump();

      // Check for scanner controls
      expect(find.text('Point camera at QR code'), findsOneWidget);
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_ios), findsOneWidget);
    });
  });

  group('Camera State Management Logic Tests', () {
    test('CameraState enum has correct values', () {
      expect(CameraState.values, contains(CameraState.idle));
      expect(CameraState.values, contains(CameraState.starting));
      expect(CameraState.values, contains(CameraState.started));
      expect(CameraState.values, contains(CameraState.stopping));
      expect(CameraState.values, contains(CameraState.stopped));
    });
  });
}
