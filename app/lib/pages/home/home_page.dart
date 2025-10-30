import "package:flutter/material.dart";
import "quizzy_tab.dart";
import "feedy_tab.dart";
import "widgets/tab_button.dart";
import "../../widgets/app_header.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: "Quizzy"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  TabButton(
                    label: "Quizzy",
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  const SizedBox(width: 12),
                  TabButton(
                    label: "Feedy",
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: const [QuizzyTab(), FeedyTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
