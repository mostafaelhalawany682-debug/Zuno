import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth.dart';
import 'data/zuno_repository.dart';
import 'pages/discover_page.dart';
import 'pages/feed_page.dart';
import 'pages/profile_page.dart';
import 'pages/upload_page.dart';
import 'zuno_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final configured = url.startsWith('https://') &&
      !url.contains('YOUR_PROJECT') &&
      publishableKey.isNotEmpty &&
      !publishableKey.contains('YOUR_');
  if (configured) {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
  runApp(ZunoApp(supabaseConfigured: configured));
}

class ZunoApp extends StatelessWidget {
  const ZunoApp({super.key, required this.supabaseConfigured});
  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ZUNO',
        theme: buildZunoTheme(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: supabaseConfigured
            ? const AuthGate(authenticatedHome: MainShell())
            : const SupabaseSetupPage(),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _repository = ZunoRepository();
  int _tab = 0;
  int _feedRevision = 0;

  void _published() {
    setState(() {
      _feedRevision++;
      _tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      FeedPage(
        key: ValueKey(_feedRevision),
        repository: _repository,
        isVisible: _tab == 0,
      ),
      DiscoverPage(repository: _repository),
      UploadPage(repository: _repository, onPublished: _published),
      ProfilePage(repository: _repository),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        backgroundColor: zunoInk,
        indicatorColor: zunoGold.withValues(alpha: .16),
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle_fill, color: zunoGold),
            label: 'الرئيسية',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'اكتشف'),
          NavigationDestination(
              icon: Icon(Icons.add_box_outlined), label: 'نشر'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}
