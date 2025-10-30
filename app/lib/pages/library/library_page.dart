import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "widgets/main_segments.dart";
import "widgets/sort_button.dart";
import "services/library_service.dart" show SortOption;
import "../../widgets/bottom_nav.dart";
import "../../widgets/app_header.dart";
import "tabs/created_tab.dart";
import "tabs/favorites_tab.dart";
import "tabs/game_tab.dart";

class LibraryPage extends StatefulWidget {
  final bool showBottomNav;
  final int initialCategoryIndex;
  final int initialGameTabIndex;

  const LibraryPage({
    super.key,
    this.showBottomNav = true,
    this.initialCategoryIndex = 0,
    this.initialGameTabIndex = 0,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late int _selectedCategoryIndex;
  int _createdTabIndex = 0;
  late int _gameTabIndex;
  SortOption _sort = SortOption.newest;
  VoidCallback? _refreshCollectionsCallback;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex;
    _gameTabIndex = widget.initialGameTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: "Library"),
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
                  if (_selectedCategoryIndex == 1) return _buildFavoritesTab();
                  return _buildGameTab();
                }(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _shouldShowFAB()
          ? FloatingActionButton(
              onPressed: _handleCreateCollection,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: widget.showBottomNav
          ? const BottomNav(selectedIndex: 1)
          : null,
    );
  }

  bool _shouldShowFAB() {
    return _selectedCategoryIndex == 0 && _createdTabIndex == 1;
  }

  Future<void> _handleCreateCollection() async {
    final result = await context.push("/library/create-collection");
    if (result == true && mounted && _refreshCollectionsCallback != null) {
      _refreshCollectionsCallback!();
    }
  }

  Widget _buildCreatedTab() {
    return CreatedTab(
      key: const ValueKey("created_tab"),
      selectedSubTab: _createdTabIndex,
      onSubTabChanged: (i) => setState(() => _createdTabIndex = i),
      sort: _sort,
      onSortTap: _showSortSheet,
      onRefreshCollectionsRegister: (callback) {
        _refreshCollectionsCallback = callback;
      },
    );
  }

  Widget _buildFavoritesTab() {
    return FavoritesTab(
      key: const ValueKey("favorites_tab"),
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
