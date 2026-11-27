import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/streak_service.dart';
import '../../services/supabase_service.dart';
import '../auth/welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'privacy_terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _keyPushNotifications = 'settings_push_notifications';
  static const String _keyStudyReminders = 'settings_study_reminders';
  static const String _keySoundEffects = 'settings_sound_effects';
  static const String _keyHiddenFromSearch = 'settings_hidden_from_search';

  bool _pushNotifications = true;
  bool _studyReminders = true;
  bool _soundEffects = true;
  bool _hiddenFromSearch = false;
  bool _isSavingHidden = false;
  int _dailyGoal = 1;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final goal = await StreakService.getDailyGoal();
    final cachedHidden = prefs.getBool(_keyHiddenFromSearch) ?? false;
    bool hiddenFromSearch = cachedHidden;

    final user = SupabaseService.instance.currentUser;
    if (user != null && SupabaseService.instance.isInitialized) {
      try {
        final profile = await SupabaseService.instance.getProfile(user.id);
        if (profile != null && profile.containsKey('hidden_from_search')) {
          hiddenFromSearch = profile['hidden_from_search'] as bool? ?? false;
          await prefs.setBool(_keyHiddenFromSearch, hiddenFromSearch);
        }
      } catch (e) {
        debugPrint('Note loading hidden_from_search: $e');
      }
    }

    if (mounted) {
      setState(() {
        _pushNotifications = prefs.getBool(_keyPushNotifications) ?? true;
        _studyReminders = prefs.getBool(_keyStudyReminders) ?? true;
        _soundEffects = prefs.getBool(_keySoundEffects) ?? true;
        _dailyGoal = goal;
        _hiddenFromSearch = hiddenFromSearch;
      });
    }
  }

  Future<void> _setPushNotifications(bool val) async {
    setState(() => _pushNotifications = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushNotifications, val);
  }

  Future<void> _setStudyReminders(bool val) async {
    setState(() => _studyReminders = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStudyReminders, val);
  }

  Future<void> _setSoundEffects(bool val) async {
    setState(() => _soundEffects = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEffects, val);
  }

  // Honest limitation:
  // The public.profiles SELECT RLS policy is broad (using (true) - any
  // authenticated user can read profile rows). This toggle hides the user from
  // Find Users SEARCH RESULTS only; it does not make the row unreadable by
  // direct ID lookup.
  Future<void> _setHiddenFromSearch(bool val) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;

    final prev = _hiddenFromSearch;
    setState(() {
      _hiddenFromSearch = val;
      _isSavingHidden = true;
    });

    try {
      await SupabaseService.instance.updateProfile(
        userId: user.id,
        hiddenFromSearch: val,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHiddenFromSearch, val);
      if (mounted) {
        setState(() {
          _isSavingHidden = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hiddenFromSearch = prev;
          _isSavingHidden = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update privacy setting: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out of StudyNest?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await SupabaseService.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: Semantics(
          button: true,
          label: 'Back',
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),

            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive reminders for quiz goals and streaks',
              value: _pushNotifications,
              onChanged: _setPushNotifications,
            ),
            const SizedBox(height: 6),

            _buildSwitchTile(
              title: 'Study Reminders',
              subtitle: 'Daily check-in alerts from Owl',
              value: _studyReminders,
              onChanged: _setStudyReminders,
            ),
            const SizedBox(height: 6),

            _buildSwitchTile(
              title: 'Sound & Mascot Effects',
              subtitle: 'Audio cues during assessments',
              value: _soundEffects,
              onChanged: _setSoundEffects,
            ),
            const SizedBox(height: 6),

            Builder(
              builder: (context) {
                final isGuest = SupabaseService.instance.currentUser == null;
                return _buildSwitchTile(
                  title: 'Hide me from search',
                  subtitle: isGuest
                      ? 'Available for signed-in accounts'
                      : 'Prevent your profile from appearing in Find Users search',
                  value: _hiddenFromSearch,
                  onChanged: (isGuest || _isSavingHidden) ? null : _setHiddenFromSearch,
                  switchKey: const Key('hide_from_search_switch'),
                );
              },
            ),

            const SizedBox(height: 16),

            const Text(
              'Account & Security',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),

            _buildActionTile(
              title: 'Edit Profile',
              icon: Icons.person_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
            ),
            const SizedBox(height: 6),

            _buildActionTile(
              title: 'Change Password',
              icon: Icons.lock_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
            const SizedBox(height: 6),

            _buildActionTile(
              title: 'Privacy & Terms',
              icon: Icons.shield_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyTermsScreen()),
                );
              },
            ),
            const SizedBox(height: 6),

            _buildDailyGoalTile(),

            const SizedBox(height: 24),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Semantics(
                button: true,
                label: 'Log Out',
                excludeSemantics: true,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _handleLogout,
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Delete Account Button (Figma frame 45, below Log Out)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Semantics(
                button: true,
                label: 'Delete Account',
                excludeSemantics: true,
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DeleteAccountScreen()),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            Center(
              child: Text(
                'StudyNest v1.0.0 • Made with Flutter',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalTile() {
    return Semantics(
      label: 'Daily Quiz Goal: $_dailyGoal ${_dailyGoal == 1 ? "quiz" : "quizzes"} per day',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Quiz Goal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target: $_dailyGoal ${_dailyGoal == 1 ? "quiz" : "quizzes"} per day',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            DropdownButton<int>(
              key: const Key('daily_goal_dropdown'),
              value: _dailyGoal,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 quiz')),
                DropdownMenuItem(value: 2, child: Text('2 quizzes')),
                DropdownMenuItem(value: 3, child: Text('3 quizzes')),
                DropdownMenuItem(value: 5, child: Text('5 quizzes')),
              ],
              onChanged: (newGoal) async {
                if (newGoal != null) {
                  setState(() => _dailyGoal = newGoal);
                  await StreakService.setDailyGoal(newGoal);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Key? switchKey,
  }) {
    return Semantics(
      button: true,
      label: '$title toggle',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              key: switchKey,
              value: value,
              activeColor: AppColors.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: 'Open $title',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(icon, color: AppColors.textDark),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
