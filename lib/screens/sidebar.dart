import 'package:flutter/material.dart';
import 'event.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  SidebarState createState() => SidebarState();
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget page;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.page,
  });
}

class SidebarState extends State<Sidebar>
    with SingleTickerProviderStateMixin {

  int _selectedIndex = 0;
  late final AnimationController _ctrl;
  late final Animation<double> _widthAnim;

  static const double _minWidth = 72;
  static const double _maxWidth = 240;
  static const double _labelThreshold = 120;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // if (sessionController.currentUser.value == null) {
      //   Get.offAllNamed(AppRoutes.admin_login);
      // }
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _widthAnim = Tween<double>(begin: _minWidth, end: _maxWidth).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _expand() => _ctrl.forward();
  void _collapse() => _ctrl.reverse();

  void _onItemTap(int idx) {
    setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    // build the list of nav items based on isAdmin
    final navItems = <_NavItem>[
      const _NavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        page: EventPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Row(
        children: [
          MouseRegion(
            onEnter: (_) => _expand(),
            onExit: (_) => _collapse(),
            child: AnimatedBuilder(
              animation: _widthAnim,
              builder: (context, child) {
                final width = _widthAnim.value;
                final expanded = width > _labelThreshold;

                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "App",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: navItems.length,
                            itemBuilder: (context, idx) {
                              final item = navItems[idx];
                              final selected = idx == _selectedIndex;
                              return Material(
                                color: selected
                                    ? Colors.blue.shade50
                                    : Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onItemTap(idx),
                                  child: Padding(
                                    padding: expanded
                                        ? const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16)
                                        : const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: expanded
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          item.icon,
                                          color: selected
                                              ? Colors.teal
                                              : Colors.grey[700],
                                        ),
                                        if (expanded) ...[
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              style: TextStyle(
                                                color: selected
                                                    ? Colors.teal
                                                    : Colors.grey[800],
                                                fontWeight: selected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:(){},
                            child: Padding(
                              padding: width > _labelThreshold
                                  ? const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16)
                                  : const EdgeInsets.symmetric(
                                  vertical: 12),
                              child: Row(
                                mainAxisAlignment: width > _labelThreshold
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                  ),
                                  if (expanded) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        // collapse/expand chevron
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _ctrl.isCompleted
                                  ? Icons.chevron_left
                                  : Icons.chevron_right,
                              key: ValueKey<bool>(_ctrl.isCompleted),
                              color: Colors.grey[700],
                            ),
                          ),
                          onPressed:
                          _ctrl.isCompleted ? _collapse : _expand,
                        ),
                        // logout button
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(100, 100, 111, 0.2),
                    offset: const Offset(0, 7),
                    blurRadius: 29,
                    spreadRadius: 0,
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
              ),
              child: IndexedStack(
                index: _selectedIndex,
                children: navItems.map((e) => e.page).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}