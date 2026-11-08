import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';

class OwlChatScreen extends StatefulWidget {
  const OwlChatScreen({super.key});

  @override
  State<OwlChatScreen> createState() => _OwlChatScreenState();
}

class _OwlChatScreenState extends State<OwlChatScreen> {
  final _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isOwl': true,
      'text': 'Hi Alvin! Stuck on derivatives? I can explain it in 2 minutes.',
    },
    {
      'isOwl': false,
      'text': 'Explain Pythagorean theorem',
    },
    {
      'isOwl': true,
      'text': 'Sure — a² + b² = c². In any right-angled triangle, the square of the hypotenuse equals the sum of the squares of the other two sides. Want a practice problem next?',
    },
  ];

  final List<String> _suggestions = [
    'Explain Pythagorean theorem',
    'Give me a practice problem',
    'Summarize today\'s session',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isOwl': false,
        'text': text,
      });
      _controller.clear();
    });

    // Simulated Owl AI intelligent reply
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isOwl': true,
          'text': 'Here\'s what you need to know for that: Focus on the fundamental rules and practice with 2-3 quick questions. Ready to begin?',
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Image.asset(
                AppAssets.owlThinking,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Owl — Study Buddy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  ..._messages.map((msg) {
                    final isOwl = msg['isOwl'] as bool;
                    final text = msg['text'] as String;

                    if (isOwl) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    }
                  }),

                  const SizedBox(height: 16),

                  // Quick Suggestion Chips
                  const Text(
                    'Quick prompts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._suggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () => _sendMessage(suggestion),
                        child: Container(
                          width: double.infinity,
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Input bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Ask Owl anything…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                        onSubmitted: (text) => _sendMessage(text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(_controller.text),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.textDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
