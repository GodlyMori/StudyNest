import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/flashcard.dart';
import '../../services/flashcard_service.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String title;
  final List<Flashcard> cards;

  const FlashcardStudyScreen({
    super.key,
    required this.title,
    required this.cards,
  });

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  int _reviewedCount = 0;

  void _flip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  Future<void> _score(int quality) async {
    final card = widget.cards[_currentIndex];
    await FlashcardService.recordReview(cardId: card.id, quality: quality);
    _reviewedCount++;

    if (_currentIndex + 1 < widget.cards.length) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Review Complete!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You reviewed $_reviewedCount flashcard${_reviewedCount == 1 ? '' : 's'}. Next intervals scheduled via SM-2.',
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context, true); // exit review
            },
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No flashcards to review right now!'),
        ),
      );
    }

    final card = widget.cards[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.title} (${_currentIndex + 1}/${widget.cards.length})',
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.cards.length,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 24),

              // Interactive Flip Card
              Expanded(
                child: GestureDetector(
                  key: const Key('flashcard_flip_target'),
                  onTap: _flip,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isFlipped ? AppColors.accent : AppColors.border,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isFlipped
                                ? AppColors.accent.withOpacity(0.12)
                                : AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isFlipped ? 'ANSWER / BACK' : 'QUESTION / FRONT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: _isFlipped
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Text(
                                _isFlipped ? card.back : card.front,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 16,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isFlipped
                                  ? 'Tap to see prompt'
                                  : 'Tap card to reveal answer',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Rating Buttons (SM-2 quality grades)
              if (_isFlipped)
                Column(
                  children: [
                    const Text(
                      'How well did you remember?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildGradeButton(
                          label: 'Again',
                          sub: 'Reset',
                          quality: 1,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        _buildGradeButton(
                          label: 'Hard',
                          sub: '+1d',
                          quality: 3,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _buildGradeButton(
                          label: 'Good',
                          sub: 'Normal',
                          quality: 4,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        _buildGradeButton(
                          label: 'Easy',
                          sub: 'Longer',
                          quality: 5,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _flip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Show Answer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeButton({
    required String label,
    required String sub,
    required int quality,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _score(quality),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
