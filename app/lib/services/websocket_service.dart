import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';

// WebSocket message types
enum WebSocketMessageType {
  connected,
  disconnected,
  error,
  sessionJoined,
  sessionLeft,
  sessionStarted,
  sessionEnded,
  participantJoined,
  participantLeft,
  participantDisconnected,
  leaderboardUpdate,
  sessionUpdate,
  sessionState,
  ping,
  pong,
  notification,
}

// WebSocket message model
class WebSocketMessage {
  final WebSocketMessageType type;
  final String? sessionId;
  final Map<String, dynamic>? data;
  final String? message;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    this.sessionId,
    this.data,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    WebSocketMessageType messageType;
    switch (json['type']) {
      case 'connected':
        messageType = WebSocketMessageType.connected;
        break;
      case 'disconnected':
        messageType = WebSocketMessageType.disconnected;
        break;
      case 'error':
        messageType = WebSocketMessageType.error;
        break;
      case 'session_joined':
        messageType = WebSocketMessageType.sessionJoined;
        break;
      case 'session_left':
        messageType = WebSocketMessageType.sessionLeft;
        break;
      case 'session_started':
        messageType = WebSocketMessageType.sessionStarted;
        break;
      case 'session_ended':
        messageType = WebSocketMessageType.sessionEnded;
        break;
      case 'participant_joined':
        messageType = WebSocketMessageType.participantJoined;
        break;
      case 'participant_left':
        messageType = WebSocketMessageType.participantLeft;
        break;
      case 'participant_disconnected':
        messageType = WebSocketMessageType.participantDisconnected;
        break;
      case 'leaderboard_update':
        messageType = WebSocketMessageType.leaderboardUpdate;
        break;
      case 'session_update':
        messageType = WebSocketMessageType.sessionUpdate;
        break;
      case 'session_state':
        messageType = WebSocketMessageType.sessionState;
        break;
      case 'ping':
        messageType = WebSocketMessageType.ping;
        break;
      case 'pong':
        messageType = WebSocketMessageType.pong;
        break;
      case 'notification':
        messageType = WebSocketMessageType.notification;
        break;
      default:
        // Silently treat unknown types as notifications to reduce log spam
        messageType = WebSocketMessageType.notification;
    }

