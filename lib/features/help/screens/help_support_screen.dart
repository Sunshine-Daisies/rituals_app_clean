import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rituals_app/theme/app_theme.dart';
import '../../../services/onboarding_service.dart';
import '../../../providers/theme_provider.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  // To track which FAQ tile is expanded. For simplicity, we allow multiple expanded.
  final Set<int> _expandedFaqs = {};

  void _toggleFaq(int index) {
    setState(() {
      if (_expandedFaqs.contains(index)) {
        _expandedFaqs.remove(index);
      } else {
        _expandedFaqs.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground1
          : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Header Text
            Text(
              'How can we help\nyou today?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: TextField(
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search FAQs, guides, and more',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : AppTheme.lightTextSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark
                        ? Colors.white54
                        : AppTheme.lightTextSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Category Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildCategoryCard(
                  Icons.account_circle,
                  'Account',
                  Colors.cyan,
                ),
                _buildCategoryCard(
                  Icons.local_fire_department,
                  'Streaks',
                  Colors.orange,
                ),
                _buildCategoryCard(Icons.payment, 'Billing', Colors.blue),
                _buildCategoryCard(
                  Icons.sports_esports,
                  'Gamification',
                  Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tip of the Day Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0097B2), Color(0xFF00ACC1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'TIP OF THE DAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 5 XP added to your progress!'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Claim 5 XP',
                            style: TextStyle(
                              color: Color(0xFF0097B2),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Looking to boost your XP? Completing a ritual before 9 AM doubles your consistency score!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Top Questions
            Text(
              'Top Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQTile(
              index: 0,
              title: 'How do I restore my streak?',
              content:
                  'You can restore a broken streak once a month if you have a Premium subscription. Simply go to the ritual details and tap the "Restore" button within 24 hours of losing it.',
            ),
            _buildFAQTile(
              index: 1,
              title: 'Inviting friends to a Ritual',
              content:
                  'Tap the "Invite" button on any Ritual card to generate a unique code. Your friends can enter this code in the "Join Ritual" section to track habits together.',
            ),
            _buildFAQTile(
              index: 2,
              title: 'Understanding XP and Levels',
              content:
                  'XP is earned by completing rituals daily. Bonus XP is awarded for long streaks and early morning rituals. Collecting XP increases your level and unlocks new titles.',
            ),
            const SizedBox(height: 32),

            // Onboarding Replay Button
            _buildOnboardingButton(context),
            const SizedBox(height: 32),
            const SizedBox(height: 40),

            // Still need help section
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic,
                      color: Colors.cyan,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Still need help?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our team is available 24/7 to assist you.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white54
                          : AppTheme.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Support chat initializing...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble, size: 18),
                      label: const Text('Chat with Support (Coming Soon)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Category: $label selected.')));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile({
    required int index,
    required String title,
    required String content,
  }) {
    final isExpanded = _expandedFaqs.contains(index);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isDark ? Colors.white54 : AppTheme.lightTextSecondary,
            ),
            onTap: () => _toggleFaq(index),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                content,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnboardingButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.cyan),
        title: const Text(
          'Replay App Introduction',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.cyan,
          ),
        ),
        subtitle: Text(
          'New here? See how everything works again.',
          style: TextStyle(
            color: isDark ? Colors.white54 : AppTheme.lightTextSecondary,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.play_arrow, color: Colors.cyan),
        onTap: () async {
          // Reset onboarding state
          await OnboardingService.resetOnboarding();
          if (context.mounted) {
            context.go('/onboarding');
          }
        },
      ),
    );
  }
}
