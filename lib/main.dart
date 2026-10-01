import 'package:flutter/material.dart';
import 'data/terms_repository.dart';
import 'models/term.dart';
import 'screens/flashcards_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/matching_screen.dart';
import 'screens/terms_list_screen.dart';
import 'storage/progress_storage.dart';
import 'theme/duo.dart';

void main() {
  runApp(const GeoApp());
}

class GeoApp extends StatelessWidget {
  const GeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo-Begriffe lernen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: DuoColors.green,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        cardTheme: const CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: DuoColors.edge, width: 2),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: DuoColors.green,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: DuoColors.nightBg,
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: DuoColors.nightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: DuoColors.nightEdge, width: 2),
          ),
        ),
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  List<Term> _terms = [];
  Set<String> _known = {};
  int _xp = 0;
  int _streak = 0;
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final terms = await TermsRepository.load();
    final known = await ProgressStorage.loadKnown();
    final xp = await ProgressStorage.loadXP();
    final streak = await ProgressStorage.loadStreakCount();
    if (!mounted) return;
    setState(() {
      _terms = terms;
      _known = known;
      _xp = xp;
      _streak = streak;
      _loading = false;
    });
  }

  Future<void> _refreshGamification() async {
    final xp = await ProgressStorage.loadXP();
    final streak = await ProgressStorage.loadStreakCount();
    if (!mounted) return;
    setState(() {
      _xp = xp;
      _streak = streak;
    });
  }

  Future<void> _setKnown(String id, bool known) async {
    final isNew = known && !_known.contains(id);
    setState(() {
      if (known) {
        _known.add(id);
      } else {
        _known.remove(id);
      }
    });
    await ProgressStorage.saveKnown(_known);
    if (isNew) {
      await ProgressStorage.addXP(5);
      await _refreshGamification();
    }
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Fortschritt löschen?'),
        content: const Text(
            'Gelernte Begriffe, XP, Streak und Bestleistung werden zurückgesetzt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ProgressStorage.reset();
      if (!mounted) return;
      setState(() {
        _known.clear();
        _xp = 0;
        _streak = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Karteikarten', 'Quiz', 'Zuordnen', 'Alle Begriffe'];
    final screens = _loading
        ? <Widget>[const Center(child: CircularProgressIndicator())]
        : <Widget>[
            FlashcardsScreen(
              terms: _terms,
              knownIds: _known,
              onKnownChanged: _setKnown,
            ),
            QuizScreen(
              terms: _terms,
              onGamificationChanged: _refreshGamification,
            ),
            MatchingScreen(
              terms: _terms,
              onGamificationChanged: _refreshGamification,
            ),
            TermsListScreen(
              terms: _terms,
              knownIds: _known,
              onKnownChanged: _setKnown,
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_loading ? 'Geo-Begriffe' : titles[_tab]),
        actions: [
          if (!_loading) ...[
            DuoStat(
              icon: Icons.whatshot,
              color: Colors.orange,
              label: '$_streak',
            ),
            DuoStat(
              icon: Icons.diamond,
              color: DuoColors.blue,
              label: '$_xp',
            ),
          ],
          IconButton(
            tooltip: 'Fortschritt zurücksetzen',
            onPressed: _reset,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _loading ? screens.first : screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Karten',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows_outlined),
            selectedIcon: Icon(Icons.compare_arrows),
            label: 'Zuordnen',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Liste',
          ),
        ],
      ),
    );
  }
}
