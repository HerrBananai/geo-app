import 'package:flutter/material.dart';
import '../models/term.dart';

class TermsListScreen extends StatefulWidget {
  final List<Term> terms;
  final Set<String> knownIds;
  final void Function(String id, bool known) onKnownChanged;

  const TermsListScreen({
    super.key,
    required this.terms,
    required this.knownIds,
    required this.onKnownChanged,
  });

  @override
  State<TermsListScreen> createState() => _TermsListScreenState();
}

class _TermsListScreenState extends State<TermsListScreen> {
  String _query = '';
  String _category = 'Alle';

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      'Alle',
      ...widget.terms.map((t) => t.kategorie),
    }.toList();

    final filtered = widget.terms.where((t) {
      final q = _query.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          t.begriff.toLowerCase().contains(q) ||
          t.definition.toLowerCase().contains(q);
      final matchC = _category == 'Alle' || t.kategorie == _category;
      return matchQ && matchC;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Suchen …',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Kategorie: '),
              DropdownButton<String>(
                value: categories.contains(_category) ? _category : 'Alle',
                items: categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? 'Alle'),
              ),
              const Spacer(),
              Text('${filtered.length} Begriffe'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final t = filtered[i];
              final known = widget.knownIds.contains(t.id);
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ExpansionTile(
                  leading: Checkbox(
                    value: known,
                    onChanged: (v) =>
                        widget.onKnownChanged(t.id, v ?? false),
                  ),
                  title: Text(
                    t.begriff,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration:
                          known ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(t.kategorie),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.definition),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Beispiel: ${t.beispiel}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
