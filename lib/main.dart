import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/colors.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'views/auth/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
      ],
      child: const AspireTaskProApp(),
    ),
  );
}

class AspireTaskProApp extends StatefulWidget {
  const AspireTaskProApp({super.key});

  @override
  State<AspireTaskProApp> createState() => _AspireTaskProAppState();

  static _AspireTaskProAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_AspireTaskProAppState>()!;
}

class _AspireTaskProAppState extends State<AspireTaskProApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    final cached = StorageService.getThemeMode();
    _themeMode = cached == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      StorageService.setThemeMode(
          _themeMode == ThemeMode.dark ? 'dark' : 'light');
    });
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aspire',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AspireColors.lightBg,
        cardColor: AspireColors.lightCard,
        dividerColor: AspireColors.lightBorder,
        colorScheme: const ColorScheme.light(
          primary: AspireColors.primary,
          secondary: AspireColors.secondary,
          surface: AspireColors.lightCard,
          error: Colors.red,
        ),
        textTheme:
            GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
          titleLarge: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AspireColors.lightTextPrimary),
          titleMedium: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: AspireColors.lightTextPrimary),
          bodyLarge: GoogleFonts.outfit(color: AspireColors.lightTextPrimary),
          bodyMedium:
              GoogleFonts.outfit(color: AspireColors.lightTextSecondary),
        ),
        cardTheme: CardThemeData(
          color: AspireColors.lightCard,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AspireColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AspireColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AspireColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AspireColors.primary, width: 2),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AspireColors.primary.withOpacity(0.1),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: AspireColors.primary);
            }
            return const IconThemeData(color: AspireColors.lightTextSecondary);
          }),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                  color: AspireColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12);
            }
            return const TextStyle(
                color: AspireColors.lightTextSecondary, fontSize: 12);
          }),
        ),
      ),

      // Dark Theme (Forced to Light Theme aesthetic per user request)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light, // Forced to light
        scaffoldBackgroundColor: AspireColors.lightBg,
        cardColor: AspireColors.lightCard,
        dividerColor: AspireColors.lightBorder,
        colorScheme: const ColorScheme.light(
          primary: AspireColors.primary,
          secondary: AspireColors.secondary,
          surface: AspireColors.lightCard,
          error: Colors.red,
        ),
        textTheme:
            GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
          titleLarge: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AspireColors.lightTextPrimary),
          titleMedium: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: AspireColors.lightTextPrimary),
          bodyLarge: GoogleFonts.outfit(color: AspireColors.lightTextPrimary),
          bodyMedium:
              GoogleFonts.outfit(color: AspireColors.lightTextSecondary),
        ),
        cardTheme: CardThemeData(
          color: AspireColors.lightCard,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AspireColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AspireColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AspireColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AspireColors.primary, width: 2),
          ),
        ),
      ),

      home: const SplashView(),
    );
  }
}
