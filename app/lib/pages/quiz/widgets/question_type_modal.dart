import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "question_type_card.dart";

void showQuestionTypeModal({
  required BuildContext context,
  required Function(String type) onTypeSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A2433),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
    ),
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 135,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF464646),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Add Question",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 170 / 97,
                children: [
                  QuestionTypeCard(
                    svgPath: "images/Icons/SingleAnswer.svg",
                    label: "Single Choice",
                    onTap: () {
                      context.pop();
                      onTypeSelected("single_choice");
                    },
                  ),
                  QuestionTypeCard(
                    svgPath: "images/Icons/TrueOrFalse.svg",
                    label: "True or false",
                    onTap: () {
                      context.pop();
                      onTypeSelected("true_false");
                    },
                  ),
                  QuestionTypeCard(
                    svgPath: "images/Icons/Reorder.svg",
                    label: "Reorder",
                    onTap: () {
                      context.pop();
                      onTypeSelected("reorder");
                    },
                  ),
                  QuestionTypeCard(
                    svgPath: "images/Icons/TypeAnswer.svg",
                    label: "Type Answer",
                    onTap: () {
                      context.pop();
                      onTypeSelected("type_answer");
                    },
                  ),
                  QuestionTypeCard(
                    svgPath: "images/Icons/CheckBox.svg",
                    label: "Checkbox",
                    onTap: () {
                      context.pop();
                      onTypeSelected("checkbox");
                    },
                  ),
                  QuestionTypeCard(
                    svgPath: "images/Icons/DropPin.svg",
                    label: "Drop Pin",
                    onTap: () {
                      context.pop();
                      onTypeSelected("drop_pin");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
