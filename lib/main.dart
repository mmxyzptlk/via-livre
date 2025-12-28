import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:via_livre/firebase_options.dart';
import 'package:via_livre/l10n/app_localizations.dart';
import 'screens/map_screen.dart';
import 'screens/create_report_screen.dart';
import 'screens/about_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    name: "via-livre",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ensure anonymous authentication
  final firebaseService = FirebaseService();
  await firebaseService.ensureAuthenticated();

  runApp(const ViaLivreApp());
}

class ViaLivreApp extends StatefulWidget {
  const ViaLivreApp({super.key});

  @override
  State<ViaLivreApp> createState() => _ViaLivreAppState();
}

class _ViaLivreAppState extends State<ViaLivreApp> {
  Locale _locale = const Locale('pt');

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Via Livre',
      
      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
      ],
      locale: _locale,
      
      // Theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme().copyWith(
          bodyLarge: GoogleFonts.notoSans(fontFeatures: const []),
          bodyMedium: GoogleFonts.notoSans(fontFeatures: const []),
          bodySmall: GoogleFonts.notoSans(fontFeatures: const []),
          titleLarge: GoogleFonts.notoSans(fontFeatures: const []),
          titleMedium: GoogleFonts.notoSans(fontFeatures: const []),
          titleSmall: GoogleFonts.notoSans(fontFeatures: const []),
          labelLarge: GoogleFonts.notoSans(fontFeatures: const []),
          labelMedium: GoogleFonts.notoSans(fontFeatures: const []),
          labelSmall: GoogleFonts.notoSans(fontFeatures: const []),
        ),
        // Add fallback font family for emoji support
        fontFamilyFallback: const ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji'],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      
      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) => MapScreen(
          onLanguageChanged: _changeLanguage,
        ),
        '/create-report': (context) => const CreateReportScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
