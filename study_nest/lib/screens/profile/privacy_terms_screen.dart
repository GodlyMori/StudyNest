import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Privacy & Terms info screen.
class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Privacy & Terms',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
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
                  children: const [
                    Text(
                      'StudyNest',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Version 1.0.0 • Production Build',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 1: Privacy Summary
              _buildSection(
                title: 'Data & Privacy Summary',
                icon: Icons.privacy_tip_outlined,
                content:
                    'StudyNest values student privacy. We only collect the minimal information necessary to deliver adaptive quizzes, study sessions, and peer study groups.',
              ),

              const SizedBox(height: 16),

              // Section 2: Where Your Data is Stored
              _buildSection(
                title: 'Storage & Syncing',
                icon: Icons.cloud_outlined,
                content:
                    '• Profile & Quiz Scores: Stored in Supabase Postgres database protected by Row Level Security (RLS) policies. Only authenticated members can view profiles and participate in groups.\n\n'
                    '• Offline Downloads & Cache: Stored strictly on your local device using secure local storage. Saved offline materials work without wifi.\n\n'
                    '• Study Planner & Reminders: Scheduled sessions and local device notifications are managed entirely on your device with no remote analytics tracking.',
              ),

              const SizedBox(height: 16),

              // Section 3: Terms of Use
              _buildSection(
                title: 'Terms of Service',
                icon: Icons.description_outlined,
                content:
                    'StudyNest is designed as an educational companion app. All quizzes, flashcards, and cheat sheets are provided for learning and exam preparation purposes. Respect other members in public study groups and maintain academic integrity.',
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  '© 2026 StudyNest. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
