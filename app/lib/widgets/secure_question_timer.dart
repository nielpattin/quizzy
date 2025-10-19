import 'dart:async';
import 'package:flutter/material.dart';

class SecureQuestionTimer extends StatefulWidget {
  final DateTime serverDeadline;
  final VoidCallback onTimeExpired;

  const SecureQuestionTimer({
    super.key,
    required this.serverDeadline,
    required this.onTimeExpired,
  });

  @override
  State<SecureQuestionTimer> createState() => _SecureQuestionTimerState();
}

class _SecureQuestionTimerState extends State<SecureQuestionTimer> {
  late Timer _timer;
  int _timeLeft = 30;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _startDisplayTimer();
  }

  void _startDisplayTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now().toUtc();
      final deadline = widget.serverDeadline.toUtc();
      final remaining = deadline.difference(now);

      if (remaining.isNegative) {
        timer.cancel();
        if (!_isExpired) {
          _isExpired = true;
          widget.onTimeExpired();
        }
      } else {
        setState(() {
          _timeLeft = remaining.inSeconds;
          _isExpired = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTimeColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTimeBorderColor(), width: 2),
        boxShadow: [
          BoxShadow(
            color: _getTimeColor().withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getTimeIcon(), color: _getTimeTextColor(), size: 20),
              const SizedBox(width: 8),
              Text(
                'Time Remaining',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _getTimeTextColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getTimeBorderColor().withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_timeLeft',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _getTimeTextColor(),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'sec',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: _getTimeTextColor().withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_isExpired) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'TIME EXPIRED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTimeColor() {
    if (_isExpired) return Colors.red[50]!;
    if (_timeLeft <= 5) return Colors.orange[50]!;
    if (_timeLeft <= 10) return Colors.yellow[50]!;
    return Colors.blue[50]!;
  }

  Color _getTimeTextColor() {
    if (_isExpired) return Colors.red;
    if (_timeLeft <= 5) return Colors.orange;
    if (_timeLeft <= 10) return Colors.yellow[800]!;
    return Colors.blue;
  }

  Color _getTimeBorderColor() {
    if (_isExpired) return Colors.red;
    if (_timeLeft <= 5) return Colors.orange;
    if (_timeLeft <= 10) return Colors.yellow[700]!;
    return Colors.blue;
  }

  IconData _getTimeIcon() {
    if (_isExpired) return Icons.timer_off;
    if (_timeLeft <= 5) return Icons.timer;
    if (_timeLeft <= 10) return Icons.hourglass_bottom;
    return Icons.access_time;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
