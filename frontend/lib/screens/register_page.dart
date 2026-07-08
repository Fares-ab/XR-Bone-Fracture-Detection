import 'package:flutter/material.dart';
import '../db_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  int? _selectedPicIndex = 0;
  String _selectedRole = 'Patient';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPicIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an avatar'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    try {
      final isTaken = await DatabaseHelper.instance.isUsernameTaken(username);
      if (isTaken) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration failed: This Username is already taken.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    } catch (e) {
      // Handle db check error if any
    }

    final user = {
      'id': int.parse(_idController.text.trim()),
      'username': username,
      'password': _passwordController.text,
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'profile_pic_index': _selectedPicIndex!,
      'role': _selectedRole,
    };

    try {
      await DatabaseHelper.instance.registerUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Registration failed: $e';
      if (e.toString().contains('UNIQUE constraint failed: users.id')) {
        errorMsg = 'Registration failed: This ID is already taken.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Row(
        children: [
          // Hero side panel (large screens)
          if (size.width > 900)
            SizedBox(
              width: 360,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E40AF), Color(0xFF4F46E5)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Join XRBone',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Create an account to access AI-powered bone fracture diagnostics.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Form panel
          Expanded(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Container(
                color: isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF8FAFF),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              label: const Text('Back'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in the details to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Role selection
                            _SectionLabel(label: 'I am a...', isDark: isDark),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _RoleTile(role: 'Patient', icon: Icons.personal_injury_rounded, selectedRole: _selectedRole, isDark: isDark, onTap: () => setState(() => _selectedRole = 'Patient'))),
                                const SizedBox(width: 12),
                                Expanded(child: _RoleTile(role: 'Doctor', icon: Icons.medical_services_rounded, selectedRole: _selectedRole, isDark: isDark, onTap: () => setState(() => _selectedRole = 'Doctor'))),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Fields
                            _SectionLabel(label: 'Account Details', isDark: isDark),
                            const SizedBox(height: 10),

                            _FormField(
                              controller: _idController,
                              hint: 'User ID (Numbers only)',
                              icon: Icons.badge_outlined,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'ID is required';
                                if (int.tryParse(v.trim()) == null) return 'Must be numbers only';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              controller: _usernameController,
                              hint: 'Username',
                              icon: Icons.person_outline_rounded,
                              isDark: isDark,
                              validator: (v) => (v == null || v.length < 3) ? 'Min 3 characters' : null,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              controller: _emailController,
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                              isDark: isDark,
                              validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              controller: _phoneController,
                              hint: 'Phone number',
                              icon: Icons.phone_outlined,
                              isDark: isDark,
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v == null || v.length < 10) ? 'Invalid phone' : null,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isDark: isDark,
                              obscure: _obscurePassword,
                              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              controller: _confirmPassController,
                              hint: 'Confirm password',
                              icon: Icons.lock_outline_rounded,
                              isDark: isDark,
                              obscure: _obscureConfirmPassword,
                              onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              validator: (v) => v != _passwordController.text ? "Passwords don't match" : null,
                            ),
                            const SizedBox(height: 24),

                            // Avatar selection
                            _SectionLabel(label: 'Profile Avatar', isDark: isDark),
                            const SizedBox(height: 12),

                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1,
                              ),
                              itemCount: avatars.length,
                              itemBuilder: (_, i) {
                                final isSelected = _selectedPicIndex == i;
                                final color = avatars[i]['color'] as Color;
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedPicIndex = i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      decoration: BoxDecoration(
                                        color: isSelected ? color.withOpacity(0.12) : (isDark ? const Color(0xFF1E2538) : const Color(0xFFF8FAFF)),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? color : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
                                          width: isSelected ? 2.5 : 1.5,
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(avatars[i]['icon'] as IconData, color: color, size: 32),
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
                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                      )
                                    : const Text('Create Account'),
                              ),
                            ),
                            const SizedBox(height: 18),

                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2563EB),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String role;
  final IconData icon;
  final String selectedRole;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.icon,
    required this.selectedRole,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedRole == role;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB).withOpacity(0.1)
                : (isDark ? const Color(0xFF1E2538) : const Color(0xFFF8FAFF)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 8),
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18,
                ),
                onPressed: onToggleObscure,
              )
            : null,
      ),
    );
  }
}
