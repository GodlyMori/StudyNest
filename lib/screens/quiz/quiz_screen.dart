import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../data/quiz_questions.dart';
import '../../models/quiz_question.dart';
import '../../services/supabase_service.dart';
import '../../services/guest_score_service.dart';
import '../../services/recommendation_engine.dart';
import '../../services/attempt_sync_service.dart';
import '../owl_chat/owl_chat_screen.dart';
import 'quiz_results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String subject;

  const QuizScreen({super.key, this.subject = 'Calculus'});

  static String calculateGrade(int score) {
    if (score >= 90) return 'Grade A';
    if (score >= 80) return 'Grade B';
    if (score >= 70) return 'Grade C';
    if (score >= 60) return 'Grade D';
    return 'Grade F';
  }

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  int _correctCount = 0;
  final Set<String> _strongTopics = {};
  final Set<String> _focusTopics = {};

  // Countdown timer: 04:32 (272 seconds)
  Timer? _countdownTimer;
  int _secondsRemaining = 272;
  bool _isFinishing = false;

  // Per-question tracking for V2 question_attempts logging
  final Stopwatch _questionStopwatch = Stopwatch();
  bool _hintUsedForCurrentQuestion = false;

  @override
  void initState() {
    super.initState();
    _questions = QuizQuestionBank.getQuestionsForSubject(widget.subject);
    _hintUsedForCurrentQuestion = false;
    _questionStopwatch
      ..reset()
      ..start();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _finishQuiz();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onOptionTapped(int index) {
    if (_isAnswered || _isFinishing) return;

    _questionStopwatch.stop();
    final timeTakenMs = _questionStopwatch.elapsedMilliseconds;
    final hintUsed = _hintUsedForCurrentQuestion;

    final question = _questions[_currentQuestionIndex];
    final isCorrect = (index == question.correctOptionIndex);

    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
      if (isCorrect) {
        _correctCount++;
        _strongTopics.add(question.topic);
      } else {
        _focusTopics.add(question.topic);
      }
    });

    // Record topic performance into recommendation engine
    RecommendationEngine.recordAnswer(
      subject: widget.subject,
      topic: question.topic,
      isCorrect: isCorrect,
    );

    // Log per-question attempt for V2 mastery / spaced repetition
    AttemptSyncService.logger.logAttempt(
      questionId: question.id,
      subject: question.subject,
      topic: question.topic,
      correct: isCorrect,
      timeTakenMs: timeTakenMs,
      hintUsed: hintUsed,
    );
  }

  void _showOwlHintDialog() {
    _hintUsedForCurrentQuestion = true;
    final question = _questions[_currentQuestionIndex];
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
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            const Text(
              'Owl\'s Hint',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Topic: ${question.topic}\n\n${question.explanation}',
          style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textDark),
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

  void _handleNext() {
    if (!_isAnswered) return;

    if (_currentQuestionIndex + 1 < _questions.length) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
        _hintUsedForCurrentQuestion = false;
      });
      _questionStopwatch
        ..reset()
        ..start();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    if (_isFinishing) return;
    _isFinishing = true;
    _countdownTimer?.cancel();

    final total = _questions.isEmpty ? 10 : _questions.length;
    final score = ((_correctCount / total) * 100).round();
    final grade = QuizScreen.calculateGrade(score);

    // Save completed quiz result (Phase 1 & Phase 2 contract)
    final user = SupabaseService.instance.currentUser;
    if (user == null) {
      await GuestScoreService.saveGuestScore(
        subject: widget.subject,
        score: score,
        grade: grade,
      );
    } else {
      await GuestScoreService.saveGuestScore(
        subject: widget.subject,
        score: score,
        grade: grade,
      );
      await GuestScoreService.migrateGuestScoresToAccount(user.id);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(
          subject: widget.subject,
          score: score,
          grade: grade,
          strongTopics: _strongTopics.toList(),
          focusTopics: _focusTopics.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No questions available.')),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final isLastQuestion = (_currentQuestionIndex + 1 == _questions.length);

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
                        AppAssets.owlSitting,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.school, color: AppColors.accent),
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

              // Progress details & Countdown Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimer(_secondsRemaining),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _secondsRemaining <= 30
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
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

              const SizedBox(height: 20),

              // Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.topic,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Options List with Instant Feedback (Figma frame 33)
              ...List.generate(question.options.length, (index) {
                final isSelected = (_selectedOptionIndex == index);
                final isCorrectOption = (index == question.correctOptionIndex);

                Color bgColor = Colors.white;
                Color borderColor = AppColors.border;
                Color textColor = AppColors.textDark;
                Widget? trailingIcon;

                if (_isAnswered) {
                  if (isCorrectOption) {
                    bgColor = AppColors.successLight;
                    borderColor = AppColors.success;
                    textColor = AppColors.textDark;
                    trailingIcon = const Icon(Icons.check_circle, color: AppColors.success, size: 20);
                  } else if (isSelected) {
                    bgColor = AppColors.errorLight;
                    borderColor = AppColors.error;
                    textColor = AppColors.error;
                    trailingIcon = const Icon(Icons.cancel, color: AppColors.error, size: 20);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _onOptionTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: borderColor,
                          width: (_isAnswered && (isCorrectOption || isSelected)) ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              question.options[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: (isSelected || (_isAnswered && isCorrectOption))
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (trailingIcon != null) trailingIcon,
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Correct/Wrong Explanation Banner (Figma frame 33)
              if (_isAnswered) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (_selectedOptionIndex == question.correctOptionIndex)
                        ? AppColors.successLight
                        : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_selectedOptionIndex == question.correctOptionIndex)
                          ? AppColors.success.withOpacity(0.4)
                          : AppColors.error.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (_selectedOptionIndex == question.correctOptionIndex)
                                ? Icons.check_circle
                                : Icons.info_outline,
                            size: 18,
                            color: (_selectedOptionIndex == question.correctOptionIndex)
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (_selectedOptionIndex == question.correctOptionIndex)
                                ? 'Correct!'
                                : 'Incorrect',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (_selectedOptionIndex == question.correctOptionIndex)
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        question.explanation,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Next question / Finish button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnswered ? AppColors.backgroundDark : AppColors.border,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isAnswered ? _handleNext : null,
                  child: Text(
                    isLastQuestion ? 'Finish Quiz →' : 'Next question →',
                    style: const TextStyle(
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
