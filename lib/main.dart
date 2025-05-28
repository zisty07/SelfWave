// aplicatie pentru self wave
// scrisa de un elev roman din liceu

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/main_home_screen.dart';
import 'profile/profile_manager.dart';
import 'profile/profile_management_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

// functia principala
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default to dark mode
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;
  late Locale _locale;
  late UserProfile _currentProfile;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadProfile();
    _loadSavedLanguage();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileManager.loadProfile();
    setState(() => _currentProfile = profile);
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('languageCode') ?? 'en';
    setState(() {
      _locale = Locale(savedLanguageCode);
    });
  }

  void _changeLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return; // Don't change if it's the same language
    
    // First save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    
    // Then update the state
    if (mounted) {
      setState(() {
        _locale = Locale(languageCode);
      });
      
      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageCode == 'en' ? 'Language changed to English' : 'Limba schimbată în română'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
      
      // Force rebuild of the entire app
      (context as Element).markNeedsBuild();
    }
  }

  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6750A4),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEADDFF),
        onPrimaryContainer: Color(0xFF21005E),
        secondary: Color(0xFF625B71),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE8DEF8),
        onSecondaryContainer: Color(0xFF1E192B),
        tertiary: Color(0xFF7D5260),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFFFD8E4),
        onTertiaryContainer: Color(0xFF31111D),
        error: Color(0xFFB3261E),
        onError: Colors.white,
        errorContainer: Color(0xFFF9DEDC),
        onErrorContainer: Color(0xFF410E0B),
        surface: Colors.white,
        onSurface: Color(0xFF1C1B1F),
        surfaceContainerHighest: Color(0xFFE7E0EC),
        onSurfaceVariant: Color(0xFF49454F),
        outline: Color(0xFF79747E),
        outlineVariant: Color(0xFFCAC4D0),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF313033),
        onInverseSurface: Color(0xFFF4EFF4),
        inversePrimary: Color(0xFFD0BCFF),
        surfaceTint: Color(0xFF6750A4),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFCAC4D0).withOpacity(0.2),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1C1B1F),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE7E0EC),
        selectedColor: const Color(0xFFEADDFF),
        labelStyle: const TextStyle(color: Color(0xFF1C1B1F)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1C1B1F)),
        bodyMedium: TextStyle(color: Color(0xFF1C1B1F)),
        titleLarge: TextStyle(color: Color(0xFF1C1B1F)),
        titleMedium: TextStyle(color: Color(0xFF1C1B1F)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFFCAC4D0).withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFFCAC4D0).withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6750A4),
          ),
        ),
        hintStyle: TextStyle(
          color: const Color(0xFF1C1B1F).withOpacity(0.6),
        ),
      ),
    );
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD0BCFF),
        onPrimary: Color(0xFF381E72),
        primaryContainer: Color(0xFF4F378B),
        onPrimaryContainer: Color(0xFFEADDFF),
        secondary: Color(0xFFCCC2DC),
        onSecondary: Color(0xFF332D41),
        secondaryContainer: Color(0xFF4A4458),
        onSecondaryContainer: Color(0xFFE8DEF8),
        tertiary: Color(0xFFEFB8C8),
        onTertiary: Color(0xFF492532),
        tertiaryContainer: Color(0xFF633B48),
        onTertiaryContainer: Color(0xFFFFD8E4),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF1C1B1F),
        onSurface: Color(0xFFE6E1E5),
        surfaceContainerHighest: Color(0xFF2D2C31),
        onSurfaceVariant: Color(0xFFCAC4D0),
        outline: Color(0xFF938F99),
        outlineVariant: Color(0xFF49454F),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE6E1E5),
        onInverseSurface: Color(0xFF313033),
        inversePrimary: Color(0xFF6750A4),
        surfaceTint: Color(0xFFD0BCFF),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF49454F).withOpacity(0.2),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE6E1E5),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: const Color(0xFFE6E1E5),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1C1B1F),
        modalBackgroundColor: Color(0xFF1C1B1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2D2C31),
        selectedColor: const Color(0xFF4F378B),
        labelStyle: const TextStyle(color: Color(0xFFE6E1E5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE6E1E5)),
        bodyMedium: TextStyle(color: Color(0xFFE6E1E5)),
        titleLarge: TextStyle(color: Color(0xFFE6E1E5)),
        titleMedium: TextStyle(color: Color(0xFFE6E1E5)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2C31),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF49454F).withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF49454F).withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6750A4),
          ),
        ),
        hintStyle: TextStyle(
          color: const Color(0xFFE6E1E5).withOpacity(0.6),
        ),
      ),
    );
    return AnimatedTheme(
      data: _isDarkMode ? darkTheme : lightTheme,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: MaterialApp(
        title: 'SelfWave',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('ro'), // Romanian
        ],
        home: LauncherScreen(
          isDarkMode: _isDarkMode,
          onThemeToggle: _toggleTheme,
          locale: _locale,
          onLanguageChanged: _changeLanguage,
        ),
      ),
    );
  }
}

class LauncherScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final Locale locale;
  final Function(String) onLanguageChanged;
  const LauncherScreen({
    Key? key, 
    required this.isDarkMode, 
    required this.onThemeToggle, 
    required this.locale, 
    required this.onLanguageChanged
  }) : super(key: key);

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  @override
  void didUpdateWidget(LauncherScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) {
      // If locale changed, rebuild the screen
      setState(() {});
    }
  }

  Future<void> _decideStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final showOnboarding = prefs.getBool('showOnboarding') ?? true;
    final profile = await ProfileManager.getCurrentProfile();

    if (profile == null) {
      if (!mounted) return;
      try {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => ProfileManagementScreen(
              onProfileChanged: () async {
                final updatedProfile = await ProfileManager.getCurrentProfile();
                if (updatedProfile != null && mounted) {
                  setState(() {});
                }
              },
            ),
          ),
        );
        
        if (result == true && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => LauncherScreen(
                isDarkMode: widget.isDarkMode,
                onThemeToggle: widget.onThemeToggle,
                locale: widget.locale,
                onLanguageChanged: widget.onLanguageChanged,
              ),
            ),
          );
        }
      } catch (e) {
        print('Error navigating to profile management: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
      return;
    }

    if (showOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            onGetStarted: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showOnboarding', false);
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainHomeScreen(
                    onThemeToggle: widget.onThemeToggle,
                    isDarkMode: widget.isDarkMode,
                    currentProfile: profile,
                    onManageProfiles: () {
                      // Create a new BuildContext for navigation
                      final navigatorContext = context;
                      return Navigator.of(navigatorContext).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => ProfileManagementScreen(
                            onProfileChanged: () async {
                              final updatedProfile = await ProfileManager.getCurrentProfile();
                              if (updatedProfile != null) {
                                // Use the navigator context for setState
                                if (navigatorContext.mounted) {
                                  (navigatorContext as Element).markNeedsBuild();
                                }
                              }
                            },
                          ),
                        ),
                      ).then((result) {
                        if (result == true && navigatorContext.mounted) {
                          (navigatorContext as Element).markNeedsBuild();
                        }
                      }).catchError((e) {
                        print('Error navigating to profile management: $e');
                        if (navigatorContext.mounted) {
                          ScaffoldMessenger.of(navigatorContext).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      });
                    },
                    onLanguageChanged: widget.onLanguageChanged,
                    currentLocale: widget.locale,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainHomeScreen(
            onThemeToggle: widget.onThemeToggle,
            isDarkMode: widget.isDarkMode,
            currentProfile: profile,
            onManageProfiles: () {
              // Create a new BuildContext for navigation
              final navigatorContext = context;
              return Navigator.of(navigatorContext).push<bool>(
                MaterialPageRoute(
                  builder: (context) => ProfileManagementScreen(
                    onProfileChanged: () async {
                      final updatedProfile = await ProfileManager.getCurrentProfile();
                      if (updatedProfile != null) {
                        // Use the navigator context for setState
                        if (navigatorContext.mounted) {
                          (navigatorContext as Element).markNeedsBuild();
                        }
                      }
                    },
                  ),
                ),
              ).then((result) {
                if (result == true && navigatorContext.mounted) {
                  (navigatorContext as Element).markNeedsBuild();
                }
              }).catchError((e) {
                print('Error navigating to profile management: $e');
                if (navigatorContext.mounted) {
                  ScaffoldMessenger.of(navigatorContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              });
            },
            onLanguageChanged: widget.onLanguageChanged,
            currentLocale: widget.locale,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}