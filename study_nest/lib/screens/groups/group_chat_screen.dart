import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupName;

  const GroupChatScreen({super.key, this.groupName = 'Calculus Crew'});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Maya',
      'text': 'Did anyone solve Q4 on the derivative of x²?',
      'isMe': false,
      'isOwl': false,
      'time': '10:24 AM',
    },
    {
      'sender': 'Owl (Study Buddy)',
      'text': 'Hint: Use the power rule! Bring the exponent down: d/dx(x²) = 2x.',
      'isMe': false,
      'isOwl': true,
      'time': '10:25 AM',
    },
    {
      'sender': 'Lucas',
      'text': 'Ah that makes sense now! Thanks Owl 🦉',
      'isMe': false,
      'isOwl': false,
      'time': '10:27 AM',
    },
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'You',
        'text': text,
        'isMe': true,
        'isOwl': false,
        'time': 'Just now',
      });
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const Text(
              '12 members • 3 online',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;
                final isOwl = msg['isOwl'] as bool;

                if (isOwl) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          AppAssets.owlThinking,
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.school, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['sender'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg['text'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          Text(
                            msg['sender'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          msg['text'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? AppColors.textDark : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? AppColors.textDark.withOpacity(0.6) : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message…',
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: AppColors.textDark),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
