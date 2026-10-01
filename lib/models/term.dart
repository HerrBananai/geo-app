class Term {
  final String id;
  final String begriff;
  final String definition;
  final String beispiel;
  final String kategorie;
  final String stufe;

  const Term({
    required this.id,
    required this.begriff,
    required this.definition,
    required this.beispiel,
    required this.kategorie,
    this.stufe = '',
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: (json['id'] ?? '').toString(),
      begriff: (json['begriff'] ?? '').toString(),
      definition: (json['definition'] ?? '').toString(),
      beispiel: (json['beispiel'] ?? '').toString(),
      kategorie: (json['kategorie'] ?? 'Allgemein').toString(),
      stufe: (json['stufe'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'begriff': begriff,
        'definition': definition,
        'beispiel': beispiel,
        'kategorie': kategorie,
        'stufe': stufe,
      };
}
