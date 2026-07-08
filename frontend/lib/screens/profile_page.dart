import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'index.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late int _currentProfilePicIndex;

  final List<Map<String, dynamic>> avatars = [
    {'icon': Icons.person, 'color': Colors.blue},
    {'icon': Icons.face, 'color': Colors.green},
    {'icon': Icons.account_circle, 'color': Colors.orange},
    {'icon': Icons.emoji_emotions, 'color': Colors.purple},
    {'icon': Icons.sentiment_satisfied_alt, 'color': Colors.pink},
    {'icon': Icons.boy, 'color': Colors.teal},
    {'icon': Icons.girl, 'color': Colors.deepOrange},
    {'icon': Icons.accessibility_new, 'color': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _currentProfilePicIndex = widget.userData['profile_pic_index'] ?? 0;
  }

  void _showAvatarPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Avatar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black38),
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (_, i) {
                    final isSelected = i == _currentProfilePicIndex;
                    final color = avatars[i]['color'] as Color;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () async {
                          setState(() => _currentProfilePicIndex = i);
                          final db = await DatabaseHelper.instance.database;
                          await db.update(
                            'users',
                            {'profile_pic_index': i},
                            where: 'id = ?',
                            whereArgs: [widget.userData['id']],
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Avatar updated!'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.15) : (isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFF)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? color : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 2.5 : 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(avatars[i]['icon'] as IconData, color: color, size: 34),
                              if (isSelected)
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = widget.userData['id'] ?? 0;
    final role = widget.userData['role'] ?? 'Patient';
    final isDoctor = role == 'Doctor';
    final avatarColor = avatars[_currentProfilePicIndex]['color'] as Color;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile hero card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2538) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                // Avatar
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatarColor.withOpacity(0.12),
                            border: Border.all(color: avatarColor.withOpacity(0.3), width: 2.5),
                          ),
                          child: Icon(
                            avatars[_currentProfilePicIndex]['icon'] as IconData,
                            size: 42,
                            color: avatarColor,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E2538) : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userData['username'] ?? '',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDoctor
                              ? const Color(0xFF2563EB).withOpacity(0.1)
                              : const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDoctor ? Icons.medical_services_rounded : Icons.person_rounded,
                              size: 13,
                              color: isDoctor ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isDoctor ? 'Doctor Account' : 'Patient Account',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDoctor ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${isDoctor ? 'DR' : 'PT'}-${userId.toString().padLeft(6, '0')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info fields
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2538) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _InfoRow(icon: Icons.person_outline_rounded, label: 'Username', value: widget.userData['username'] ?? '', isDark: isDark, showDivider: true),
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: widget.userData['email'] ?? '', isDark: isDark, showDivider: true),
                _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: widget.userData['phone'] ?? '', isDark: isDark, showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const WelcomePage(),
                    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF2D1515) : const Color(0xFFFEF2F2),
                foregroundColor: isDark ? const Color(0xFFFC8181) : const Color(0xFFDC2626),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 50,
            color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFF1F5F9),
          ),
      ],
    );
  }
}
