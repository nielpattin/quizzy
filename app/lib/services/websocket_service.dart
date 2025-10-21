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
      default:
        messageType = WebSocketMessageType.error;
    }

    return WebSocketMessage(
      type: messageType,
      sessionId: json['sessionId'],
      data:
          json['data'] ??
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
    return Participant(
      id: json['id'],
      userId: json['userId'] ?? json['user']['id'],
      username: json['username'] ?? json['user']['username'],
      fullName: json['fullName'] ?? json['user']['fullName'],
      profilePictureUrl:
          json['profilePictureUrl'] ?? json['user']['profilePictureUrl'],
      score: json['score'] ?? 0,
      rank: json['rank'],
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }
}

// Session model
class LiveSession {
  final String id;
  final String title;
  final bool isLive;
  final int joinedCount;
  final String? code;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final List<Participant> participants;

  LiveSession({
    required this.id,
    required this.title,
    required this.isLive,
    required this.joinedCount,
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
      joinedCount: json['joinedCount'] ?? 0,
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
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session');
      }

      final serverUrl = dotenv.env['SERVER_URL']!;
      final wsUrl =
          '${serverUrl.replaceFirst('http', 'ws')}/ws?token=${session.accessToken}';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _startPingTimer();
      _updateConnectionStatus(ConnectionStatus.connected);
    } catch (e) {
      _updateConnectionStatus(ConnectionStatus.error);
      _scheduleReconnect();
      debugPrint('WebSocket connection error: $e');
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
    if (currentStatus != ConnectionStatus.connected) {
      await connect();
    }

    _currentSessionId = sessionId;
    _sendMessage({'type': 'join_session', 'sessionId': sessionId});
  }

  Future<void> leaveSession() async {
    if (_currentSessionId != null) {
      _sendMessage({'type': 'leave_session', 'sessionId': _currentSessionId});
      _currentSessionId = null;
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && currentStatus == ConnectionStatus.connected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json);

      _messageController.add(message);

      switch (message.type) {
        case WebSocketMessageType.sessionJoined:
          _currentSessionId = message.sessionId;
          break;

        case WebSocketMessageType.sessionLeft:
          _currentSessionId = null;
          _sessionController.add(null);
          _participantsController.add([]);
          _leaderboardController.add([]);
          break;

        case WebSocketMessageType.sessionStarted:
        case WebSocketMessageType.sessionEnded:
        case WebSocketMessageType.sessionUpdate:
        case WebSocketMessageType.sessionState:
          if (message.data != null) {
            final session = LiveSession.fromJson(message.data!);
            _sessionController.add(session);
          }
          break;

        case WebSocketMessageType.participantJoined:
          if (message.data != null) {
            final participant = Participant.fromJson(message.data!);
            final currentParticipants = List<Participant>.from(
              _participantsController.value,
            );
            currentParticipants.add(participant);
            _participantsController.add(currentParticipants);
          }
          break;

        case WebSocketMessageType.participantLeft:
        case WebSocketMessageType.participantDisconnected:
          if (message.data != null) {
            final participantId =
                message.data!['participantId'] ?? message.data!['userId'];
            final currentParticipants = List<Participant>.from(
              _participantsController.value,
            );
            currentParticipants.removeWhere((p) => p.userId == participantId);
            _participantsController.add(currentParticipants);
          }
          break;

        case WebSocketMessageType.leaderboardUpdate:
          if (message.data != null) {
            if (message.data!['leaderboard'] != null) {
              final leaderboard = (message.data!['leaderboard'] as List)
                  .map((p) => Participant.fromJson(p))
                  .toList();
              _leaderboardController.add(leaderboard);
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

        case WebSocketMessageType.error:
          debugPrint('WebSocket error: ${message.message}');
          break;

        default:
          debugPrint('Unknown WebSocket message type: ${message.type}');
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _handleError(Object error) {
    if (_isDisposed) return;
    debugPrint('WebSocket error: $error');
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
