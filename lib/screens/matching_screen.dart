import 'package:flutter/material.dart';
import '../models/term.dart';
import '../storage/progress_storage.dart';
import '../theme/duo.dart';

/// Zuordnungsspiel: 4 Begriffe links, 4 Definitionen rechts.
/// Erst Begriff tippen, dann passende Definition tippen.
class MatchingScreen extends StatefulWidget {
  final List<Term> terms;
  final Future<void> Function() onGamificationChanged;
  const MatchingScreen({
    super.key,
    required this.terms,
    required this.onGamificationChanged,
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  late List<Term> _left; // Begriffe
  late List<Term> _right; // Definitionen (gemischt)
  String? _selectedLeftId;
  final Set<String> _solved = {};
  String? _errorId;
  int _tries = 0;
  int _pairs = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final pool = List<Term>.from(widget.terms)..shuffle();
    final pick = pool.take(4).toList();
    _left = List<Term>.from(pick)..shuffle();
    _right = List<Term>.from(pick)..shuffle();
    _selectedLeftId = null;
    _solved.clear();
    _errorId = null;
    _tries = 0;
    _pairs = 0;
  }

  void _tapLeft(String id) {
    if (_solved.contains(id)) return;
    setState(() {
      _selectedLeftId = id;
      _errorId = null;
    });
  }

  Future<void> _tapRight(String id) async {
    if (_selectedLeftId == null || _solved.contains(id)) return;
    final matched = _selectedLeftId == id;
    setState(() {
      _tries++;
      if (matched) {
        _solved.add(id);
        _pairs++;
        _selectedLeftId = null;
      } else {
        _errorId = id;
      }
    });
    if (!matched) return;
    await ProgressStorage.addXP(5);
    await widget.onGamificationChanged();
    if (!mounted) return;
    if (_solved.length == _left.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geschafft! +20 XP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.terms.length < 4) {
      return const Center(child: Text('Mindestens 4 Begriffe nötig.'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text('Paare: $_pairs/4 • Versuche: $_tries',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              IconButton(
                tooltip: 'Neue Runde',
                onPressed: () => setState(_newRound),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const Text('1. Begriff links wählen, 2. passende Definition rechts tippen.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    children: _left.map((t) {
                      final solved = _solved.contains(t.id);
                      final selected = _selectedLeftId == t.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: solved
                                ? Colors.green.shade100
                                : selected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : null,
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed:
                              solved ? null : () => _tapLeft(t.id),
                          child: Text(
                            solved ? '✓ ${t.begriff}' : t.begriff,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListView(
                    children: _right.map((t) {
                      final solved = _solved.contains(t.id);
                      final isErr = _errorId == t.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: solved
                                ? Colors.green.shade50
                                : isErr
                                    ? Colors.red.shade50
                                    : null,
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed:
                              solved ? null : () => _tapRight(t.id),
                          child: Text(
                            t.definition,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          if (_solved.length == _left.length)
            DuoButton(
              label: 'Neue Runde',
              icon: Icons.refresh,
              onPressed: () => setState(_newRound),
            ),
        ],
      ),
    );
  }
}
