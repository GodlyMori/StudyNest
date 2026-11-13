import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../data/quiz_questions.dart';
import '../../models/quiz_question.dart';
import 'quiz_screen.dart';

/// Custom Quiz Setup Screen (Task 5.2).
///
/// Allows students to build a targeted quiz configuration:
/// - Subject (Calculus, Biology, History, Physics)
/// - Topic(s) within subject (multi-select, or "All topics")
/// - Number of questions (presets: 5, 10, 15, 20)
/// - Difficulty: Any (default), Easy (1), Medium (2), Hard (3)
///
/// Filters the bank adaptively. If fewer questions match than requested,
/// it serves all available matching questions without repeats and displays
/// a clean notice banner.
class CustomQuizScreen extends StatefulWidget {
  const CustomQuizScreen({super.key});

  @override
  State<CustomQuizScreen> createState() => _CustomQuizScreenState();
}

class _CustomQuizScreenState extends State<CustomQuizScreen> {
  static const List<String> subjects = [
    'Calculus',
    'Biology',
    'History',
    'Physics',
  ];

  static const List<int> lengthPresets = [5, 10, 15, 20];

  String _selectedSubject = 'Calculus';
  final Set<String> _selectedTopics = {};
  bool _isAllTopicsSelected = true;

  // null means "Any" difficulty; 1 = Easy, 2 = Medium, 3 = Hard
  int? _selectedDifficulty;

  int _selectedLength = 10;

  @override
  void initState() {
    super.initState();
    _resetTopicsForCurrentSubject();
  }

  void _resetTopicsForCurrentSubject() {
    final available = _getTopicsForSubject(_selectedSubject);
    _selectedTopics.clear();
    _selectedTopics.addAll(available);
    _isAllTopicsSelected = true;
  }

  List<String> _getTopicsForSubject(String subject) {
    final questions = QuizQuestionBank.getQuestionsForSubject(subject);
    final set = <String>{};
    for (final q in questions) {
      set.add(q.topic);
    }
    return set.toList()..sort();
  }

