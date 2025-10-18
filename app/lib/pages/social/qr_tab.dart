import "package:flutter/material.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "dart:async";
import "../../utils/camera_state_manager.dart";

// Enum to track camera state
enum CameraState { idle, starting, started, stopping, stopped }

class QRTab extends StatefulWidget {
  const QRTab({super.key});

  @override
  State<QRTab> createState() => _QRTabState();
}

class _QRTabState extends State<QRTab> with WidgetsBindingObserver {
  late final MobileScannerController _cameraController;
  bool _isCameraInitialized = false;
  bool _isPageVisible = true;
  bool _isDisposed = false; // Flag to track disposal state

  // Camera state management
  CameraState _cameraState = CameraState.idle;
  Timer? _cameraOperationTimer; // For debouncing camera operations

  // Global camera state manager
  final CameraStateManager _cameraStateManager = CameraStateManager();

  @override
  void initState() {
    super.initState();
    debugPrint("DEBUG: QRTab initState - tab is initializing");
    WidgetsBinding.instance.addObserver(this);
    _cameraController = MobileScannerController(
      autoStart: false, // We'll control when to start the camera
    );
    debugPrint("DEBUG: QRTab camera controller created");
    _isCameraInitialized = true;

    // Listen to camera state changes
    _cameraStateManager.addListener(_onCameraStateChanged);

    // Update the camera state manager that we're on the QR tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        "DEBUG: QRTab notifying camera state manager that we're on QR tab",
      );
      _cameraStateManager.setOnQRTab(true);

      // Check if we should start the camera based on the global state
      if (_cameraStateManager.isCameraActive) {
        debugPrint(
          "DEBUG: QRTab starting camera safely from initState (camera should be active)",
        );
        _startCameraSafely();
      } else {
        debugPrint(
          "DEBUG: QRTab not starting camera from initState (camera should not be active)",
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint("DEBUG: QRTab didChangeDependencies called");

    // Update the camera state manager that we're on the join page
    _cameraStateManager.setOnJoinPage(true);

    // Check if page is visible when dependencies change
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      final isVisible = route.isCurrent && route.isActive;
      debugPrint(
        "DEBUG: QRTab didChangeDependencies - route isCurrent: ${route.isCurrent}, isActive: ${route.isActive}, isVisible: $isVisible",
      );

      if (isVisible && !_isPageVisible) {
        debugPrint("DEBUG: QRTab became visible in didChangeDependencies");
        _isPageVisible = true;
        // Camera will be started by the camera state manager if needed
      } else if (!isVisible && _isPageVisible) {
        debugPrint("DEBUG: QRTab became hidden in didChangeDependencies");
        _isPageVisible = false;
        // Camera will be stopped by the camera state manager if needed
      }
    }
  }

