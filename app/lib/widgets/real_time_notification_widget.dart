import 'package:flutter/material.dart';
import '../services/real_time_notification_service.dart';

class RealTimeNotificationWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final double? size;
  final bool showBadge;

  const RealTimeNotificationWidget({
    super.key,
    this.onTap,
    this.size,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = RealTimeNotificationService();
    final iconSize = size ?? 24.0;

    return StreamBuilder<int>(
      stream: notificationService.newCount,
      initialData: 0,
      builder: (context, snapshot) {
        final newCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: iconSize,
                color: Colors.white,
              ),
              onPressed: onTap,
            ),
            if (showBadge && newCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      newCount > 9 ? '9+' : newCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