    return WebSocketMessage(
      type: messageType,
      sessionId: json['sessionId'],
      data:
          json['data'] ??
          json['notification'] ??
          json['participant'] ??
          json['leaderboard'] ??
          json['session'],
      message: json['message'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'sessionId': sessionId,
      'data': data,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Connection status enum
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

// Participant model
class Participant {
  final String id;
  final String userId;
  final String username;
  final String? fullName;
  final String? profilePictureUrl;
  final int score;
  final int? rank;
  final DateTime joinedAt;

  Participant({
    required this.id,
    required this.userId,
    required this.username,
    this.fullName,
    this.profilePictureUrl,
    this.score = 0,
    this.rank,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both direct fields and nested user object
      final String id = json['id'] as String;
      final String userId =
          json['userId'] as String? ??
          json['user']?['id'] as String? ??
          json['id'] as String;
      final String username =
          json['username'] as String? ??
          json['user']?['username'] as String? ??
          'Unknown';
      final String? fullName =
          json['fullName'] as String? ?? json['user']?['fullName'] as String?;
      final String? profilePictureUrl =
          json['profilePictureUrl'] as String? ??
          json['user']?['profilePictureUrl'] as String?;
      final int score = json['score'] as int? ?? 0;
      final int? rank = json['rank'] as int?;

      // Parse joinedAt - handle both string and DateTime, default to now if missing
      DateTime joinedAt;
      if (json['joinedAt'] != null) {
        if (json['joinedAt'] is String) {
          joinedAt = DateTime.parse(json['joinedAt'] as String);
        } else if (json['joinedAt'] is DateTime) {
          joinedAt = json['joinedAt'] as DateTime;
        } else {
          debugPrint(
            '[Participant] ⚠️ joinedAt has unexpected type: ${json['joinedAt'].runtimeType}',
          );
          joinedAt = DateTime.now();
        }
      } else {
        joinedAt = DateTime.now();
      }

      return Participant(
        id: id,
        userId: userId,
        username: username,
        fullName: fullName,
        profilePictureUrl: profilePictureUrl,
        score: score,
        rank: rank,
        joinedAt: joinedAt,
      );
    } catch (e, stack) {
      debugPrint('[Participant] ❌ Error parsing JSON: $e');
      debugPrint('[Participant] JSON data: $json');
      debugPrint('[Participant] Stack trace: $stack');
      rethrow;
    }
  }
}

// Session model
class LiveSession {
  final String id;
  final String title;
  final bool isLive;
  final int participantCount;
  final String? code;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final List<Participant> participants;

  LiveSession({
    required this.id,
    required this.title,
    required this.isLive,
    required this.participantCount,
    this.code,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    this.participants = const [],
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    List<Participant> participants = [];
    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((p) => Participant.fromJson(p))
          .toList();
    }

    return LiveSession(
      id: json['id'],
      title: json['title'],
      isLive: json['isLive'] ?? false,
      participantCount: json['participantCount'] ?? 0,
      code: json['code'],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      participants: participants,
    );
  }
}

// WebSocket Service
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentSessionId;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  // Stream controllers
  final _connectionStatusController = BehaviorSubject<ConnectionStatus>.seeded(
    ConnectionStatus.disconnected,
  );
  final _messageController = BehaviorSubject<WebSocketMessage?>();
  final _sessionController = BehaviorSubject<LiveSession?>();
  final _participantsController = BehaviorSubject<List<Participant>>.seeded([]);
  final _leaderboardController = BehaviorSubject<List<Participant>>.seeded([]);

  // Public streams
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;
  Stream<WebSocketMessage> get messages => _messageController.stream
      .where((m) => m != null)
      .cast<WebSocketMessage>();
  Stream<LiveSession?> get session => _sessionController.stream;
  Stream<List<Participant>> get participants => _participantsController.stream;
  Stream<List<Participant>> get leaderboard => _leaderboardController.stream;

  ConnectionStatus get currentStatus => _connectionStatusController.value;
  LiveSession? get currentSession => _sessionController.value;

  Future<void> connect() async {
    if (_channel != null && currentStatus == ConnectionStatus.connected) {
      return;
    }

    _isDisposed = false; // Reset disposal flag when reconnecting
    _updateConnectionStatus(ConnectionStatus.connecting);

    try {
      Session? session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session');
      }

      // Check if token expires soon (within 5 minutes) and refresh proactively
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeUntilExpiry = expiresAt - now;

        if (timeUntilExpiry < 300) {
          debugPrint(
            '[WebSocket] Token expires in ${timeUntilExpiry}s, refreshing before connect...',
          );
          try {
            final response = await Supabase.instance.client.auth
                .refreshSession();
            if (response.session != null) {
              session = response.session;
              debugPrint(
                '[WebSocket] Token refreshed successfully for connection',
              );
            }
          } catch (refreshError) {
            debugPrint(
              '[WebSocket] Token refresh failed: $refreshError, attempting connection anyway...',
            );
          }
        }
      }

      // Final null check after potential refresh
      if (session == null) {
        throw Exception('Session became null after token refresh');
      }

      final serverUrl = dotenv.env['SERVER_URL']!;
      final wsUrl =
          '${serverUrl.replaceFirst('http', 'ws')}/ws?token=${session.accessToken}';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError:
            false, // Don't cancel stream on error - keep reconnecting
      );

      // Don't set connected status immediately - wait for server confirmation
      // Status will be set to connected when first message is received
    } catch (e) {
      _updateConnectionStatus(ConnectionStatus.error);
      _scheduleReconnect();
      debugPrint('[WebSocket] Connection error (will retry): $e');
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_currentSessionId != null) {
      await leaveSession();
    }