  @override
  void dispose() {
    debugPrint("DEBUG: QRTab dispose - tab is being disposed");
    // Set disposed flag to prevent any setState calls
    _isDisposed = true;
    debugPrint("DEBUG: QRTab disposed flag set to true");
    // Cancel any pending camera operations
    _cameraOperationTimer?.cancel();
    debugPrint("DEBUG: QRTab camera operation timer cancelled");
    // Stop camera before disposing if it's initialized
    if (_isCameraInitialized) {
      debugPrint("DEBUG: QRTab stopping camera directly in dispose");
      // Always use the direct method in dispose to avoid setState calls
      _stopCameraDirectly();
      debugPrint("DEBUG: QRTab disposing camera controller");
      _cameraController.dispose();
    }
    debugPrint("DEBUG: QRTab removing camera state manager listener");
    _cameraStateManager.removeListener(_onCameraStateChanged);
    debugPrint(
      "DEBUG: QRTab notifying camera state manager that we're no longer on QR tab",
    );
    _cameraStateManager.setOnQRTab(false);
    debugPrint("DEBUG: QRTab removing WidgetsBinding observer");
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startCameraSafely() async {
    debugPrint(
      "DEBUG: QRTab _startCameraSafely called - current state: $_cameraState",
    );
    // Cancel any pending camera operations
    _cameraOperationTimer?.cancel();
    debugPrint("DEBUG: QRTab cancelled any pending camera operations");

    // Set camera state to starting only if widget is still mounted and not disposed
    if (mounted && !_isDisposed) {
      debugPrint("DEBUG: QRTab setting camera state to starting");
      setState(() {
        _cameraState = CameraState.starting;
      });
    } else {
      debugPrint(
        "DEBUG: QRTab not starting camera - mounted: $mounted, disposed: $_isDisposed",
      );
      return;
    }

    // Debounce camera start operation
    _cameraOperationTimer = Timer(const Duration(milliseconds: 300), () async {
      debugPrint("DEBUG: QRTab executing debounced camera start");
      try {
        debugPrint("DEBUG: QRTab attempting to start camera...");
        await _cameraController.start();
        debugPrint("DEBUG: QRTab camera started successfully");
        // Update state only if widget is still mounted and not disposed
        if (mounted && !_isDisposed) {
          debugPrint("DEBUG: QRTab setting camera state to started");
          setState(() {
            _cameraState = CameraState.started;
          });
        } else {
          debugPrint(
            "DEBUG: QRTab not updating state after start - mounted: $mounted, disposed: $_isDisposed",
          );
        }
      } catch (e) {
        debugPrint("DEBUG: QRTab error starting camera: $e");
        // Update state only if widget is still mounted and not disposed
        if (mounted && !_isDisposed) {
          debugPrint("DEBUG: QRTab setting camera state to idle due to error");
          setState(() {
            _cameraState = CameraState.idle;
          });
        }

        // Handle specific MobileScannerException
        if (e.toString().contains("controllerInitializing")) {
          debugPrint("DEBUG: QRTab camera is still initializing, retrying...");
          // Retry after a short delay
          _cameraOperationTimer = Timer(const Duration(milliseconds: 500), () {
            debugPrint(
              "DEBUG: QRTab retrying camera start after initialization delay",
            );
            if (_isPageVisible && !_isDisposed) {
              _startCameraSafely();
            } else {
              debugPrint(
                "DEBUG: QRTab not retrying camera start - page visible: $_isPageVisible, disposed: $_isDisposed",
              );
            }
          });
        }
      }
    });
  }

  void _stopCameraDirectly() async {
    debugPrint(
      "DEBUG: QRTab _stopCameraDirectly called - current state: $_cameraState",
    );
    // Cancel any pending camera operations
    _cameraOperationTimer?.cancel();
    debugPrint("DEBUG: QRTab cancelled any pending camera operations");

    try {
      debugPrint("DEBUG: QRTab stopping camera directly...");
      await _cameraController.stop();
      debugPrint("DEBUG: QRTab camera stopped directly");
    } catch (e) {
      debugPrint("DEBUG: QRTab error stopping camera directly: $e");
    }
  }

  void _stopCameraSafely() async {
    debugPrint(
      "DEBUG: QRTab _stopCameraSafely called - current state: $_cameraState",
    );
    // Cancel any pending camera operations
    _cameraOperationTimer?.cancel();
    debugPrint("DEBUG: QRTab cancelled any pending camera operations");

    // Set camera state to stopping only if widget is still mounted and not disposed
    if (mounted && !_isDisposed) {
      debugPrint("DEBUG: QRTab setting camera state to stopping");
      setState(() {
        _cameraState = CameraState.stopping;
      });
    } else {
      debugPrint(
        "DEBUG: QRTab not stopping camera safely - mounted: $mounted, disposed: $_isDisposed",
      );
      return;
    }

    // Debounce camera stop operation
    _cameraOperationTimer = Timer(const Duration(milliseconds: 100), () async {
      debugPrint("DEBUG: QRTab executing debounced camera stop");
      try {
        debugPrint("DEBUG: QRTab attempting to stop camera...");
        await _cameraController.stop();
        debugPrint("DEBUG: QRTab camera stopped successfully");
        // Update state only if widget is still mounted and not disposed
        if (mounted && !_isDisposed) {
          debugPrint("DEBUG: QRTab setting camera state to stopped");
          setState(() {
            _cameraState = CameraState.stopped;
          });
        } else {
          debugPrint(
            "DEBUG: QRTab not updating state after stop - mounted: $mounted, disposed: $_isDisposed",
          );
        }
      } catch (e) {
        debugPrint("DEBUG: QRTab error stopping camera: $e");
        // Update state only if widget is still mounted and not disposed
        if (mounted && !_isDisposed) {
          debugPrint("DEBUG: QRTab setting camera state to idle due to error");
          setState(() {
            _cameraState = CameraState.idle;
          });
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint(
      "DEBUG: QRTab app lifecycle state changed to: $state, current camera state: $_cameraState",
    );

    switch (state) {
      case AppLifecycleState.paused:
        // App is paused (user went to home screen, etc.)
        debugPrint("DEBUG: QRTab app paused - stopping camera");
        // Only stop if camera is currently active
        if (_cameraState == CameraState.started ||
            _cameraState == CameraState.starting) {
          debugPrint("DEBUG: QRTab stopping camera due to app pause");
          _stopCameraSafely();
        } else {
          debugPrint(
            "DEBUG: QRTab not stopping camera on pause - current state: $_cameraState",
          );
        }
        break;
      case AppLifecycleState.inactive:
        // App is inactive (app is transitioning, etc.)
        debugPrint("DEBUG: QRTab app inactive - stopping camera");
        // Only stop if camera is currently active
        if (_cameraState == CameraState.started ||
            _cameraState == CameraState.starting) {
          debugPrint("DEBUG: QRTab stopping camera due to app inactive");
          _stopCameraSafely();
        } else {
          debugPrint(
            "DEBUG: QRTab not stopping camera on inactive - current state: $_cameraState",
          );
        }
        break;
      case AppLifecycleState.resumed:
        // App is resumed - check if camera should be active
        debugPrint(
          "DEBUG: QRTab app resumed - checking if camera should be active",
        );
        // Let the camera state manager decide if the camera should be active
        if (_cameraStateManager.isCameraActive &&
            (_cameraState == CameraState.idle ||
                _cameraState == CameraState.stopped)) {
          debugPrint("DEBUG: QRTab starting camera due to app resume");
          _startCameraSafely();
        } else {
          debugPrint(
            "DEBUG: QRTab camera should not be active or already active - current state: $_cameraState, global state: ${_cameraStateManager.isCameraActive}",
          );
        }
        break;
      case AppLifecycleState.detached:
        // App is being detached - camera will be disposed in dispose()
        debugPrint(
          "DEBUG: QRTab app detached - camera will be disposed in dispose()",
        );
        break;
      case AppLifecycleState.hidden:
        // App is hidden (new in Flutter 3.13)
        debugPrint("DEBUG: QRTab app hidden - stopping camera");
        // Only stop if camera is currently active
        if (_cameraState == CameraState.started ||
            _cameraState == CameraState.starting) {
          debugPrint("DEBUG: QRTab stopping camera due to app hidden");
          _stopCameraSafely();
        } else {
          debugPrint(
            "DEBUG: QRTab not stopping camera on hidden - current state: $_cameraState",
          );
        }
        break;
    }
  }

  /// Called when the camera state changes
  void _onCameraStateChanged() {
    debugPrint(
      "DEBUG: QRTab _onCameraStateChanged called - global camera active: ${_cameraStateManager.isCameraActive}",
    );

    if (_isDisposed) {
      debugPrint(
        "DEBUG: QRTab widget is disposed, ignoring camera state change",
      );
      return;
    }

    if (_cameraStateManager.isCameraActive) {
      // Camera should be active
      if (_cameraState == CameraState.idle ||
          _cameraState == CameraState.stopped) {
        debugPrint("DEBUG: QRTab starting camera due to global state change");
        _startCameraSafely();
      } else {
        debugPrint(
          "DEBUG: QRTab camera already active or starting, state: $_cameraState",
        );
      }
    } else {
      // Camera should be inactive
      if (_cameraState == CameraState.started ||
          _cameraState == CameraState.starting) {
        debugPrint("DEBUG: QRTab stopping camera due to global state change");
        _stopCameraSafely();
      } else {
        debugPrint(
          "DEBUG: QRTab camera already stopped or stopping, state: $_cameraState",
        );
      }
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    debugPrint(
      "DEBUG: QRTab _handleBarcode called with ${capture.barcodes.length} barcodes",
    );
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      final code = barcode!.rawValue!;
      debugPrint("DEBUG: QRTab barcode detected with value: $code");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Scanned code: $code"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      debugPrint("DEBUG: QRTab no valid barcode found in capture");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "DEBUG: QRTab build called - camera state: $_cameraState, page visible: $_isPageVisible",
    );
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _cameraController,
                onDetect: _handleBarcode,
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  children: [
                    Text(
                      "Point camera at QR code",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _cameraController.toggleTorch(),
                          icon: ValueListenableBuilder(
                            valueListenable: _cameraController,
                            builder: (context, state, child) {
                              return Icon(
                                state.torchState == TorchState.on
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                color: Colors.white,
                                size: 32,
                              );
                            },
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        IconButton(
                          onPressed: () => _cameraController.switchCamera(),
                          icon: Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                            size: 32,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
