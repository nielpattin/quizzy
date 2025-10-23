import "package:flutter/material.dart";

class CleanAnswerList extends StatefulWidget {
  final String questionType;
  final int? correctAnswerIndex;
  final List<TextEditingController> answerControllers;
  final int answerCount;
  final Function(int) onMarkCorrect;
  final VoidCallback? onAddAnswer;
  final Function(int)? onRemoveAnswer;

  const CleanAnswerList({
    required this.questionType,
    required this.correctAnswerIndex,
    required this.answerControllers,
    required this.answerCount,
    required this.onMarkCorrect,
    this.onAddAnswer,
    this.onRemoveAnswer,
    super.key,
  });

  @override
  State<CleanAnswerList> createState() => _CleanAnswerListState();
}

class _CleanAnswerListState extends State<CleanAnswerList> {
  int? _expandedIndex;

  void _toggleExpanded(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  void _closeExpanded() {
    if (_expandedIndex != null) {
      setState(() {
        _expandedIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questionType == "true_false") {
      return Column(
        children: [
          _buildTrueFalseOption(context, 0, "True"),
          const SizedBox(height: 12),
          _buildTrueFalseOption(context, 1, "False"),
        ],
      );
    }

    return GestureDetector(
      onTap: _closeExpanded,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          ...List.generate(
            widget.answerCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAnswerOption(context, index),
            ),
          ),
          if (widget.answerCount < 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: widget.onAddAnswer,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text("Add Answer (${widget.answerCount}/5)"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(BuildContext context, int index) {
    final isCorrect = widget.correctAnswerIndex == index;
    final canRemove = widget.answerCount > 2;
    final isExpanded = _expandedIndex == index;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect
                    ? const Color(0xFF10B981)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                width: isCorrect ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: widget.answerControllers[index],
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: "Type answer",
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                ignoring: !isExpanded,
                child: AnimatedOpacity(
                  opacity: isExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isExpanded ? 32 : 0,
                    margin: EdgeInsets.only(right: isExpanded ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        widget.onMarkCorrect(index);
                        _closeExpanded();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (canRemove)
                IgnorePointer(
                  ignoring: !isExpanded,
                  child: AnimatedOpacity(
                    opacity: isExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isExpanded ? 32 : 0,
                      margin: EdgeInsets.only(right: isExpanded ? 8 : 0),
                      child: GestureDetector(
                        onTap: () {
                          widget.onRemoveAnswer?.call(index);
                          _closeExpanded();
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => _toggleExpanded(index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isExpanded ? Icons.circle : Icons.circle_outlined,
                    color: isExpanded
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOption(BuildContext context, int index, String label) {
    final isCorrect = widget.correctAnswerIndex == index;

    return GestureDetector(
      onTap: () => widget.onMarkCorrect(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect
                ? const Color(0xFF10B981)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.2),
            width: isCorrect ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: index == 0
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFFEF4444).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                index == 0 ? Icons.check_rounded : Icons.close_rounded,
                color: index == 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xFF10B981)
                    : Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: isCorrect
                    ? null
                    : Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                        width: 2,
                      ),
              ),
              child: Icon(
                isCorrect ? Icons.check_rounded : Icons.circle_outlined,
                color: isCorrect
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
