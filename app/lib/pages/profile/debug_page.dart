import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Map<String, dynamic> _sessionInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
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

  Widget _buildInfoItem(String key, dynamic value) {
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
        color: Theme.of(context).colorScheme.surface,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Debug Info"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadSessionInfo),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Debug Mode - Sensitive Information",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                ..._sessionInfo.entries.map((entry) {
                  return _buildInfoItem(entry.key, entry.value);
                }),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final jsonString = const JsonEncoder.withIndent(
                      "  ",
                    ).convert(_sessionInfo);
                    _copyToClipboard(jsonString);
                  },
                  icon: Icon(Icons.copy_all),
                  label: Text("Copy All Info"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