  List<QuizQuestion> _getFilteredQuestions() {
    final allForSubject = QuizQuestionBank.getQuestionsForSubject(_selectedSubject);
    return allForSubject.where((q) {
      // Topic filter
      if (!_isAllTopicsSelected && !_selectedTopics.contains(q.topic)) {
        return false;
      }
      // Difficulty filter
      if (_selectedDifficulty != null && q.difficulty != _selectedDifficulty) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final availableTopics = _getTopicsForSubject(_selectedSubject);
    final matchingQuestions = _getFilteredQuestions();
    final matchingCount = matchingQuestions.length;
    final effectiveCount = min(_selectedLength, matchingCount);
    final isPoolShort = matchingCount > 0 && matchingCount < _selectedLength;
    final isPoolEmpty = matchingCount == 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Custom Quiz',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              const Text(
                'Design Your Quiz',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Target specific topics and difficulty with adaptive selection.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // 1. Subject Selector
              _buildSectionTitle('Subject'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((subj) {
                  final isSelected = subj == _selectedSubject;
                  return ChoiceChip(
                    key: Key('custom_quiz_subject_$subj'),
                    label: Text(
                      subj,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.backgroundDark,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.backgroundDark : AppColors.border,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    onSelected: (selected) {
                      if (selected && _selectedSubject != subj) {
                        setState(() {
                          _selectedSubject = subj;
                          _resetTopicsForCurrentSubject();
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 2. Topics Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Topics'),
                  GestureDetector(
                    key: const Key('custom_quiz_toggle_all_topics'),
                    onTap: () {
                      setState(() {
                        if (_isAllTopicsSelected) {
                          _isAllTopicsSelected = false;
                          _selectedTopics.clear();
                        } else {
                          _isAllTopicsSelected = true;
                          _selectedTopics.addAll(availableTopics);
                        }
                      });
                    },
                    child: Text(
                      _isAllTopicsSelected ? 'Deselect All' : 'Select All',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // All Topics chip
                  FilterChip(
                    key: const Key('custom_quiz_all_topics'),
                    label: Text(
                      'All Topics',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isAllTopicsSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    selected: _isAllTopicsSelected,
                    selectedColor: AppColors.backgroundDark,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isAllTopicsSelected
                            ? AppColors.backgroundDark
                            : AppColors.border,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    onSelected: (selected) {
                      setState(() {
                        _isAllTopicsSelected = selected;
                        if (selected) {
                          _selectedTopics.addAll(availableTopics);
                        } else {
                          _selectedTopics.clear();
                        }
                      });
                    },
                  ),
                  ...availableTopics.map((topic) {
                    final isSelected = !_isAllTopicsSelected && _selectedTopics.contains(topic);
                    return FilterChip(
                      key: Key('custom_quiz_topic_$topic'),
                      label: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      onSelected: (selected) {
                        setState(() {
                          _isAllTopicsSelected = false;
                          if (selected) {
                            _selectedTopics.add(topic);
                            if (_selectedTopics.length == availableTopics.length) {
                              _isAllTopicsSelected = true;
                            }
                          } else {
                            _selectedTopics.remove(topic);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Difficulty Selector
              _buildSectionTitle('Difficulty'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildDifficultyChip(label: 'Any', value: null, keyName: 'any'),
                  _buildDifficultyChip(label: 'Easy only', value: 1, keyName: '1'),
                  _buildDifficultyChip(label: 'Medium only', value: 2, keyName: '2'),
                  _buildDifficultyChip(label: 'Hard only', value: 3, keyName: '3'),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Number of Questions
              _buildSectionTitle('Number of Questions'),
              const SizedBox(height: 8),
              Row(
                children: lengthPresets.map((length) {
                  final isSelected = _selectedLength == length;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        key: Key('custom_quiz_length_$length'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedLength = length;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.backgroundDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.backgroundDark : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$length Qs',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 5. Reactive Notice Banner
              Container(
                key: const Key('custom_quiz_notice_banner'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isPoolEmpty
                      ? AppColors.errorLight
                      : (isPoolShort ? AppColors.accentLight : AppColors.surfaceMuted),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPoolEmpty
                        ? AppColors.error
                        : (isPoolShort ? AppColors.accent : AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPoolEmpty
                          ? Icons.warning_amber_rounded
                          : (isPoolShort ? Icons.info_outline : Icons.check_circle_outline),
                      size: 20,
                      color: isPoolEmpty
                          ? AppColors.error
                          : (isPoolShort ? AppColors.accent : AppColors.success),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPoolEmpty
                            ? 'No questions match your filters. Please select more topics or another difficulty.'
                            : (isPoolShort
                                ? 'Only $matchingCount questions match your filters — running a $matchingCount-question quiz.'
                                : '$matchingCount questions available. Running a $_selectedLength-question adaptive quiz.'),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: isPoolEmpty
                              ? AppColors.error
                              : (isPoolShort ? AppColors.textDark : AppColors.textDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. Start Quiz Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('custom_quiz_start_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundDark,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isPoolEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                subject: _selectedSubject,
                                isAdaptive: true,
                                customPool: matchingQuestions,
                                targetQuestionCount: effectiveCount,
                              ),
                            ),
                          );
                        },
                  child: Text(
                    isPoolEmpty
                        ? 'No Questions Available'
                        : 'Start Quiz ($effectiveCount Qs) →',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildDifficultyChip({
    required String label,
    required int? value,
    required String keyName,
  }) {
    final isSelected = _selectedDifficulty == value;
    return ChoiceChip(
      key: Key('custom_quiz_difficulty_$keyName'),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.backgroundDark,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.backgroundDark : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDifficulty = value;
          });
        }
      },
    );
  }
}
