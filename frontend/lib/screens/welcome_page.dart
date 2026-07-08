import 'package:flutter/material.dart';
import 'index.dart';
import '../theme/theme_notifier.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _heroController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _heroController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B0F1A), Color(0xFF111827), Color(0xFF0D1321)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF0F7FF), Color(0xFFE8F0FE), Color(0xFFF8FAFF)],
                    ),
            ),
          ),

          // Decorative orbs
          Positioned(
            top: -80,
            left: -80,
            child: _Orb(size: 300, color: const Color(0xFF2563EB), opacity: isDark ? 0.12 : 0.08),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _Orb(size: 400, color: const Color(0xFF6366F1), opacity: isDark ? 0.10 : 0.06),
          ),
          Positioned(
            top: size.height * 0.4,
            left: size.width * 0.7,
            child: _Orb(size: 200, color: const Color(0xFF06B6D4), opacity: isDark ? 0.08 : 0.05),
          ),

          // Grid lines
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _GridPainter(isDark: isDark),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with pulse
                    ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Brand text
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF818CF8)],
                      ).createShader(bounds),
                      child: const Text(
                        'XRBone',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'AI-Powered Bone Fracture Detection',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feature pills
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Pill(label: 'Precision', isDark: isDark),
                        const SizedBox(width: 8),
                        _Pill(label: 'Fast', isDark: isDark),
                        const SizedBox(width: 8),
                        _Pill(label: 'Secure', isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: 64),

                    // CTA button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const LoginPage(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 400),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Enter Portal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dark mode toggle
                    _DarkModeToggle(isDark: isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isDark;
  const _Pill({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2538)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _DarkModeToggle extends StatelessWidget {
  final bool isDark;
  const _DarkModeToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => themeNotifier.toggleTheme(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2538) : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDark),
                  size: 16,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
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
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.blue).withOpacity(0.025)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.isDark != isDark;
}
