import 'package:flutter/material.dart';
import '../models/term.dart';
import '../storage/progress_storage.dart';
import '../theme/duo.dart';

class _QuizQuestion {
  final Term correct;
  final List<String> options; // Begriffe
  _QuizQuestion({required this.correct, required this.options});
}

class QuizScreen extends StatefulWidget {
  final List<Term> terms;
  final Future<void> Function() onGamificationChanged;
  const QuizScreen({
    super.key,
    required this.terms,
    required this.onGamificationChanged,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<_QuizQuestion> _questions;
  int _index = 0;
  int _score = 0;
  String? _picked;
  bool _finished = false;
  int _best = 0;
  int _hearts = 3;
  int _gained = 0;
  bool _outOfHearts = false;

  @override
  void initState() {
    super.initState();
    _startRound();
    ProgressStorage.loadBestQuiz().then((v) {
      if (mounted) setState(() => _best = v);
    });
  }

  void _startRound() {
    final pool = List<Term>.from(widget.terms)..shuffle();
    final round = pool.take(10).toList();
    _questions = round.map((t) {
      final others = List<Term>.from(widget.terms)
        ..removeWhere((e) => e.id == t.id)
        ..shuffle();
      final opts = <String>{t.begriff};
      for (final o in others) {
        if (opts.length >= 4) break;
        opts.add(o.begriff);
      }
      final list = opts.toList()..shuffle();
      return _QuizQuestion(correct: t, options: list);
    }).toList();
    _index = 0;
    _score = 0;
    _picked = null;
    _finished = false;
    _hearts = 3;
    _gained = 0;
    _outOfHearts = false;
  }

  Future<void> _pick(String begriff) async {
    if (_picked != null || _finished) return;
    final correct = begriff == _questions[_index].correct.begriff;
    setState(() {
      _picked = begriff;
      if (correct) {
        _score++;
        _gained += 10;
      } else {
        _hearts--;
      }
    });
    if (correct) {
      await ProgressStorage.addXP(10);
      await widget.onGamificationChanged();
    } else if (_hearts <= 0) {
      setState(() {
        _finished = true;
        _outOfHearts = true;
      });
      await ProgressStorage.saveBestQuiz(_score);
      final b = await ProgressStorage.loadBestQuiz();
      if (!mounted) return;
      setState(() => _best = b);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Herzen aufgebraucht! +$_gained XP')),
      );
    }
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _picked = null;
      });
    } else {
      setState(() => _finished = true);
      ProgressStorage.saveBestQuiz(_score).then((_) async {
        final b = await ProgressStorage.loadBestQuiz();
        if (mounted) setState(() => _best = b);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Runde fertig! +$_gained XP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.terms.length < 4) {
      return const Center(
        child: Text('Mindestens 4 Begriffe fürs Quiz nötig.'),
      );
    }
    if (_finished) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _outOfHearts ? 'Herzen aufgebraucht!' : 'Runde beendet!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                '$_score / ${_index + 1}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '+$_gained XP',
                style: const TextStyle(
                  color: DuoColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text('Bestleistung: $_best'),
              const SizedBox(height: 16),
              DuoButton(
                label: 'Neue Runde',
                icon: Icons.refresh,
                onPressed: () => setState(_startRound),
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ...List.generate(
                3,
                (i) => Icon(
                  Icons.favorite,
                  size: 20,
                  color:
                      i < _hearts ? DuoColors.red : Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: (_index + 1) / _questions.length,
                ),
              ),
              const SizedBox(width: 12),
              Text('Frage ${_index + 1}/${_questions.length} • $_score Punkte'),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Chip(label: Text(q.correct.kategorie)),
                  const SizedBox(height: 8),
                  Text(
                    q.correct.definition,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Welcher Begriff passt?',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...q.options.map((opt) {
            final isCorrect = opt == q.correct.begriff;
            final isPicked = opt == _picked;
            Color? bg;
            if (_picked != null) {
              if (isCorrect) bg = Colors.green.shade100;
              if (isPicked && !isCorrect) bg = Colors.red.shade100;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _pick(opt),
                child: Text(opt, textAlign: TextAlign.center),
              ),
            );
          }),
          const Spacer(),
          if (_picked != null)
            DuoButton(
              label: _index < _questions.length - 1 ? 'Weiter' : 'Ergebnis',
              onPressed: _next,
            ),
        ],
      ),
    );
  }
}
