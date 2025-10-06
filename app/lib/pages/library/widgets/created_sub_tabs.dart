import "package:flutter/material.dart";

class CreatedSubTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const CreatedSubTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _MiniTab(
              label: "Quizzes",
              selected: selected == 0,
              onTap: () => onChanged(0),
              scheme: scheme,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniTab(
              label: "Collections",
              selected: selected == 1,
              onTap: () => onChanged(1),
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  const _MiniTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? scheme.primary : Colors.transparent;
    final fg = selected ? Colors.white : scheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: selected ? null : Border.all(color: scheme.primary, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
