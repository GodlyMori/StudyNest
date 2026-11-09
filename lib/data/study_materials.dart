import '../models/study_material.dart';

class StudyMaterialBank {
  static const List<StudyMaterial> defaultMaterials = [
    StudyMaterial(
      id: 'mat_derivatives',
      title: 'Derivatives Cheat Sheet',
      category: 'Maths',
      meta: 'Maths • 8 min • Easy',
      content:
          'Key formulas: d/dx(c) = 0, d/dx(x^n) = n*x^(n-1), Product rule: (uv)\' = u\'v + uv\', Quotient rule: (u/v)\' = (u\'v - uv\')/v².',
    ),
    StudyMaterial(
      id: 'mat_cell_structure',
      title: 'Cell Structure Notes',
      category: 'Science',
      meta: 'Science • 12 min • Medium',
      content:
          'Eukaryotic cells contain membrane-bound organelles: Nucleus (houses DNA), Mitochondria (ATP production), Ribosomes (protein synthesis).',
    ),
    StudyMaterial(
      id: 'mat_ww2_timeline',
      title: 'WW2 Timeline',
      category: 'History',
      meta: 'History • 10 min • Easy',
      content:
          '1939: Outbreak of war with Poland invasion; 1941: Pearl Harbor; 1944: D-Day Normandy landings; 1945: Victory in Europe and Pacific.',
    ),
    StudyMaterial(
      id: 'mat_calculus_integrals',
      title: 'Calculus Integral Tables',
      category: 'Maths',
      meta: 'Maths • 15 min • Hard',
      content:
          'Integration formulas for trigonometric, exponential, and polynomial functions.',
    ),
  ];

  static List<StudyMaterial> getMaterials() {
    return List<StudyMaterial>.from(defaultMaterials);
  }

  static StudyMaterial? getById(String id) {
    try {
      return defaultMaterials.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