    await _channel?.sink.close();
    _channel = null;
    _currentSessionId = null;
    _updateConnectionStatus(ConnectionStatus.disconnected);
  }

  Future<void> joinSession(String sessionId) async {
    debugPrint('[WebSocket] joinSession called for session: $sessionId');

    // Ensure we're connected first
    if (currentStatus != ConnectionStatus.connected) {
      debugPrint('[WebSocket] Not connected, connecting first...');
      await connect();

      // Wait for connection to be established (max 5 seconds)
      debugPrint('[WebSocket] Waiting for connection to be established...');
      final completer = Completer<void>();
      late StreamSubscription<ConnectionStatus> subscription;

      subscription = connectionStatus.listen((status) {
        debugPrint('[WebSocket] Connection status changed to: $status');
        if (status == ConnectionStatus.connected) {
          subscription.cancel();
          completer.complete();
        } else if (status == ConnectionStatus.error) {
          subscription.cancel();
          completer.completeError('Failed to connect');
        }
      });

      // Wait up to 5 seconds for connection
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          subscription.cancel();
          throw TimeoutException('WebSocket connection timeout');
        },
      );

      debugPrint('[WebSocket] Connection established, ready to join session');
    }

    _currentSessionId = sessionId;
    debugPrint('[WebSocket] Sending join_session message for: $sessionId');
    _sendMessage({'type': 'join_session', 'sessionId': sessionId});
  }

  Future<void> leaveSession() async {
    debugPrint(
      '[WebSocket] leaveSession called for session: $_currentSessionId',
    );
    if (_currentSessionId != null) {
      _sendMessage({'type': 'leave_session', 'sessionId': _currentSessionId});
      _currentSessionId = null;
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && currentStatus == ConnectionStatus.connected) {
      final messageStr = jsonEncode(message);
      _channel!.sink.add(messageStr);
    } else {
      debugPrint(
        '[WebSocket] ⚠️ Cannot send message - not connected. Status: $currentStatus',
      );
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json);

      _messageController.add(message);

      // Set connected status when first message received
      if (currentStatus == ConnectionStatus.connecting) {
        _updateConnectionStatus(ConnectionStatus.connected);
        _startPingTimer();
        debugPrint('WebSocket connected successfully');
      }

      switch (message.type) {
        case WebSocketMessageType.sessionJoined:
          debugPrint('[WebSocket] session_joined: ${message.sessionId}');
          _currentSessionId = message.sessionId;
          break;

        case WebSocketMessageType.sessionLeft:
          debugPrint('[WebSocket] session_left: ${message.sessionId}');
          _currentSessionId = null;
          _sessionController.add(null);
          _participantsController.add([]);
          _leaderboardController.add([]);
          break;

        case WebSocketMessageType.sessionStarted:
          debugPrint('[WebSocket] session_started: ${message.sessionId}');
        case WebSocketMessageType.sessionEnded:
          debugPrint('[WebSocket] session_ended: ${message.sessionId}');
        case WebSocketMessageType.sessionUpdate:
          debugPrint('[WebSocket] session_update: ${message.sessionId}');
        case WebSocketMessageType.sessionState:
          debugPrint('[WebSocket] session_state: ${message.sessionId}');
          if (message.data != null) {
            final session = LiveSession.fromJson(message.data!);
            _sessionController.add(session);

            // Extract and set participants from session state
            if (message.data!['participants'] != null) {
              final participants = (message.data!['participants'] as List)
                  .map((p) => Participant.fromJson(p))
                  .toList();
              _participantsController.add(participants);
              debugPrint(
                '[WebSocket] Session state loaded: ${session.title}, ${participants.length} participants',
              );
            } else {
              debugPrint(
                '[WebSocket] Session updated: ${session.title}, live: ${session.isLive}',
              );
            }
          }
          break;

        case WebSocketMessageType.participantJoined:
          debugPrint('[WebSocket] participant_joined received');
          debugPrint('[WebSocket] Raw participant data: ${message.data}');
          if (message.data != null) {
            try {
              final participant = Participant.fromJson(message.data!);
              debugPrint(
                '[WebSocket] ✅ Parsed participant: ${participant.username} (${participant.userId})',
              );
              final currentParticipants = List<Participant>.from(
                _participantsController.value,
              );

              // Check if participant already exists (deduplicate by userId)
              final existingIndex = currentParticipants.indexWhere(
                (p) => p.userId == participant.userId,
              );

              if (existingIndex == -1) {
                // New participant - add to list
                currentParticipants.add(participant);
                debugPrint(
                  '[WebSocket] ➕ Added new participant: ${participant.username}',
                );
              } else {
                // Duplicate - update existing participant (in case of score/rank changes)
                currentParticipants[existingIndex] = participant;
                debugPrint(
                  '[WebSocket] 🔄 Updated existing participant: ${participant.username}',
                );
              }

              _participantsController.add(currentParticipants);
              debugPrint(
                '[WebSocket] Participants list updated: ${currentParticipants.length} total',
              );
            } catch (e, stack) {
              debugPrint('[WebSocket] ❌ ERROR parsing participant: $e');
              debugPrint('[WebSocket] Stack trace: $stack');
              debugPrint('[WebSocket] Problematic data: ${message.data}');
            }
          } else {
            debugPrint('[WebSocket] ⚠️ participant_joined data is null');
          }
          break;

        case WebSocketMessageType.participantLeft:
          debugPrint('[WebSocket] participant_left received');
        case WebSocketMessageType.participantDisconnected:
          debugPrint('[WebSocket] participant_disconnected received');
          if (message.data != null) {
            final participantId =
                message.data!['participantId'] ?? message.data!['userId'];
            debugPrint('[WebSocket] Removing participant: $participantId');
            final currentParticipants = List<Participant>.from(
              _participantsController.value,
            );
            currentParticipants.removeWhere((p) => p.userId == participantId);
            _participantsController.add(currentParticipants);
            debugPrint(
              '[WebSocket] Participants list updated: ${currentParticipants.length} remaining',
            );
          }
          break;

        case WebSocketMessageType.leaderboardUpdate:
          debugPrint('[WebSocket] leaderboard_update received');
          if (message.data != null) {
            if (message.data!['leaderboard'] != null) {
              final leaderboard = (message.data!['leaderboard'] as List)
                  .map((p) => Participant.fromJson(p))
                  .toList();
              _leaderboardController.add(leaderboard);
              debugPrint(
                '[WebSocket] Leaderboard updated: ${leaderboard.length} participants',
              );
            } else if (message.data!['participant'] != null) {
              // Update single participant in leaderboard
              final updatedParticipant = Participant.fromJson(
                message.data!['participant'],
              );
              final currentLeaderboard = List<Participant>.from(
                _leaderboardController.value,
              );
              final index = currentLeaderboard.indexWhere(
                (p) => p.userId == updatedParticipant.userId,
              );
              if (index != -1) {
                currentLeaderboard[index] = updatedParticipant;
                _leaderboardController.add(currentLeaderboard);
                debugPrint(
                  '[WebSocket] Leaderboard participant updated: ${updatedParticipant.username}',
                );
              }
            }
          }
          break;

        case WebSocketMessageType.ping:
          _sendMessage({'type': 'pong'});
          break;

        case WebSocketMessageType.pong:
          // Pong received, connection is alive
          break;

        case WebSocketMessageType.connected:
          _updateConnectionStatus(ConnectionStatus.connected);
          _startPingTimer();
          debugPrint('[WebSocket] ✅ Connected successfully');
          break;

        case WebSocketMessageType.error:
          // Only log meaningful errors, not "Unknown message type"
          if (message.message != null &&
              message.message != 'Unknown message type') {
            debugPrint('[WebSocket] ❌ Error: ${message.message}');
          }
          break;

        case WebSocketMessageType.notification:
          debugPrint('[WebSocket] 🔔 Notification received');
          break;

        default:
          debugPrint('[WebSocket] ℹ️ Unhandled message type: ${message.type}');
        // Don't treat unhandled messages as errors - just log them
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _handleError(Object error, [StackTrace? stackTrace]) {
    if (_isDisposed) return;

    // Log error but don't crash - just schedule reconnect
    debugPrint('[WebSocket] Error caught: $error');
    if (stackTrace != null) {
      debugPrint('[WebSocket] Stack trace: $stackTrace');
    }

    _updateConnectionStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    if (_isDisposed) return;
    debugPrint('WebSocket disconnected');
    _updateConnectionStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _updateConnectionStatus(ConnectionStatus status) {
    if (!_isDisposed && !_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (currentStatus == ConnectionStatus.connected) {
        _sendMessage({'type': 'ping'});
      } else {
        timer.cancel();
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (currentStatus != ConnectionStatus.connected) {
        _updateConnectionStatus(ConnectionStatus.reconnecting);
        await connect();
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _currentSessionId = null;
    _updateConnectionStatus(ConnectionStatus.disconnected);
    // Don't close stream controllers - this is a singleton that gets reused
  }
}
