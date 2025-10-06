import "package:flutter/material.dart";
import "section_header.dart";

class SortButton extends StatelessWidget {
  final SortOption option;
  final VoidCallback? onTap;
  const SortButton({super.key, required this.option, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.6),
            width: 1.2,
          ),
          color: scheme.primary.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, size: 18, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              option.label,
              style: TextStyle(
                color: scheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SortOptionTile extends StatelessWidget {
  final SortOption option;
  final bool selected;
  final VoidCallback onTap;
  const SortOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        option.icon,
        color: selected
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        option.label,
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check, color: scheme.primary, size: 20)
          : null,
    );
  }
}
