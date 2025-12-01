import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Greeting
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreetingMessage(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getMotivationalMessage(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Vertical Action Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _VerticalActionCard(
                        icon: Icons.psychology,
                        title: 'My Rituals',
                        subtitle: 'View and manage your daily habits',
                        color: Colors.purple,
                        onTap: () => context.go('/rituals'),
                      ),
                      const SizedBox(height: 16),
                      _VerticalActionCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'AI Chat',
                        subtitle: 'Get suggestions and motivation',
                        color: Colors.indigo,
                        onTap: () => context.go('/llm-chat'),
                      ),
                      const SizedBox(height: 16),
                      _VerticalActionCard(
                        icon: Icons.add_circle_outline,
                        title: 'New Ritual',
                        subtitle: 'Add a new habit to your list',
                        color: Colors.teal,
                        onTap: () => context.go('/ritual/create'),
                      ),
                      const SizedBox(height: 16),
                      _VerticalActionCard(
                        icon: Icons.people_alt_outlined,
                        title: 'Join Ritual',
                        subtitle: 'Partner up with friends',
                        color: Colors.orange,
                        onTap: () => context.go('/join-ritual'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBackground1,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  isActive: true,
                  onTap: () {},
                ),
                _BottomNavItem(
                  icon: Icons.people,
                  label: 'Friends',
                  isActive: false,
                  onTap: () => context.go('/friends'),
                ),
                _BottomNavItem(
                  icon: Icons.bar_chart,
                  label: 'Statistics',
                  isActive: false,
                  onTap: () => context.go('/stats'),
                ),
                _BottomNavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  isActive: false,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night,';
    }
  }

  String _getMotivationalMessage() {
    final messages = [
      '✨ Every small step builds great habits',
      '🌟 Today is a perfect day to grow',
      '🚀 Your future self will thank you',
      '💪 Consistency is your superpower',
      '🎯 Small habits, big transformations',
      '🌱 Progress, not perfection',
      '⭐ You\'re building something amazing',
      '🔥 Keep your momentum going',
      '🌈 Every ritual shapes your destiny',
      '💎 Excellence is a daily habit',
    ];
    
    // Saate göre farklı mesaj kategorileri de ekleyebiliriz
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      // Sabah motivasyonu
      return messages[(DateTime.now().millisecondsSinceEpoch % 3)];
    } else if (hour >= 12 && hour < 17) {
      // Öğlen motivasyonu
      return messages[3 + (DateTime.now().millisecondsSinceEpoch % 3)];
    } else if (hour >= 17 && hour < 21) {
      // Akşam motivasyonu
      return messages[6 + (DateTime.now().millisecondsSinceEpoch % 2)];
    } else {
      // Gece motivasyonu
      return messages[8 + (DateTime.now().millisecondsSinceEpoch % 2)];
    }
  }
}

class _VerticalActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _VerticalActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.blue : Colors.white54,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.blue : Colors.white54,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
