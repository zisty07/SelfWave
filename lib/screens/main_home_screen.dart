// aplicatie pentru self wave
// scrisa de un elev roman din liceu
// nu stiu prea bine cod dar merge

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// importuri pentru alte ecrane
import 'todo_screen.dart';
import 'profile_screen.dart';
import 'journal_screen.dart';
import '../profile/profile_manager.dart';
import 'miscScreens/record_mood_screen.dart';

// ecranul principal al aplicatiei
class MainHomeScreen extends StatefulWidget {
  // variabile pentru ecranul principal
  final VoidCallback onThemeToggle; // buton pentru schimbarea temei
  final bool isDarkMode; // daca e modul intunecat activ
  final UserProfile currentProfile; // profilul utilizatorului curent
  final Future<void> Function() onManageProfiles; // functie pentru gestionarea profilurilor
  final Function(String) onLanguageChanged; // functie pentru schimbarea limbii
  final Locale currentLocale; // limba curenta a aplicatiei

  const MainHomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.currentProfile,
    required this.onManageProfiles,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> with TickerProviderStateMixin {
  // variabile pentru navigare si animatii
  int _selectedIndex = 0; // pagina curenta selectata
  late final AnimationController _controller; // controller pentru animatii
  final GlobalKey<JournalScreenState> _journalKey = GlobalKey<JournalScreenState>(); // cheie pentru ecranul de jurnal

  @override
  void initState() {
    super.initState();
    // initializam controllerul pentru animatii
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // durata animatiei in milisecunde
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // curatam controllerul cand nu mai e nevoie
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // lista cu toate ecranele aplicatiei
    final screens = [
      DashboardScreen(
        onThemeToggle: widget.onThemeToggle,
        isDarkMode: widget.isDarkMode,
        currentProfile: widget.currentProfile,
      ),
      JournalScreen(key: _journalKey),
      const TodoScreen(),
      ProfileScreen(
        onThemeToggle: widget.onThemeToggle,
        isDarkMode: widget.isDarkMode,
        currentProfile: widget.currentProfile,
        onManageProfiles: () async {
          print('MainHomeScreen: onManageProfiles called');
          try {
            await widget.onManageProfiles();
            print('MainHomeScreen: onManageProfiles completed');
          } catch (e) {
            print('MainHomeScreen: Error in onManageProfiles: $e');
            rethrow;
          }
        },
        onLanguageChanged: widget.onLanguageChanged,
        currentLocale: widget.currentLocale,
      ),
    ];

    // butoanele pentru navigare
    final navItems = [
      _NavBarItem(icon: Icons.dashboard_rounded, label: l10n.navHome),
      _NavBarItem(icon: Icons.book_rounded, label: l10n.navJournal),
      _NavBarItem(icon: Icons.check_circle_rounded, label: l10n.navTodo),
      _NavBarItem(icon: Icons.person_rounded, label: l10n.navProfile),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // verificam daca ecranul e lat sau ingust
        final isWide = constraints.maxWidth > 800;
        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logo-ul aplicatiei
                Image.asset('assets/imgs/minilogo.png', height: 40),
                const SizedBox(width: 8),
                // titlul aplicatiei (SelfWave)
                Text(
                  'Self',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  'Wave',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              // butonul pentru schimbarea temei (luminos/intunecat)
              IconButton(
                icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                onPressed: widget.onThemeToggle,
                tooltip: l10n.darkMode,
              ),
            ],
          ),
          body: Row(
            children: [
              // bara de navigare pentru ecrane late
              if (isWide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: navItems
                      .map((item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            label: Text(item.label),
                          ))
                      .toList(),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: screens[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
          // bara de navigare pentru ecrane inguste
          bottomNavigationBar: isWide
              ? null
              : _AnimatedBottomNavBar(
                  items: navItems,
                  selectedIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
          // butonul mare pentru adaugare (apare doar pe ecranele principale)
          floatingActionButton: _selectedIndex == 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 88),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      // deschide ecranul pentru inregistrarea starii de spirit
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecordMoodScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newEntry),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                )
              : _selectedIndex == 1
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 88),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      // deschide dialogul pentru adaugarea unei intrari in jurnal
                      final state = _journalKey.currentState;
                      if (state != null) {
                        final l10n = AppLocalizations.of(context)!;
                        state.showNewEntryDialog(context, l10n);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newEntry),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }
}

// clasa pentru elementele din bara de navigare
class _NavBarItem {
  final IconData icon; // iconita butonului
  final String label; // textul butonului
  _NavBarItem({required this.icon, required this.label});
}

// bara de navigare animata de jos
class _AnimatedBottomNavBar extends StatelessWidget {
  final List<_NavBarItem> items; // lista de butoane
  final int selectedIndex; // indexul butonului selectat
  final ValueChanged<int> onTap; // functia apelata cand se apasa un buton
  const _AnimatedBottomNavBar({required this.items, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final selected = index == selectedIndex;
            return GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(horizontal: selected ? 24 : 12, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(items[index].icon, color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                items[index].label,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ecranul principal cu statistici si informatii
class DashboardScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final UserProfile currentProfile;
  const DashboardScreen({super.key, required this.onThemeToggle, required this.isDarkMode, required this.currentProfile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Theme.of(context).colorScheme.secondary.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // profilul utilizatorului cu avatar si nume
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentProfile.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (currentProfile.email != null)
                    Text(currentProfile.email!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 32),
          // carduri cu statistici despre utilizator
          _AnimatedStatCard(
            icon: Icons.emoji_emotions,
            label: l10n.moodLevel(5),
            value: '😊',
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          _AnimatedStatCard(
            icon: Icons.book,
            label: l10n.journalTitle,
            value: '12',
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          _AnimatedStatCard(
            icon: Icons.check_circle,
            label: l10n.navTodo,
            value: '7',
            color: Colors.green,
          ),
          const SizedBox(height: 32),
          // intrebarea despre starea de spirit
          Center(
            child: Text(
              l10n.howAreYouFeelingToday,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// card animat pentru afisarea statisticilor
class _AnimatedStatCard extends StatelessWidget {
  final IconData icon; // iconita cardului
  final String label; // textul cardului
  final String value; // valoarea afisata
  final Color color; // culoarea cardului
  const _AnimatedStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: color.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      value,
                      key: ValueKey(value),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
