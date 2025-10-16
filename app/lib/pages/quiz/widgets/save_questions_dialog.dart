import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

void showSaveQuestionsDialog({
  required BuildContext context,
  required VoidCallback onAddMore,
  required VoidCallback onSave,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Save Questions"),
      content: const Text("Do you want to add more questions or save now?"),
      actions: [
        TextButton(
          onPressed: () {
            context.pop();
            onAddMore();
          },
          child: const Text("Add More"),
        ),
        ElevatedButton(
          onPressed: () {
            context.pop();
            onSave();
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
