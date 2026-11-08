import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../services/supabase_service.dart';
import '../../services/guest_score_service.dart';
import '../owl_chat/owl_chat_screen.dart';
import 'quiz_results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String subject;

  const QuizScreen({super.key, this.subject = 'Calculus'});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 3; // Question 4 of 10
  final int _totalQuestions = 10;
  int? _selectedAnswerIndex = 1; // Default selected option B (2x) as in Figma prototype

  final List<String> _options = [
    'A • x',
    'B • 2x',
    'C • x²',
    'D • 2',
  ];

  void _showOwlHintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Image.asset(
              AppAssets.owlThinking,
              width: 36,
              height: 36,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Owl\'s Hint',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Remember the power rule: d/dx [xⁿ] = n · xⁿ⁻¹.\nHere n = 2, so bring 2 to the front and reduce the power by 1.',
          style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    if (_currentQuestionIndex + 1 < _totalQuestions) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
      });
    } else {
      // Save quiz score
      final user = SupabaseService.instance.currentUser;
      if (user == null) {
        await GuestScoreService.saveGuestScore(
          subject: widget.subject,
          score: 82,
          grade: 'Grade B',
        );
      } else {
        await GuestScoreService.saveGuestScore(
          subject: widget.subject,
          score: 82,
          grade: 'Grade B',
        );
        await GuestScoreService.migrateGuestScoresToAccount(user.id);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultsScreen(subject: widget.subject),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentQuestionIndex + 1) / _totalQuestions;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Back button & Owl Mascot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          widget.subject,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                        AppAssets.owlThinking,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                '${widget.subject} Quiz',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              // Progress details & Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of $_totalQuestions',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Text(
                    '04:32',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),

              const SizedBox(height: 24),

              // Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'What is the derivative of x²?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Options List
              ...List.generate(_options.length, (index) {
                final isSelected = _selectedAnswerIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAnswerIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentLight : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Text(
                        _options[index],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Clarification caption
              const Center(
                child: Text(
                  'Tap an answer to continue. No distractions, one question at a time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Next question button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _handleNext,
                  child: const Text(
                    'Next question →',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Ask Owl for a Hint
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.accentLight,
                    side: BorderSide(color: AppColors.accent.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _showOwlHintDialog,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lightbulb_outline, color: AppColors.accentDark, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ask Owl for a Hint',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
