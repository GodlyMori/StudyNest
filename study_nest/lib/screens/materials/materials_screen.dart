import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../owl_chat/owl_chat_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Maths', 'Science', 'History'];

  final List<Map<String, dynamic>> _materials = [
    {
      'title': 'Derivatives Cheat Sheet',
      'category': 'Maths',
      'meta': 'Maths • 8 min • Easy',
      'status': 'Offline',
      'statusColor': AppColors.success,
      'content': 'Key formulas: d/dx(c) = 0, d/dx(x^n) = n*x^(n-1), Product rule: (uv)\' = u\'v + uv\', Quotient rule: (u/v)\' = (u\'v - uv\')/v².',
    },
    {
      'title': 'Cell Structure Notes',
      'category': 'Science',
      'meta': 'Science • 12 min • Medium',
      'status': 'Offline',
      'statusColor': AppColors.warning,
      'content': 'Eukaryotic cells contain membrane-bound organelles: Nucleus (houses DNA), Mitochondria (ATP production), Ribosomes (protein synthesis).',
    },
    {
      'title': 'WW2 Timeline',
      'category': 'History',
      'meta': 'History • 10 min • Easy',
      'status': 'Offline',
      'statusColor': AppColors.success,
      'content': '1939: Outbreak of war with Poland invasion; 1941: Pearl Harbor; 1944: D-Day Normandy landings; 1945: Victory in Europe and Pacific.',
    },
    {
      'title': 'Calculus Integral Tables',
      'category': 'Maths',
      'meta': 'Maths • 15 min • Hard',
      'status': 'Offline',
      'statusColor': AppColors.success,
      'content': 'Integration formulas for trigonometric, exponential, and polynomial functions.',
    },
  ];

  void _openMaterialDetail(Map<String, dynamic> material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    material['title'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (material['statusColor'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    material['status'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: material['statusColor'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              material['meta'] as String,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  material['content'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMaterials = _selectedCategoryIndex == 0
        ? _materials
        : _materials.where((m) => m['category'] == _categories[_selectedCategoryIndex]).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Study Materials',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OwlChatScreen()),
                      );
                    },
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Image.asset(
                        AppAssets.owlReading,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Search Bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search notes, cheat sheets…',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_categories.length, (index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.backgroundDark : Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _categories[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // Materials List
              ...filteredMaterials.map((material) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openMaterialDetail(material),
                      child: Container(
                        height: 84,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    material['meta'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              material['status'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: material['statusColor'] as Color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Bottom Notice
              const Center(
                child: Text(
                  'Saved offline files work without wifi.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
