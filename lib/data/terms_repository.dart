import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/term.dart';

/// Lädt die Fachbegriffe aus assets/data/terms.json.
/// Später: einfach diese JSON-Datei mit den echten Buchbegriffen ersetzen,
/// Format bleibt gleich: id, begriff, definition, beispiel, kategorie.
class TermsRepository {
  static Future<List<Term>> load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/terms.json');
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      final terms = decoded
          .whereType<Map<String, dynamic>>()
          .map(Term.fromJson)
          .where((t) => t.id.isNotEmpty && t.begriff.isNotEmpty)
          .toList();
      if (terms.isNotEmpty) return terms;
    } catch (_) {
      // Fallback unten
    }
    return _fallback;
  }

  static const _fallback = <Term>[
    Term(
      id: 'erosion',
      begriff: 'Erosion (PLATZHALTER)',
      definition: 'Abtragung von Gestein und Boden durch Wasser, Wind oder Eis.',
      beispiel: 'Ein Fluss trägt Erde an der Böschung ab.',
      kategorie: 'Geomorphologie',
    ),
    Term(
      id: 'delta',
      begriff: 'Delta (PLATZHALTER)',
      definition: 'Mündungsform eines Flusses mit Sedimentaufschüttung.',
      beispiel: 'Das Nildelta.',
      kategorie: 'Gewässer',
    ),
    Term(
      id: 'klima',
      begriff: 'Klima (PLATZHALTER)',
      definition: 'Langjähriger Mittelwert des Wetters einer Region.',
      beispiel: 'Maritimes Klima.',
      kategorie: 'Klima',
    ),
  ];
}
