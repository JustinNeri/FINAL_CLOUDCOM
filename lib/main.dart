import 'package:flutter/material.dart';
import 'add_monster.dart';
import 'catch_monster.dart';
import 'instance_screen.dart';
import 'instance_status.dart';
import 'edit_monster.dart';
import 'delete_monster.dart';
import 'top_hunters.dart';
import 'show_monster_map.dart';
import 'login_screen.dart';
import 'player_accounts_screen.dart';
import 'auth_models.dart';
import 'session.dart';
import 'theme.dart';
import 'about_us.dart';
import 'privacy_policy.dart';
import 'widgets.dart';

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
  bool _restoringSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final saved = await Session.load();
    if (!mounted) return;
    setState(() {
      _currentPlayer = saved;
      _restoringSession = false;
    });
  }

  void _handleLogin(PlayerProfile profile) {
    setState(() => _currentPlayer = profile);
    Session.save(profile);
  }

  void _handleLogout() {
    setState(() => _currentPlayer = null);
    Session.clear();
  }

  void _handlePlayerProfileUpdate(PlayerProfile profile) {
    setState(() => _currentPlayer = profile);
    Session.save(profile);
  }

  @override
  Widget build(BuildContext context) {
    final Widget home;
    if (_restoringSession) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_currentPlayer == null) {
      home = LoginScreen(onLoginSuccess: _handleLogin);
    } else {
      home = MainMenu(
        currentPlayer: _currentPlayer!,
        onLogout: _handleLogout,
        onPlayerUpdated: _handlePlayerProfileUpdate,
      );
    }

    return MaterialApp(
      title: 'Monster Control Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: home,
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
  InstanceState instanceState = InstanceState.unknown;

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openInstance() async {
    final result = await Navigator.of(context).push<InstanceState>(
      MaterialPageRoute(builder: (_) => InstanceScreen(initialState: instanceState)),
    );
    if (result != null && mounted) setState(() => instanceState = result);
  }

  /// Catching is paused while the instance is down or changing state.
  void _openCatch() {
    if (!instanceState.allowsCatching) {
      final message = switch (instanceState) {
        InstanceState.starting => 'The server is still starting. Try again in a minute.',
        InstanceState.stopping => 'The server is shutting down. Start it again to catch monsters.',
        _ => 'The server is offline. Start it to catch monsters.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(label: 'Open', onPressed: _openInstance),
        ),
      );
      return;
    }
    _push(CatchMonsterScreen(playerId: widget.currentPlayer.id));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to keep hunting.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.currentPlayer;
    final actions = [
      _MenuAction(
        title: 'Catch Monsters',
        subtitle: 'Find nearby spawns',
        icon: Icons.catching_pokemon,
        color: ThemeColors.pokeRed,
        onTap: _openCatch,
      ),
      _MenuAction(
        title: 'Monster Map',
        subtitle: 'See where you caught them',
        icon: Icons.map_outlined,
        color: ThemeColors.success,
        onTap: () => _push(ShowMonsterMapScreen(playerId: player.id)),
      ),
      _MenuAction(
        title: 'Top Hunters',
        subtitle: 'Leaderboard',
        icon: Icons.emoji_events_outlined,
        color: Colors.purple,
        onTap: () => _push(TopHuntersScreen(currentPlayerId: player.id)),
      ),
      _MenuAction(
        title: 'Add Monsters',
        subtitle: 'Create a new spawn',
        icon: Icons.add_location_alt_outlined,
        color: ThemeColors.pokeBlue,
        onTap: () => _push(const AddMonsterScreen()),
      ),
      _MenuAction(
        title: 'Edit Monsters',
        subtitle: 'Rename your catches',
        icon: Icons.edit_outlined,
        color: Colors.teal,
        onTap: () => _push(EditMonsterScreen(playerId: player.id)),
      ),
      _MenuAction(
        title: 'Delete Monsters',
        subtitle: 'Release old catches',
        icon: Icons.delete_outline,
        color: Colors.deepOrange,
        onTap: () => _push(DeleteMonsterScreen(playerId: player.id)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monster Control Center'),
        actions: [
          IconButton(
            tooltip: 'My account',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _push(PlayerAccountsScreen(
              currentPlayer: player,
              onProfileUpdated: widget.onPlayerUpdated,
            )),
          ),
        ],
      ),
      drawer: _AppDrawer(
        currentPlayer: player,
        onNavigate: _push,
        onOpenCatch: _openCatch,
        onLogout: _confirmLogout,
        onPlayerUpdated: widget.onPlayerUpdated,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeCard(player: player),
                const SizedBox(height: 14),
                _InstanceCard(state: instanceState, onTap: _openInstance),
                const SizedBox(height: 22),
                const SectionTitle('What do you want to do?'),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 560 ? 3 : 2;
                    return GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 3 ? 1.35 : 1.15,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [for (final action in actions) _MenuCard(action: action)],
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
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.player});

  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [ThemeColors.pokeBlue, Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: ThemeColors.pokeBlue.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -18,
            top: -26,
            child: Icon(Icons.catching_pokemon, size: 130, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Row(
            children: [
              const AppLogo(size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${player.displayName}!',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trainer ID #${player.id} · Ready for your next hunt?',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstanceCard extends StatelessWidget {
  const _InstanceCard({required this.state, required this.onTap});

  final InstanceState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBadge(icon: state.icon, color: state.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Server instance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(width: 8),
                        Pill(label: state.label, color: state.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state == InstanceState.unknown ? 'Tap to check the server status.' : state.description,
                      style: const TextStyle(color: ThemeColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ThemeColors.accentMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuAction {
  const _MenuAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.action});

  final _MenuAction action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${action.title}. ${action.subtitle}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: action.onTap,
          splashColor: action.color.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon: action.icon, color: action.color, size: 48),
                const Spacer(),
                Text(
                  action.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ThemeColors.deepNavy, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  action.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ThemeColors.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.currentPlayer,
    required this.onNavigate,
    required this.onOpenCatch,
    required this.onLogout,
    required this.onPlayerUpdated,
  });

  final PlayerProfile currentPlayer;
  final ValueChanged<Widget> onNavigate;
  final VoidCallback onOpenCatch;
  final VoidCallback onLogout;
  final ValueChanged<PlayerProfile> onPlayerUpdated;

  @override
  Widget build(BuildContext context) {
    void go(Widget screen) {
      Navigator.pop(context);
      onNavigate(screen);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [ThemeColors.deepNavy, ThemeColors.cardNavy]),
            ),
            child: Row(
              children: [
                const AppLogo(size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPlayer.displayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text('Trainer ID #${currentPlayer.id}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.catching_pokemon),
            title: const Text('Catch Monsters'),
            onTap: () {
              Navigator.pop(context);
              onOpenCatch();
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Monster Map'),
            onTap: () => go(ShowMonsterMapScreen(playerId: currentPlayer.id)),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Top Hunters'),
            onTap: () => go(TopHuntersScreen(currentPlayerId: currentPlayer.id)),
          ),
          ExpansionTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Manage Monsters'),
            shape: const Border(),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: const Icon(Icons.add_location_alt_outlined),
                title: const Text('Add Monster'),
                onTap: () => go(const AddMonsterScreen()),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Monsters'),
                onTap: () => go(EditMonsterScreen(playerId: currentPlayer.id)),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Monsters'),
                onTap: () => go(DeleteMonsterScreen(playerId: currentPlayer.id)),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('My Account'),
            onTap: () => go(PlayerAccountsScreen(
              currentPlayer: currentPlayer,
              onProfileUpdated: onPlayerUpdated,
            )),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () => go(const AboutUsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => go(const PrivacyPolicyScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: ThemeColors.pokeRed),
            title: const Text('Log Out', style: TextStyle(color: ThemeColors.pokeRed, fontWeight: FontWeight.w600)),
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
