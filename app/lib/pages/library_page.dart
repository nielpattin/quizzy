import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "library/widgets/main_segments.dart";
import "library/widgets/section_header.dart";
import "library/widgets/sort_button.dart";
import "library/widgets/bottom_nav.dart";
import "library/tabs/created_tab.dart";
import "library/tabs/saved_tab.dart";
import "library/tabs/game_tab.dart";

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int _selectedCategoryIndex = 0;
  int _createdTabIndex = 0;
  int _gameTabIndex = 0;
  SortOption _sort = SortOption.newest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          MainSegments(
            selected: _selectedCategoryIndex,
            onChanged: (i) => setState(() => _selectedCategoryIndex = i),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: () {
                if (_selectedCategoryIndex == 0) return _buildCreatedTab();
                if (_selectedCategoryIndex == 1) return _buildSavedTab();
                return _buildGameTab();
              }(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(selectedIndex: 1),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.quiz, color: Colors.white, size: 24),
        ),
      ),
      title: const Text(
        "Library",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.push("/search"),
        ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.push("/notification"),
        ),
      ],
    );
  }

  Widget _buildCreatedTab() {
    return CreatedTab(
      key: const ValueKey("created_tab"),
      selectedSubTab: _createdTabIndex,
      onSubTabChanged: (i) => setState(() => _createdTabIndex = i),
      sort: _sort,
      onSortTap: _showSortSheet,
    );
  }

  Widget _buildSavedTab() {
    return SavedTab(
      key: const ValueKey("saved_tab"),
      sort: _sort,
      onSortTap: _showSortSheet,
    );
  }

  Widget _buildGameTab() {
    return GameTab(
      key: const ValueKey("game_tab"),
      selectedSubTab: _gameTabIndex,
      onSubTabChanged: (i) => setState(() => _gameTabIndex = i),
      sort: _sort,
      onSortTap: _showSortSheet,
    );
  }

  void _showSortSheet() async {
    final selected = await showModalBottomSheet<SortOption>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sort by",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              for (final opt in SortOption.values)
                SortOptionTile(
                  option: opt,
                  selected: opt == _sort,
                  onTap: () => Navigator.of(ctx).pop(opt),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != _sort) {
      setState(() => _sort = selected);
    }
  }
}
