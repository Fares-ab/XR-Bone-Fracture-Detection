import 'package:flutter/material.dart';
import 'screens/index.dart';
import 'theme/theme_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XRBoneApp());
}

class XRBoneApp extends StatefulWidget {
  const XRBoneApp({super.key});

  @override
  State<XRBoneApp> createState() => _XRBoneAppState();
}

class _XRBoneAppState extends State<XRBoneApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() {
      setState(() {});
    });
  }

  ThemeData _buildLightTheme() {
    const primaryBlue = Color(0xFF2563EB);
    const surfaceColor = Color(0xFFF8FAFF);
    const cardColor = Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        surface: surfaceColor,
        surfaceContainerHighest: cardColor,
      ),
      scaffoldBackgroundColor: surfaceColor,
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
        prefixIconColor: Colors.grey.shade500,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.grey.shade100,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF475569)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        shadowColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade100,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: const ListTileThemeData(
        mouseCursor: WidgetStateMouseCursor.clickable,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryBlue = Color(0xFF3B82F6);
    const bg = Color(0xFF0B0F1A);
    const surface = Color(0xFF111827);
    const card = Color(0xFF1E2538);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        surface: bg,
        surfaceContainerHighest: card,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
        prefixIconColor: const Color(0xFF475569),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Color(0xFF94A3B8)),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFF2D3748)),
        ),
        shadowColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E2D3D),
        thickness: 1,
        space: 1,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF1E2538),
        labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      listTileTheme: const ListTileThemeData(
        mouseCursor: WidgetStateMouseCursor.clickable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XRBone',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      home: const WelcomePage(),
    );
  }
}
