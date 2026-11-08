import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../data/study_materials.dart';
import '../../models/study_material.dart';
import '../../services/material_download_service.dart';
import '../owl_chat/owl_chat_screen.dart';
import 'material_detail_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Maths', 'Science', 'History'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _downloadedIds = {};
  bool _isLoading = true;

  final List<StudyMaterial> _materials = StudyMaterialBank.getMaterials();

  @override
  void initState() {
    super.initState();
    _loadDownloadedStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDownloadedStatus() async {
    final ids = await MaterialDownloadService.getDownloadedIds();
    if (mounted) {
      setState(() {
        _downloadedIds = ids.toSet();
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  Future<void> _openMaterialDetail(StudyMaterial material) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialDetailScreen(material: material),
      ),
    );
    await _loadDownloadedStatus();
  }

  Future<void> _toggleDownload(StudyMaterial material) async {
    final isDownloaded = _downloadedIds.contains(material.id);
    if (isDownloaded) {
      await MaterialDownloadService.removeDownloadedMaterial(material.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from offline downloads'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await MaterialDownloadService.downloadMaterial(material);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloaded for offline use'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
    await _loadDownloadedStatus();
  }

  bool _matchesQuery(StudyMaterial m, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return m.title.toLowerCase().contains(q) ||
        m.category.toLowerCase().contains(q) ||
        m.meta.toLowerCase().contains(q) ||
        m.content.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final filteredMaterials = _materials.where((m) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          m.category == _categories[_selectedCategoryIndex];
      final matchesSearch = _matchesQuery(m, _searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

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
                        MaterialPageRoute(
                          builder: (context) => const OwlChatScreen(),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Image.asset(
                        AppAssets.owlReading,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Working Search Bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search notes, cheat sheets…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 18,
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
                            color: isSelected
                                ? AppColors.backgroundDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _categories[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // Materials List or No-Results State
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (filteredMaterials.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.border.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No materials match your search',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting your search query or switching categories.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _clearSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Clear search'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredMaterials.map((material) {
                  final isDownloaded = _downloadedIds.contains(material.id);
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
                                      material.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      material.meta,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isDownloaded
                                        ? 'Downloaded'
                                        : 'Needs Internet',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDownloaded
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: isDownloaded
                                        ? 'Downloaded (Tap to remove)'
                                        : 'Download offline',
                                    icon: Icon(
                                      isDownloaded
                                          ? Icons.check_circle
                                          : Icons.download_outlined,
                                      size: 20,
                                      color: isDownloaded
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                    ),
                                    onPressed: () => _toggleDownload(material),
                                  ),
                                ],
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
