import 'package:flutter/material.dart';
import '../models/term.dart';
import '../theme/duo.dart';

class FlashcardsScreen extends StatefulWidget {
  final List<Term> terms;
  final Set<String> knownIds;
  final void Function(String id, bool known) onKnownChanged;

  const FlashcardsScreen({
    super.key,
    required this.terms,
    required this.knownIds,
    required this.onKnownChanged,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late List<Term> _queue;
  int _index = 0;
  bool _showBack = false;
  bool _onlyUnknown = false;

  @override
  void initState() {
    super.initState();
    _rebuildQueue();
  }

  @override
  void didUpdateWidget(covariant FlashcardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.terms != widget.terms ||
        oldWidget.knownIds != widget.knownIds) {
      _rebuildQueue(keepIndex: true);
    }
  }

  void _rebuildQueue({bool keepIndex = false}) {
    var list = List<Term>.from(widget.terms)..shuffle();
    if (_onlyUnknown) {
      list = list.where((t) => !widget.knownIds.contains(t.id)).toList();
    }
    _queue = list;
    if (!keepIndex) {
      _index = 0;
      _showBack = false;
    } else {
      _index = _index.clamp(0, _queue.isEmpty ? 0 : _queue.length - 1);
    }
  }

  void _mark(bool known) {
    if (_queue.isEmpty) return;
    final term = _queue[_index];
    widget.onKnownChanged(term.id, known);
    setState(() {
      if (_index < _queue.length - 1) {
        _index++;
        _showBack = false;
      } else {
        // Runde fertig -> neu mischen
        _showBack = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stapel durch! Wird neu gemischt.')),
        );
        _rebuildQueue();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.terms.isEmpty) {
      return const Center(child: Text('Keine Begriffe vorhanden.'));
    }
    if (_queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alle Begriffe gelernt! Stark.'),
            const SizedBox(height: 12),
            DuoButton(
              label: 'Alle wiederholen',
              icon: Icons.refresh,
              onPressed: () => setState(() {
                _onlyUnknown = false;
                _rebuildQueue();
              }),
            ),
          ],
        ),
      );
    }

    final term = _queue[_index];
    final known = widget.knownIds.contains(term.id);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_index + 1) / _queue.length,
                ),
              ),
              const SizedBox(width: 12),
              Text('${_index + 1}/${_queue.length}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Nur ungelernte'),
                selected: _onlyUnknown,
                onSelected: (v) => setState(() {
                  _onlyUnknown = v;
                  _rebuildQueue();
                }),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Mischen',
                onPressed: () => setState(() {
                  _queue.shuffle();
                  _index = 0;
                  _showBack = false;
                }),
                icon: const Icon(Icons.shuffle),
              ),
              if (known)
                const Chip(
                  label: Text('gelernt'),
                  avatar: Icon(Icons.check, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBack = !_showBack),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Card(
                  key: ValueKey('${term.id}_$_showBack'),
                  elevation: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(label: Text(term.kategorie)),
                        const SizedBox(height: 16),
                        if (!_showBack) ...[
                          Text(
                            term.begriff,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tippen zum Umdrehen',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ] else ...[
                          Text(
                            term.definition,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Beispiel: ${term.beispiel}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DuoButton.secondary(
                  onPressed: () => _mark(false),
                  icon: Icons.close,
                  label: 'Nochmal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DuoButton(
                  onPressed: () => _mark(true),
                  icon: Icons.check,
                  label: 'Gewusst',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _index > 0
                    ? () => setState(() {
                          _index--;
                          _showBack = false;
                        })
                    : null,
                child: const Text('← Zurück'),
              ),
              TextButton(
                onPressed: _index < _queue.length - 1
                    ? () => setState(() {
                          _index++;
                          _showBack = false;
                        })
                    : null,
                child: const Text('Weiter →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
