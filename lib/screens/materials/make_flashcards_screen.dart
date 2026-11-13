import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/flashcard.dart';
import '../../models/study_material.dart';
import '../../ml/flashcard_parser.dart';
import '../../services/flashcard_service.dart';

class MakeFlashcardsScreen extends StatefulWidget {
  final StudyMaterial material;

  const MakeFlashcardsScreen({
    super.key,
    required this.material,
  });

  @override
  State<MakeFlashcardsScreen> createState() => _MakeFlashcardsScreenState();
}

class _MakeFlashcardsScreenState extends State<MakeFlashcardsScreen> {
  late List<_CardDraft> _cards;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final parsed = FlashcardParser.parse(
      widget.material.content,
      title: widget.material.title,
    );

    _cards = parsed
        .map(
          (c) => _CardDraft(
            frontController: TextEditingController(text: c.front),
            backController: TextEditingController(text: c.back),
            isSelected: true,
          ),
        )
        .toList();

    // If parser returned nothing, provide one empty draft
    if (_cards.isEmpty) {
      _cards.add(
        _CardDraft(
          frontController: TextEditingController(text: widget.material.title),
          backController: TextEditingController(),
          isSelected: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final card in _cards) {
      card.dispose();
    }
    super.dispose();
  }

  void _addCard() {
    setState(() {
      _cards.add(
        _CardDraft(
          frontController: TextEditingController(),
          backController: TextEditingController(),
          isSelected: true,
        ),
      );
    });
  }

  void _removeCard(int index) {
    setState(() {
      _cards[index].dispose();
      _cards.removeAt(index);
    });
  }

  Future<void> _saveCards() async {
    final selectedDrafts = _cards.where((c) => c.isSelected).toList();
    final validDrafts = selectedDrafts
        .where((c) =>
            c.frontController.text.trim().isNotEmpty &&
            c.backController.text.trim().isNotEmpty)
        .toList();

    if (validDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one card with front and back text.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now().toUtc();
    final newCards = <Flashcard>[];

    for (var i = 0; i < validDrafts.length; i++) {
      final draft = validDrafts[i];
      final id =
          'card_${widget.material.id}_${now.millisecondsSinceEpoch}_$i';
      newCards.add(
        Flashcard(
          id: id,
          materialId: widget.material.id,
          front: draft.frontController.text.trim(),
          back: draft.backController.text.trim(),
          createdAt: now,
          updatedAt: now,
          nextReviewAt: now, // immediately due for initial learning
        ),
      );
    }

    await FlashcardService.saveFlashcards(newCards);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${newCards.length} flashcards!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _cards.where((c) => c.isSelected).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make Flashcards',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Add manual card',
            icon: const Icon(Icons.add, color: AppColors.textDark),
            onPressed: _addCard,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Text(
                'Review parsed cards for "${widget.material.title}". Edit, discard, or add your own cards before saving.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Card list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final draft = _cards[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: draft.isSelected ? Colors.white : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: draft.isSelected
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.border,
                        width: draft.isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: draft.isSelected,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  draft.isSelected = val ?? true;
                                });
                              },
                            ),
                            Text(
                              'Card ${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: draft.isSelected
                                    ? AppColors.textDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 20),
                              tooltip: 'Discard card',
                              onPressed: () => _removeCard(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: draft.frontController,
                          enabled: draft.isSelected,
                          decoration: InputDecoration(
                            labelText: 'Front (Prompt / Term / Formula)',
                            labelStyle: const TextStyle(fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: draft.backController,
                          enabled: draft.isSelected,
                          decoration: InputDecoration(
                            labelText: 'Back (Definition / Answer / Value)',
                            labelStyle: const TextStyle(fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          maxLines: null,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _addCard,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ Card'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('save_flashcards_button'),
                      onPressed: _isSaving ? null : _saveCards,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save $selectedCount Cards',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDraft {
  final TextEditingController frontController;
  final TextEditingController backController;
  bool isSelected;

  _CardDraft({
    required this.frontController,
    required this.backController,
    this.isSelected = true,
  });

  void dispose() {
    frontController.dispose();
    backController.dispose();
  }
}
