// ecranul pentru profil
// aici poti schimba setarile tale

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../profile/profile_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ecranul de profil
class ProfileScreen extends StatefulWidget {
  // variabilele necesare
  final VoidCallback onThemeToggle; // pentru tema
  final bool isDarkMode; // modul intunecat
  final UserProfile currentProfile; // utilizatorul curent
  final Future<void> Function() onManageProfiles; // pentru gestionarea profilurilor
  final Function(String) onLanguageChanged;
  final Locale currentLocale;

  const ProfileScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.currentProfile,
    required this.onManageProfiles,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // serviciu notificari
  final NotificationService notificationService = NotificationService();
  
  // variabile
  bool remindersOn = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);
  List<bool> daysSelected = List.generate(7, (index) => index == 0);
  int moodLevel = 3;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    darkMode = widget.isDarkMode;
    loadSettings();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() {
        darkMode = widget.isDarkMode;
      });
    }
  }

  // incarca setarile
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      final remindersEnabled = prefs.getBool('reminders_enabled');
      remindersOn = remindersEnabled ?? false;
      
      final reminderHour = prefs.getInt('reminder_hour') ?? 20;
      final reminderMinute = prefs.getInt('reminder_minute') ?? 0;
      reminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);
      
      daysSelected = List.generate(7, (index) {
        final val = prefs.getBool('reminder_day_$index');
        if (val == null) {
          return index == 0;
        } else {
          return val == true;
        }
      });
    });
  }

  // salveaza setarile
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('reminders_enabled', remindersOn);
    await prefs.setInt('reminder_hour', reminderTime.hour);
    await prefs.setInt('reminder_minute', reminderTime.minute);
    
    for (var i = 0; i < 7; i++) {
      final safeValue = daysSelected[i] ?? false;
      await prefs.setBool('reminder_day_$i', safeValue);
    }
  }

  // actualizeaza notificarile
  Future<void> updateReminders() async {
    if (remindersOn) {
      final hasPermission = await notificationService.requestPermissions();
      
      if (!hasPermission) {
        setState(() {
          remindersOn = false;
        });
        saveSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trebuie permisiune pentru notificari'),
            ),
          );
        }
        return;
      }

      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      await notificationService.cancelAllReminders();

      for (var i = 0; i < 7; i++) {
        if (daysSelected[i]) {
          final dayOffset = (i - now.weekday + 7) % 7;
          final reminderTime = scheduledTime.add(Duration(days: dayOffset));
          
          await notificationService.scheduleMoodReminder(
            id: i + 1,
            title: 'Timpul pentru starea ta',
            body: 'Cum te simti azi? Ia-ti un moment sa reflectezi si sa inregistrezi starea ta.',
            scheduledTime: reminderTime,
            repeats: true,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificarile au fost actualizate!'),
          ),
        );
      }
    } else {
      await notificationService.cancelAllReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificarile au fost oprite'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentProfile.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (widget.currentProfile.email != null)
                    Text(widget.currentProfile.email!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _AnimatedProfileCard(
            icon: Icons.language,
            label: l10n.language,
            value: widget.currentLocale.languageCode == 'en' ? 'English' : 'Română',
            onTap: () {
              final newLocale = widget.currentLocale.languageCode == 'en' ? 'ro' : 'en';
              widget.onLanguageChanged(newLocale);
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.currentLocale.languageCode == 'en' ? 'EN' : 'RO',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.currentLocale.languageCode == 'en' ? 'RO' : 'EN',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedProfileCard(
            icon: darkMode ? Icons.dark_mode : Icons.light_mode,
            label: l10n.darkMode,
            value: darkMode ? l10n.dark : l10n.light,
            onTap: widget.onThemeToggle,
          ),
          const SizedBox(height: 16),
          _AnimatedProfileCard(
            icon: Icons.manage_accounts,
            label: l10n.manageProfiles,
            value: '',
            onTap: () async {
              print('Manage profiles button tapped');
              try {
                await widget.onManageProfiles();
                print('Manage profiles callback completed');
              } catch (e) {
                print('Error in manage profiles callback: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AnimatedProfileCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;
  
  const _AnimatedProfileCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: InkWell(
              onTap: () {
                print('Card tapped: $label');
                onTap();
              },
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(icon, color: Colors.white),
                ),
                title: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: value.isNotEmpty ? Text(value) : null,
                trailing: trailing ?? const Icon(Icons.chevron_right),
              ),
            ),
          ),
        );
      },
    );
  }
}