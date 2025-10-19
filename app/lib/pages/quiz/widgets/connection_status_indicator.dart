import 'package:flutter/material.dart';
import '../../../services/websocket_service.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final double size;

  const ConnectionStatusIndicator({super.key, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final websocketService = WebSocketService();

    return StreamBuilder<ConnectionStatus>(
      stream: websocketService.connectionStatus,
      initialData: ConnectionStatus.disconnected,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.disconnected;

        Color color;
        String tooltip;

        switch (status) {
          case ConnectionStatus.connected:
            color = Colors.green;
            tooltip = 'Connected';
            break;
          case ConnectionStatus.connecting:
          case ConnectionStatus.reconnecting:
            color = Colors.orange;
            tooltip = 'Connecting...';
            break;
          case ConnectionStatus.disconnected:
            color = Colors.grey;
            tooltip = 'Disconnected';
            break;
          case ConnectionStatus.error:
            color = Colors.red;
            tooltip = 'Connection Error';
            break;
        }

        return Tooltip(
          message: tooltip,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        );
      },
    );
  }
}
