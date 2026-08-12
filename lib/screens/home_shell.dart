import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_controller.dart';
import 'settings/user_guide_screen.dart';
import 'budget_screen.dart';
import 'record_screen.dart';
import 'review_screen.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';

/// Hosts the 5 tabs and the bottom navigation bar. You can also swipe
/// left/right to move between tabs.
///
/// Tab order (left -> right):
///   0 Budget   1 Record   2 Review/Dashboard   3 Goals   4 Profile
///
/// The other tabs stay locked (no tapping, no swiping) until the user ticks
/// the "I have checked the data" declaration on the Review tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 2});
  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _reviewConfirmed = false;

  // Bumped each time a page becomes visible, so its key changes and the page
  // rebuilds with fresh data from the database (e.g. dashboard, goals).
  final List<int> _nonce = [0, 0, 0, 0, 0];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirmReview() => setState(() => _reviewConfirmed = true);

  void _goTo(int i) {
    if (!_reviewConfirmed && i != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Finish your daily review first — tick the box to continue.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
    setState(() => _index = i);
  }

  Widget _pageAt(int i) {
    final key = ValueKey('p$i-${_nonce[i]}');
    switch (i) {
      case 0:
        return BudgetScreen(key: key);
      case 1:
        return RecordScreen(key: key);
      case 2:
        return ReviewScreen(
          key: key,
          confirmed: _reviewConfirmed,
          onConfirm: _onConfirmReview,
        );
      case 3:
        return GoalsScreen(key: key);
      default:
        return ProfileScreen(key: key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Offline banner — only visible when there's no connection.
            ValueListenableBuilder<bool>(
              valueListenable: ConnectivityController.instance.online,
              builder: (context, online, _) {
                if (online) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  color: Colors.orange.shade800,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Offline — your changes will sync when you reconnect.",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: 5,
                    // Swiping is disabled until the review is confirmed.
                    physics: _reviewConfirmed
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) {
                      setState(() {
                        _index = i;
                        // Recreate the page we landed on so its data is fresh.
                        _nonce[i]++;
                      });
                    },
                    itemBuilder: (context, i) => _pageAt(i),
                  ),
                  // "i" User Guide button, top-right of every page.
                  Positioned(
                    top: 6,
                    right: 10,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'User Guide',
                        icon: const Icon(Icons.info_outline),
                        color: AppColors.primary,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserGuideScreen()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _NavBar(
        index: _index,
        locked: !_reviewConfirmed,
        onTap: _goTo,
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.locked,
    required this.onTap,
  });

  final int index;
  final bool locked;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.calculate_outlined, 'Budget'),
    (Icons.download_rounded, 'Record'),
    (Icons.dashboard_rounded, 'Review'),
    (Icons.track_changes_rounded, 'Goals'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final selected = i == index;
          final disabled = locked && i != 2;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _items[i].$1,
                color: disabled ? Colors.white38 : Colors.white,
                size: 26,
              ),
            ),
          );
        }),
      ),
    );
  }
}
