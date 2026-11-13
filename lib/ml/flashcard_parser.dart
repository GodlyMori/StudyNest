/// Represents a candidate flashcard extracted from structured text.
class CandidateFlashcard {
  final String front;
  final String back;
  final bool isSelected;

  const CandidateFlashcard({
    required this.front,
    required this.back,
    this.isSelected = true,
  });

  CandidateFlashcard copyWith({
    String? front,
    String? back,
    bool? isSelected,
  }) {
    return CandidateFlashcard(
      front: front ?? this.front,
      back: back ?? this.back,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandidateFlashcard &&
          runtimeType == other.runtimeType &&
          front == other.front &&
          back == other.back;

  @override
  int get hashCode => front.hashCode ^ back.hashCode;
}

/// Pure Dart parser that extracts flashcards from structured text
/// without any AI/LLM call.
class FlashcardParser {
  FlashcardParser._();

  /// Parses [content] into a list of candidate flashcards.
  /// [title] is optional fallback context if the text lacks delimiters.
  static List<CandidateFlashcard> parse(String content, {String? title}) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const [];

    final results = <CandidateFlashcard>[];
    final seenFronts = <String>{};

    void addCandidate(String front, String back) {
      final cleanFront = _cleanText(front);
      final cleanBack = _cleanText(back);
      if (cleanFront.length >= 2 &&
          cleanBack.length >= 2 &&
          !seenFronts.contains(cleanFront.toLowerCase())) {
        seenFronts.add(cleanFront.toLowerCase());
        results.add(CandidateFlashcard(front: cleanFront, back: cleanBack));
      }
    }

    // 1. Semicolon-delimited clauses (e.g. WW2 timeline or semicolon lists)
    if (trimmed.contains(';')) {
      final parts = trimmed.split(';');
      for (final part in parts) {
        if (part.contains(':')) {
          final idx = part.indexOf(':');
          final f = part.substring(0, idx);
          final b = part.substring(idx + 1);
          addCandidate(f, b);
        } else if (part.contains(' - ')) {
          final idx = part.indexOf(' - ');
          final f = part.substring(0, idx);
          final b = part.substring(idx + 3);
          addCandidate(f, b);
        }
      }
    }

    // 2. Parenthesized terms: e.g. "Nucleus (houses DNA), Mitochondria (ATP production)"
    final parenRegex = RegExp(r"([A-Za-z0-9\s_\-\/\^'*]+?)\s*\(([^()]+)\)");
    final parenMatches = parenRegex.allMatches(trimmed);
    for (final match in parenMatches) {
      var f = match.group(1)?.trim() ?? '';
      final b = match.group(2)?.trim() ?? '';

      // If front contains a sentence/clause prefix with a colon, take the part after the colon
      if (f.contains(':')) {
        f = f.split(':').last.trim();
      }
      // If front starts with a comma or list marker, strip it
      if (f.startsWith(',') || f.startsWith('•') || f.startsWith('-')) {
        f = f.substring(1).trim();
      }

      // Filter out mathematical expressions like d/dx(x^n) where parens are math arguments
      final isMathParen = f.contains('/') || f.endsWith('d') || f.contains('=');
      if (!isMathParen && f.isNotEmpty && b.isNotEmpty) {
        addCandidate(f, b);
      }
    }

    // 3. Mathematical equations / rules with `=` or `:`
    // e.g. "Product rule: (uv)' = u'v + uv'"
    final ruleRegex = RegExp(r"([A-Za-z0-9\s_\-'\/]+):\s*([^,;]+)");
    for (final match in ruleRegex.allMatches(trimmed)) {
      final f = match.group(1)?.trim() ?? '';
      final b = match.group(2)?.trim() ?? '';
      // Avoid adding large headers like "Key formulas" unless they have distinct values
      if (!f.toLowerCase().startsWith('key formulas') &&
          !f.toLowerCase().startsWith('note') &&
          !f.toLowerCase().startsWith('chapter')) {
        addCandidate(f, b);
      }
    }

    // Equations like d/dx(c) = 0 or (uv)' = u'v + uv'
    final eqRegex = RegExp(r"([a-zA-Z0-9\s_\-\/\^'*\(\)]+)\s*=\s*([^,;]+)");
    for (final match in eqRegex.allMatches(trimmed)) {
      final f = match.group(1)?.trim() ?? '';
      final b = match.group(2)?.trim() ?? '';
      // Filter out if f is too long (likely full sentence)
      if (f.length < 35 && b.length < 50 && f.isNotEmpty && b.isNotEmpty) {
        // Strip leading markers
        var cleanF = f;
        if (cleanF.toLowerCase().contains('formulas:')) {
          cleanF = cleanF.split(':').last.trim();
        }
        addCandidate(cleanF, b);
      }
    }

    // 4. Fallback if no structured pairs were found:
    if (results.isEmpty) {
      // Split into sentences
      final sentences = trimmed
          .split(RegExp(r'\. |\.\n|\n'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (var i = 0; i < sentences.length; i++) {
        final sentence = sentences[i];
        final frontLabel = title != null
            ? (sentences.length > 1 ? '$title (Pt ${i + 1})' : title)
            : 'Key Concept';
        addCandidate(frontLabel, sentence);
      }
    }

    return results;
  }

  static String _cleanText(String text) {
    var cleaned = text.trim();
    // Remove leading punctuation / dashes
    cleaned = cleaned.replaceFirst(RegExp(r'^[\s,;:•\-\–]+'), '');
    // Remove trailing punctuation
    cleaned = cleaned.replaceFirst(RegExp(r'[\s,;]+$'), '');
    return cleaned.trim();
  }
}
