import 'package:flutter/material.dart';
import 'dart:convert';
import '../db_helper.dart';
import 'index.dart';
import '../theme/theme_notifier.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DashboardPage({super.key, required this.userData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late bool _isDoctor;
  late List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _isDoctor = widget.userData['role'] == 'Doctor';
    _navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      if (_isDoctor) _NavItem(icon: Icons.add_circle_rounded, label: 'Analysis'),
      if (_isDoctor) _NavItem(icon: Icons.search_rounded, label: 'Patient Search'),
      _NavItem(icon: Icons.history_rounded, label: 'History'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];
    themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  List<Widget> get _pages => [
        HomePage(userData: widget.userData),
        if (_isDoctor) ApplyXrayPage(userData: widget.userData),
        if (_isDoctor) PatientSearchPage(userData: widget.userData),
        HistoryPage(userData: widget.userData),
        ProfilePage(userData: widget.userData),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF8FAFF),
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            isDark: isDark,
            selectedIndex: _selectedIndex,
            navItems: _navItems,
            userData: widget.userData,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                _TopBar(
                  isDark: isDark,
                  title: _navItems[_selectedIndex].label,
                  userData: widget.userData,
                ),

                // Page content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _pages[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Sidebar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _Sidebar extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final List<_NavItem> navItems;
  final Map<String, dynamic> userData;
  final void Function(int) onTap;

  const _Sidebar({
    required this.isDark,
    required this.selectedIndex,
    required this.navItems,
    required this.userData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Animated Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: Row(
              children: [
                const _AnimatedSidebarLogo(),
                const SizedBox(width: 10),
                Text(
                  'XRBone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: List.generate(navItems.length, (i) {
                  final item = navItems[i];
                  final isSelected = i == selectedIndex;
                  return _SidebarItem(
                    icon: item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
          ),

          // Theme + user footer
          Divider(height: 1, color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Theme toggle
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => themeNotifier.toggleTheme(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2538) : const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isDark ? 'Light Mode' : 'Dark Mode',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF2563EB).withOpacity(0.12)
                : _hovering
                    ? (widget.isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.04))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: active
                    ? const Color(0xFF2563EB)
                    : widget.isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active
                      ? const Color(0xFF2563EB)
                      : widget.isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Top Bar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _TopBar extends StatelessWidget {
  final bool isDark;
  final String title;
  final Map<String, dynamic> userData;

  const _TopBar({required this.isDark, required this.title, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2538) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF2D3748) : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  userData['role'] == 'Doctor' ? Icons.medical_services_rounded : Icons.person_rounded,
                  size: 14,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Text(
                  userData['role'] ?? 'Patient',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Avatar chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2538) : const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      (userData['username'] as String? ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  userData['username'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Nav Item model Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Home Page Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, int> _stats = {};
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final id = widget.userData['id'] as int;
    final isDoctor = widget.userData['role'] == 'Doctor';
    final result = isDoctor
        ? await DatabaseHelper.instance.fetchDoctorStats(id)
        : await DatabaseHelper.instance.fetchPatientStats(id);
    if (mounted) setState(() { _stats = result; _statsLoaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDoctor = widget.userData['role'] == 'Doctor';
    final userData = widget.userData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero greeting card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good day, ${userData['username']}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isDoctor
                            ? 'You can upload and analyze X-ray images using the Analysis tab.'
                            : 'View your X-Ray reports and medical history in the History tab.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDoctor ? Icons.medical_services_rounded : Icons.person_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Stats row
          _StatsRow(
            isDoctor: isDoctor,
            isDark: isDark,
            stats: _stats,
            loaded: _statsLoaded,
          ),
          const SizedBox(height: 32),

          // RSNA News section
          _RsnaNewsSection(isDark: isDark),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final bool isDoctor;
  final bool isDark;
  final Map<String, int> stats;
  final bool loaded;
  const _StatsRow({
    required this.isDoctor,
    required this.isDark,
    required this.stats,
    required this.loaded,
  });

  String _val(String key) {
    if (!loaded) return 'Ã¢â‚¬Â¦';
    return (stats[key] ?? 0).toString();
  }

  @override
  Widget build(BuildContext context) {
    final items = isDoctor
        ? [
            _StatCard(icon: Icons.analytics_rounded, value: _val('reports'), label: 'Reports Issued', color: const Color(0xFF2563EB), isDark: isDark, delay: 0),
            _StatCard(icon: Icons.people_rounded,    value: _val('patients'), label: 'Patients',       color: const Color(0xFF10B981), isDark: isDark, delay: 80),
            _StatCard(icon: Icons.warning_amber_rounded, value: _val('fractures'), label: 'Fractures Found', color: const Color(0xFFF59E0B), isDark: isDark, delay: 160),
          ]
        : [
            _StatCard(icon: Icons.folder_open_rounded,  value: _val('reports'),   label: 'X-Ray Reports', color: const Color(0xFF2563EB), isDark: isDark, delay: 0),
          ];

    if (isDoctor) {
      return Row(
        children: items
            .map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 14), child: c)))
            .toList(),
      );
    } else {
      return Row(
        children: [
          SizedBox(width: 420, child: items.first),
        ],
      );
    }
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final int delay;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    this.delay = 0,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _iconPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _iconPulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E2538) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: _iconPulse,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _QuickActionsRow extends StatelessWidget {
  final bool isDoctor;
  final bool isDark;
  const _QuickActionsRow({required this.isDoctor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = isDoctor
        ? [
            _ActionCard(icon: Icons.upload_file_rounded, title: 'Upload X-Ray', subtitle: 'Analyze a new scan', color: const Color(0xFF2563EB), isDark: isDark),
            _ActionCard(icon: Icons.history_rounded, title: 'View History', subtitle: 'All patient reports', color: const Color(0xFF10B981), isDark: isDark),
          ]
        : [
            _ActionCard(icon: Icons.folder_open_rounded, title: 'My Reports', subtitle: 'View your results', color: const Color(0xFF2563EB), isDark: isDark),
            _ActionCard(icon: Icons.person_rounded, title: 'My Profile', subtitle: 'Account details', color: const Color(0xFF10B981), isDark: isDark),
          ];

    return Row(
      children: items
          .map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 14), child: c)))
          .toList(),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovering
              ? widget.color.withOpacity(0.06)
              : (widget.isDark ? const Color(0xFF1E2538) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovering ? widget.color.withOpacity(0.3) : (widget.isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: widget.isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Animated Sidebar Logo Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _AnimatedSidebarLogo extends StatefulWidget {
  const _AnimatedSidebarLogo();

  @override
  State<_AnimatedSidebarLogo> createState() => _AnimatedSidebarLogoState();
}

class _AnimatedSidebarLogoState extends State<_AnimatedSidebarLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB)
                    .withOpacity(0.15 + 0.45 * _glow.value),
                blurRadius: 6 + 14 * _glow.value,
                spreadRadius: _glow.value * 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ RSNA News Section Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _RsnaArticle {
  final String title;
  final String url;
  final String journal;
  final String date;
  final String description;
  String imageUrl;

  _RsnaArticle({
    required this.title,
    required this.url,
    required this.journal,
    required this.date,
    required this.description,
    this.imageUrl = '',
  });
}

class _RsnaNewsSection extends StatefulWidget {
  final bool isDark;
  const _RsnaNewsSection({required this.isDark});

  @override
  State<_RsnaNewsSection> createState() => _RsnaNewsSectionState();
}

class _RsnaNewsSectionState extends State<_RsnaNewsSection> {
  List<_RsnaArticle> _articles = [];
  bool _loading = true;
  String? _error;
  String? _debugError;

  // Crossref REST API returns clean JSON natively with DOI links. Completely free and open.
  static const _crossrefBase = 'https://api.crossref.org/journals';

  // Topic pairs: (Category Name, Journal ISSN)
  // 1527-1315 = Radiology (RSNA)
  // 1535-1386 = Journal of Bone and Joint Surgery
  // 2638-6100 = Radiology: Artificial Intelligence (RSNA)
  static const _queries = [
    ('Radiology',       '1527-1315'),
    ('Bone & Fracture', '1535-1386'),
    ('AI Radiology',    '2638-6100'),
  ];

  static const _headers = {
    'User-Agent': 'mailto:demo@xrbone.local - XRBone App Medical News Fetcher',
    'Accept': 'application/json',
  };

  // Fast CDN images per category â€” no extra HTTP requests needed
  static const _categoryImages = {
    'Radiology': [
      'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=400&h=200&fit=crop&q=80',
      'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=400&h=200&fit=crop&q=80',
    ],
    'Bone & Fracture': [
      'https://images.unsplash.com/photo-1530497610245-b484b34d1a0a?w=400&h=200&fit=crop&q=80',
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&h=200&fit=crop&q=80',
    ],
    'AI Radiology': [
      'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400&h=200&fit=crop&q=80',
      'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=400&h=200&fit=crop&q=80',
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() { _loading = true; _error = null; _debugError = null; });
    final all = <_RsnaArticle>[];
    final errors = <String>[];

    for (final (journal, issn) in _queries) {
      try {
        final url = '$_crossrefBase/$issn/works?select=title,URL,container-title,published,abstract&rows=2&sort=created&order=desc';
        final response = await http.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final message = data['message'] as Map<String, dynamic>? ?? {};
          final items = message['items'] as List<dynamic>? ?? [];

          for (final item in items) {
            final titles = item['title'] as List<dynamic>? ?? [];
            final t = titles.isNotEmpty ? titles.first.toString() : '';
            final link = item['URL']?.toString() ?? '';
            final containerNames = item['container-title'] as List<dynamic>? ?? [];
            final pubName = containerNames.isNotEmpty ? containerNames.first.toString() : journal;
            final desc = _stripHtml(item['abstract']?.toString() ?? '').trim();

            // Parse Crossref date array: [YYYY, MM, DD]
            String pubDate = '';
            final published = item['published'] as Map<String, dynamic>?;
            if (published != null) {
              final datePartsArray = published['date-parts'] as List<dynamic>? ?? [];
              if (datePartsArray.isNotEmpty) {
                final dateParts = datePartsArray.first as List<dynamic>? ?? [];
                if (dateParts.isNotEmpty) {
                  pubDate = dateParts.join('-'); // E.g., "2024-05-12"
                }
              }
            }

            if (t.isNotEmpty) {
              final imgs = _categoryImages[journal] ?? [];
              final imgIdx = all.where((a) => a.journal == journal).length;
              final imgUrl = imgs.isNotEmpty ? imgs[imgIdx % imgs.length] : '';
              all.add(_RsnaArticle(
                title: t,
                url: link,
                journal: journal,
                date: pubDate,
                description: desc,
                imageUrl: imgUrl,
              ));
            }
          }
        } else {
          errors.add('$journal: HTTP ${response.statusCode}');
        }
      } catch (e) {
        errors.add('$journal: $e');
      }
    }

    final articles = all.take(6).toList();

    if (mounted) {
      setState(() {
        _articles = articles;
        _loading = false;
        if (articles.isEmpty) {
          _error = 'Could not load news.';
          _debugError = errors.join('\n');
        }
      });
    }

  }

  String _formatDate(String raw) {
    try {
      // RSS dates: "Tue, 15 Apr 2025 00:00:00 GMT"
      final parts = raw.split(' ');
      if (parts.length >= 4) return '${parts[1]} ${parts[2]} ${parts[3]}';
    } catch (_) {}
    return raw.isNotEmpty ? raw.substring(0, raw.length.clamp(0, 16)) : '';
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.newspaper_rounded, color: Color(0xFF0EA5E9), size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Radiology News',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Latest from RSNA Journals',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _fetchNews,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2538) : const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 14,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_loading)
          _buildSkeletonGrid(isDark)
        else if (_error != null)
          _buildError(isDark)
        else
          _buildGrid(isDark),
      ],
    );
  }

  Widget _buildGrid(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < 3 && i < _articles.length; i++) ...[
              Expanded(child: _NewsCard(article: _articles[i], isDark: isDark)),
              if (i < 2) const SizedBox(width: 14),
            ],
          ],
        ),
        if (_articles.length > 3) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (int i = 3; i < 6 && i < _articles.length; i++) ...[
                Expanded(child: _NewsCard(article: _articles[i], isDark: isDark)),
                if (i < 5 && i < _articles.length - 1) const SizedBox(width: 14),
              ],
              // Fill empty slots
              for (int i = _articles.length; i < 6 && i >= 3; i++) ...[
                if (i > 3) const SizedBox(width: 14),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSkeletonGrid(bool isDark) {
    return Column(
      children: [
        Row(
          children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 14 : 0),
              child: _SkeletonCard(isDark: isDark),
            ),
          )),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 14 : 0),
              child: _SkeletonCard(isDark: isDark),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildError(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 36,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              )),
            if (_debugError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _debugError!,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _fetchNews,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Try Again',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ News Card Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _NewsCard extends StatefulWidget {
  final _RsnaArticle article;
  final bool isDark;
  const _NewsCard({required this.article, required this.isDark});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _hovering = false;

  Color get _journalColor {
    switch (widget.article.journal) {
      case 'Bone & Fracture': return const Color(0xFF10B981);
      case 'AI Radiology':    return const Color(0xFF8B5CF6);
      default:                return const Color(0xFF0EA5E9);
    }
  }

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(widget.article.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final color = _journalColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _openUrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _hovering
                ? (isDark ? const Color(0xFF1E2D40) : const Color(0xFFF0F9FF))
                : (isDark ? const Color(0xFF1E2538) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering
                  ? color.withOpacity(0.4)
                  : (isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
            ),
            boxShadow: _hovering
                ? [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article image
              if (widget.article.imageUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 130,
                  child: Image.network(
                    widget.article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.article_rounded, size: 32, color: color.withOpacity(0.3)),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.article_rounded, size: 28, color: color.withOpacity(0.3)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Journal badge + date row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.article.journal,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.article.date.isNotEmpty)
                    Text(
                      widget.article.date,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                widget.article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Description snippet
              if (widget.article.description.isNotEmpty)
                Text(
                  widget.article.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              const SizedBox(height: 12),

              // Read more link
              Row(
                children: [
                  Text(
                    'Read article',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 11, color: color),
                ],
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Skeleton Card Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? const Color(0xFF1E2538) : Colors.white;
    final shine = widget.isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBlock(width: 80, height: 18, base: base, shine: shine),
            const SizedBox(height: 14),
            _shimmerBlock(width: double.infinity, height: 12, base: base, shine: shine),
            const SizedBox(height: 6),
            _shimmerBlock(width: double.infinity, height: 12, base: base, shine: shine),
            const SizedBox(height: 6),
            _shimmerBlock(width: 120, height: 12, base: base, shine: shine),
            const SizedBox(height: 14),
            _shimmerBlock(width: 80, height: 10, base: base, shine: shine),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBlock({required double width, required double height, required Color base, required Color shine}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(base, shine, _shimmer.value),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
