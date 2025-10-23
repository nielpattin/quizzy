import "package:flutter/material.dart";

class SettingsToolbar extends StatelessWidget {
  final String timeLimit;
  final String points;
  final String questionType;
  final VoidCallback onTimeTap;
  final VoidCallback onPointsTap;
  final VoidCallback onTypeTap;

  const SettingsToolbar({
    required this.timeLimit,
    required this.points,
    required this.questionType,
    required this.onTimeTap,
    required this.onPointsTap,
    required this.onTypeTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToolbarButton(
              icon: Icons.timer_rounded,
              label: timeLimit,
              onTap: onTimeTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ToolbarButton(
              icon: Icons.stars_rounded,
              label: points,
              onTap: onPointsTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ToolbarButton(
              icon: Icons.list_alt_rounded,
              label: _getTypeLabel(questionType),
              onTap: onTypeTap,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case "multiple_choice":
        return "Quiz";
      case "true_false":
        return "True/False";
      case "reorder":
        return "Reorder";
      case "type_answer":
        return "Type";
      case "checkbox":
        return "Checkbox";
      case "drop_pin":
        return "Drop Pin";
      default:
        return "Quiz";
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
