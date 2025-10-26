import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "dart:async";
import "../../services/websocket_service.dart";

/// Reusable debug panel widget that can be used in a page or modal
class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

/// Page wrapper for the debug panel (accessible via /debug route)
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Debug Info"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: const DebugPanel(),
    );
  }
}

class _DebugPanelState extends State<DebugPanel> {
  Map<String, dynamic> _sessionInfo = {};
  Map<String, dynamic> _websocketInfo = {};
  bool _isLoading = true;
  StreamSubscription? _wsSubscription;
  DateTime? _connectedAt;
  DateTime? _lastMessageAt;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
    _loadWebSocketInfo();

    _wsSubscription = WebSocketService().connectionStatus.listen((_) {
      if (mounted) {
        _loadWebSocketInfo();
      }
    });

    WebSocketService().messages.listen((_) {
      if (mounted) {
        setState(() {
          _lastMessageAt = DateTime.now();
        });
      }
    });

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _websocketInfo.isNotEmpty) {
        setState(() {});
      }
    });
  }

  Future<void> _loadSessionInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session != null && user != null) {
        final expiresAt = session.expiresAt;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeUntilExpiry = expiresAt != null ? expiresAt - now : null;

        setState(() {
          _sessionInfo = {
            "Session Status": "Active",
            "User ID": user.id,
            "Email": user.email ?? "N/A",
            "Email Verified": user.emailConfirmedAt != null ? "Yes" : "No",
            "Phone": user.phone ?? "N/A",
            "Created At": user.createdAt,
            "Last Sign In": user.lastSignInAt ?? "N/A",
            "Access Token": "${session.accessToken.substring(0, 50)}...",
            "Token Type": session.tokenType,
            "Expires At": expiresAt != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    expiresAt * 1000,
                  ).toString()
                : "N/A",
            "Time Until Expiry": timeUntilExpiry != null
                ? "${(timeUntilExpiry / 60).toStringAsFixed(2)} minutes"
                : "N/A",
            "User Metadata": user.userMetadata ?? {},
            "App Metadata": user.appMetadata,
            "Identities":
                user.identities
                    ?.map(
                      (i) => {
                        "provider": i.provider,
                        "id": i.id,
                        "created_at": i.createdAt,
                      },
                    )
                    .toList() ??
                [],
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _sessionInfo = {"Session Status": "No Active Session"};
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _sessionInfo = {"Error": e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWebSocketInfo() async {
    try {
      final wsService = WebSocketService();
      final status = wsService.currentStatus;
      final user = Supabase.instance.client.auth.currentUser;

      if (status == ConnectionStatus.connected && _connectedAt == null) {
        _connectedAt = DateTime.now();
      } else if (status != ConnectionStatus.connected) {
        _connectedAt = null;
      }

      String statusEmoji;
      Color statusColor;
      switch (status) {
        case ConnectionStatus.connected:
          statusEmoji = "🟢";
          statusColor = Colors.green;
          break;
        case ConnectionStatus.connecting:
        case ConnectionStatus.reconnecting:
          statusEmoji = "🟡";
          statusColor = Colors.orange;
          break;
        case ConnectionStatus.error:
          statusEmoji = "⚫";
          statusColor = Colors.grey;
          break;
        case ConnectionStatus.disconnected:
        default:
          statusEmoji = "🔴";
          statusColor = Colors.red;
      }

      String connectedDuration = "N/A";
      if (_connectedAt != null && status == ConnectionStatus.connected) {
        final duration = DateTime.now().difference(_connectedAt!);
        if (duration.inHours > 0) {
          connectedDuration =
              "${duration.inHours}h ${duration.inMinutes % 60}m";
        } else if (duration.inMinutes > 0) {
          connectedDuration =
              "${duration.inMinutes}m ${duration.inSeconds % 60}s";
        } else {
          connectedDuration = "${duration.inSeconds}s";
        }
      }

      String lastMessage = "Never";
      if (_lastMessageAt != null) {
        final since = DateTime.now().difference(_lastMessageAt!);
        if (since.inMinutes > 0) {
          lastMessage = "${since.inMinutes}m ${since.inSeconds % 60}s ago";
        } else {
          lastMessage = "${since.inSeconds}s ago";
        }
      }

      setState(() {
        _websocketInfo = {
          "Status": status.toString().split('.').last,
          "Status Emoji": statusEmoji,
          "Status Color": statusColor,
          "Is Connected": status == ConnectionStatus.connected,
          "User ID": user?.id ?? "N/A",
          "Connected Duration": connectedDuration,
          "Last Message": lastMessage,
        };
      });
    } catch (e) {
      setState(() {
        _websocketInfo = {"Error": e.toString()};
      });
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoItem(String key, dynamic value, {Color? backgroundColor}) {
    String displayValue;
    if (value is Map || value is List) {
      displayValue = const JsonEncoder.withIndent("  ").convert(value);
    } else {
      displayValue = value.toString();
    }

    final bool isLongValue =
        displayValue.length > 50 || displayValue.contains("\n");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 18),
                onPressed: () => _copyToClipboard(displayValue),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: isLongValue
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      displayValue,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "monospace",
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  )
                : SelectableText(
                    displayValue,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSocketSection() {
    if (_websocketInfo.isEmpty) {
      return SizedBox.shrink();
    }

    final isConnected = _websocketInfo["Is Connected"] ?? false;
    final statusEmoji = _websocketInfo["Status Emoji"] ?? "⚫";
    final statusColor = _websocketInfo["Status Color"] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(statusEmoji, style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WebSocket Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      isConnected ? "Connected to backend" : "Not connected",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isConnected ? Icons.check_circle : Icons.error,
                color: statusColor,
                size: 32,
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 8),
          ..._websocketInfo.entries
              .where(
                (e) => ![
                  "Status Emoji",
                  "Status Color",
                  "Is Connected",
                ].contains(e.key),
              )
              .map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          entry.value.toString(),
                          style: TextStyle(
                            fontFamily: entry.key == "User ID"
                                ? "monospace"
                                : null,
                            fontSize: entry.key == "User ID" ? 11 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Debug Mode - Sensitive Information",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _loadSessionInfo();
                        _loadWebSocketInfo();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildWebSocketSection(),
              ..._sessionInfo.entries.map((entry) {
                return _buildInfoItem(entry.key, entry.value);
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final jsonString = const JsonEncoder.withIndent(
                    "  ",
                  ).convert(_sessionInfo);
                  _copyToClipboard(jsonString);
                },
                icon: const Icon(Icons.copy_all),
                label: const Text("Copy All Info"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
  }
}
