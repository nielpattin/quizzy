import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

void showTimeLimitPicker(
  BuildContext context,
  String currentTimeLimit,
  Function(String) onTimeSelected,
) {
  final timeLimits = [
    "5 sec",
    "10 sec",
    "20 sec",
    "30 sec",
    "45 sec",
    "60 sec",
    "90 sec",
    "120 sec",
  ];

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF1A2433),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Time Limit",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: timeLimits.map((time) {
                  final isSelected = time == currentTimeLimit;
                  return GestureDetector(
                    onTap: () {
                      onTimeSelected(time);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 80,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.transparent, width: 0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showPointsPicker(
  BuildContext context,
  String currentPoints,
  Function(String) onPointsSelected,
) {
  final pointsOptions = [
    "50 coki",
    "100 coki",
    "200 coki",
    "250 coki",
    "500 coki",
    "750 coki",
    "1000 coki",
    "2000 coki",
  ];

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF1A2433),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Points",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: pointsOptions.map((points) {
                  final isSelected = points == currentPoints;
                  return GestureDetector(
                    onTap: () {
                      onPointsSelected(points);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 110,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.transparent, width: 0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          points,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showQuestionTypePicker(
  BuildContext context,
  String currentType,
  Function(String) onTypeSelected,
) {
  final questionTypes = [
    {
      "type": "single_choice",
      "label": "Single Choice",
      "svgPath": "images/Icons/SingleAnswer.svg",
    },
    {
      "type": "true_false",
      "label": "True or false",
      "svgPath": "images/Icons/TrueOrFalse.svg",
    },
    {
      "type": "reorder",
      "label": "Reorder",
      "svgPath": "images/Icons/Reorder.svg",
    },
    {
      "type": "type_answer",
      "label": "Type Answer",
      "svgPath": "images/Icons/TypeAnswer.svg",
    },
    {
      "type": "checkbox",
      "label": "Checkbox",
      "svgPath": "images/Icons/CheckBox.svg",
    },
    {
      "type": "drop_pin",
      "label": "Drop Pin",
      "svgPath": "images/Icons/DropPin.svg",
    },
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A2433),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Question Type",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 170 / 97,
              ),
              itemCount: questionTypes.length,
              itemBuilder: (context, index) {
                final type = questionTypes[index];
                final isSelected = type["type"] == currentType;
                return GestureDetector(
                  onTap: () {
                    onTypeSelected(type["type"] as String);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF35383F),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          type["svgPath"] as String,
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type["label"] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
