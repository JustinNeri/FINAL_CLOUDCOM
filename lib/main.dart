import 'package:flutter/material.dart';
import 'add_monster.dart';
import 'catch_monster.dart';
import 'instance_toggle.dart';
import 'instance_screen.dart';
import 'edit_monster.dart';
import 'delete_monster.dart';
import 'top_hunters.dart';
import 'show_monster_map.dart';
import 'login_screen.dart';
import 'player_accounts_screen.dart';
import 'auth_models.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PlayerProfile? _currentPlayer;

  void _handleLogin(PlayerProfile profile) {
    setState(() => _currentPlayer = profile);
  }

  void _handleLogout() {
    setState(() => _currentPlayer = null);
  }

  void _handlePlayerProfileUpdate(PlayerProfile profile) {
    setState(() => _currentPlayer = profile);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monster Control Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: ThemeColors.deepNavy,
        colorScheme: ColorScheme.fromSeed(seedColor: ThemeColors.deepNavy),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        fontFamily: 'Montserrat',
        useMaterial3: false,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: ThemeColors.deepNavy,
          elevation: 2,
          toolbarHeight: 86,
          titleTextStyle: const TextStyle(color: ThemeColors.deepNavy, fontSize: 20, fontWeight: FontWeight.w800),
          iconTheme: const IconThemeData(color: ThemeColors.deepNavy),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(18))),
          titleSpacing: 16,
        ),
        cardTheme: CardThemeData(
          color: ThemeColors.cardNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: ThemeColors.borderNavy, width: 1)),
          elevation: 4,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFB0BEC5))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFB0BEC5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeColors.pokeYellow, width: 2)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(ThemeColors.pokeYellow),
            foregroundColor: MaterialStateProperty.all(Colors.black),
            elevation: MaterialStateProperty.all(8),
            shadowColor: MaterialStateProperty.all(const Color(0x99FFCB05)),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: ThemeColors.accentMuted),
        ),
      ),
      home: _currentPlayer == null
          ? LoginScreen(onLoginSuccess: _handleLogin)
          : MainMenu(
              currentPlayer: _currentPlayer!,
              onLogout: _handleLogout,
              onPlayerUpdated: _handlePlayerProfileUpdate,
            ),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({
    super.key,
    required this.currentPlayer,
    required this.onLogout,
    required this.onPlayerUpdated,
  });

  final PlayerProfile currentPlayer;
  final VoidCallback onLogout;
  final ValueChanged<PlayerProfile> onPlayerUpdated;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool instanceOn = true;

  @override
  Widget build(BuildContext context) {
    const baseGreen = ThemeColors.deepNavy;
    const accentGreen = ThemeColors.pokeYellow;
    const lightGreen = ThemeColors.accentMuted;
    const cardGreen = ThemeColors.cardNavy;
    const borderGreen = ThemeColors.borderNavy;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: baseGreen,
        elevation: 0,
        title: const Text('Monster Control Center',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _AppDrawer(
        baseGreen: baseGreen,
        currentPlayer: widget.currentPlayer,
        onLogout: widget.onLogout,
        onPlayerUpdated: widget.onPlayerUpdated,
      ),
      body: Container(
        color: const Color(0xFFF7F9FC),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: ThemeColors.pokeBlue,
                    boxShadow: [
                      BoxShadow(
                        color: ThemeColors.pokeBlue.withOpacity(0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -18,
                        child: Icon(
                          Icons.catching_pokemon,
                          size: 120,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 54,
                                width: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                                ),
                                child: const Icon(Icons.catching_pokemon, color: ThemeColors.pokeRed, size: 30),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Trainer Hub',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'A colorful base for your monster adventures',
                                    style: TextStyle(
                                      color: Color(0xFFFFF8E1),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // removed unclickable pills per UX request
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => InstanceScreen(initialStatus: instanceOn),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        instanceOn = result;
                      });
                    }
                  },
                  child: _InstancePreviewCard(
                    instanceOn: instanceOn,
                    baseGreen: baseGreen,
                    accentGreen: accentGreen,
                    borderGreen: borderGreen,
                  ),
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MenuCard(
                      title: 'Add Monsters',
                      subtitle: 'Create new entries',
                      icon: Icons.add_circle_outline,
                      color: Colors.white,
                      accent: ThemeColors.pokeBlue,
                      background: ThemeColors.pokeBlue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddMonsterScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      title: 'Catch Monsters',
                      subtitle: 'Find nearby spawns',
                      icon: Icons.catching_pokemon,
                      color: Colors.white,
                      accent: ThemeColors.pokeRed,
                      background: ThemeColors.pokeRed,
                      highlight: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CatchMonsterScreen(playerId: widget.currentPlayer.id),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      title: 'Edit Monsters',
                      subtitle: 'Update details',
                      icon: Icons.edit_outlined,
                      color: Colors.white,
                      accent: Colors.teal,
                      background: Colors.teal,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditMonsterScreen(playerId: widget.currentPlayer.id),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      title: 'Delete Monsters',
                      subtitle: 'Clean old data',
                      icon: Icons.delete_outline,
                      color: Colors.white,
                      accent: Colors.deepOrange,
                      background: Colors.deepOrange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeleteMonsterScreen(playerId: widget.currentPlayer.id),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      title: 'View Top Monster Hunters',
                      subtitle: 'Leaderboard',
                      icon: Icons.emoji_events_outlined,
                      color: Colors.white,
                      accent: Colors.purple,
                      background: Colors.purple,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TopHuntersScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      title: 'Show Monster Map',
                      subtitle: 'See hotspots',
                      icon: Icons.map_outlined,
                      color: Colors.white,
                      accent: Colors.green,
                      background: Colors.green,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ShowMonsterMapScreen(playerId: widget.currentPlayer.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accent,
    required this.background,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accent;
  final Color background;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: background,
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  if (highlight)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Focus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstancePreviewCard extends StatelessWidget {
  const _InstancePreviewCard({
    required this.instanceOn,
    required this.baseGreen,
    required this.accentGreen,
    required this.borderGreen,
  });

  final bool instanceOn;
  final Color baseGreen;
  final Color accentGreen;
  final Color borderGreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 58,
            decoration: BoxDecoration(
              color: instanceOn ? ThemeColors.pokeYellow : Colors.redAccent,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Instance status',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ThemeColors.deepNavy,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (instanceOn ? ThemeColors.pokeYellow : Colors.redAccent).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          instanceOn ? 'Online' : 'Offline',
                          key: ValueKey(instanceOn),
                          style: TextStyle(
                            color: instanceOn ? ThemeColors.deepNavy : Colors.redAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  instanceOn
                      ? 'All systems nominal. Catch flows and monitoring are active.'
                      : 'Paused for maintenance. Reactivate to resume catch and detect.',
                  style: TextStyle(
                    color: ThemeColors.deepNavy.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: ThemeColors.deepNavy.withOpacity(0.5)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ThemeColors.deepNavy),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ThemeColors.deepNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.baseGreen,
    required this.currentPlayer,
    required this.onLogout,
    required this.onPlayerUpdated,
  });

  final Color baseGreen;
  final PlayerProfile currentPlayer;
  final VoidCallback onLogout;
  final ValueChanged<PlayerProfile> onPlayerUpdated;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [ThemeColors.pokeBlue, ThemeColors.pokeRed]),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: ThemeColors.deepNavy),
            ),
            accountName: Text(
              currentPlayer.name?.isNotEmpty == true
                  ? currentPlayer.name!
                  : currentPlayer.username,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            accountEmail: Text('Player ID: ${currentPlayer.id}', style: const TextStyle(color: Colors.white70)),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ExpansionTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Manage Monsters'),
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Monster'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddMonsterScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Monsters'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditMonsterScreen(playerId: currentPlayer.id),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Monsters'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DeleteMonsterScreen(playerId: currentPlayer.id),
                    ),
                  );
                },
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('View Top Monster Hunters'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TopHuntersScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('My Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerAccountsScreen(
                    currentPlayer: currentPlayer,
                    onProfileUpdated: onPlayerUpdated,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.catching_pokemon),
            title: const Text('Catch Monsters'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CatchMonsterScreen(playerId: currentPlayer.id),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Show Monster Map'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShowMonsterMapScreen(playerId: currentPlayer.id),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}
