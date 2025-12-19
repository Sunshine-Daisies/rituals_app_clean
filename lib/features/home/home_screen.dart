import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ritual.dart';
import '../../services/rituals_service.dart';
import '../../services/ritual_logs_service.dart';
import '../../services/partnership_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/bottom_nav_item.dart';
import 'widgets/empty_today_card.dart';
import 'widgets/pending_request_card.dart';
import 'widgets/today_partnership_card.dart';
import 'widgets/today_ritual_card.dart';
import '../../data/models/user_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GamificationService _gamificationService = GamificationService();
  late Future<List<Ritual>> _myRitualsFuture;
  late Future<List<Partnership>> _partnershipsFuture;
  late Future<List<PartnerRequest>> _pendingRequestsFuture;
  late Future<UserProfile?> _profileFuture;
  int _unreadNotificationCount = 0;
  
  // Bugün tamamlanan ritüeller (backend'den gelecek)
  Map<String, bool> _ritualCompletionStatus = {};
  Map<int, bool> _partnershipCompletionStatus = {};
  
  // Ritüel bazında zamanlayicilar
  Map<String, Timer?> _ritualTimers = {};
  Map<int, Timer?> _partnershipTimers = {};
  Timer? _notificationTimer;
  
  String get _todayShort {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[DateTime.now().weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    _loadRituals();
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadUnreadNotifications());
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    // Tüm timer'ları iptal et
    _ritualTimers.values.forEach((timer) => timer?.cancel());
    _partnershipTimers.values.forEach((timer) => timer?.cancel());
    super.dispose();
  }

  void _loadRituals() {
    final ritualsFuture = _fetchRitualsWithStatus();
    final partnershipsFuture = _fetchPartnershipsWithStatus();
    final profileFuture = _gamificationService.getMyProfile();
    
    setState(() {
      _myRitualsFuture = ritualsFuture;
      _partnershipsFuture = partnershipsFuture;
      _pendingRequestsFuture = PartnershipService.getPendingRequests();
      _profileFuture = profileFuture;
    });
    
    _loadUnreadNotifications();
    
    // Timer'ları kurmak için verilerin gelmesini bekle
    Future.wait([ritualsFuture, partnershipsFuture]).then((results) {
      if (mounted) {
        final rituals = results[0] as List<Ritual>;
        final partnerships = results[1] as List<Partnership>;
        _scheduleRitualRefreshTimers(rituals, partnerships);
      }
    });
  }

  Future<List<Ritual>> _fetchRitualsWithStatus() async {
    final rituals = await RitualsService.getRituals('temp_user_id');
    
    // Status fetch logic
    final statusUpdates = <String, bool>{};
    await Future.wait(rituals.map((r) async {
      try {
        final response = await RitualLogsService.getCompletionStatus(r.id);
        statusUpdates[r.id] = response['completedToday'] ?? false;
      } catch (e) {
        statusUpdates[r.id] = false;
      }
    }));
    
    // Update map directly (FutureBuilder will see this when it rebuilds)
    _ritualCompletionStatus.addAll(statusUpdates);
    return rituals;
  }

  Future<List<Partnership>> _fetchPartnershipsWithStatus() async {
    final partnerships = await PartnershipService.getMyPartnerships();
    
    final statusUpdates = <int, bool>{};
    for (var p in partnerships) {
       statusUpdates[p.id] = p.myCompletedToday;
    }
    
    _partnershipCompletionStatus.addAll(statusUpdates);
    return partnerships;
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final result = await _gamificationService.getNotifications();
      if (mounted && result != null) {
        // Sadece sayı değiştiyse ekranı yenile
        if (_unreadNotificationCount != result.unreadCount) {
          setState(() {
            _unreadNotificationCount = result.unreadCount;
          });
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // _loadCompletionStatus artık kullanılmıyor, çünkü status fetch işlemi
  // _fetchRitualsWithStatus ve _fetchPartnershipsWithStatus içine taşındı.
  // Ancak eski koddan kalan referansları temizlemek için boş bırakabiliriz veya silebiliriz.
  // Aşağıdaki metod artık çağrılmıyor.

  Future<bool> _checkRitualCompletedToday(String ritualId) async {
    try {
      final response = await RitualLogsService.getCompletionStatus(ritualId);
      return response['completedToday'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkPartnershipCompletedToday(int partnershipId) async {
    try {
      return await PartnershipService.isCompletedToday(partnershipId);
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // ZAMANLAYİCI SİSTEMİ
  // ============================================

  /// Her ritüel için belirlenen saatte refresh yapacak timer'lar oluştur
  void _scheduleRitualRefreshTimers(List<Ritual> rituals, List<Partnership> partnerships) {
    // Önce eski timer'ları temizle
    _ritualTimers.values.forEach((timer) => timer?.cancel());
    _partnershipTimers.values.forEach((timer) => timer?.cancel());
    _ritualTimers.clear();
    _partnershipTimers.clear();
    
    print('🕒 Scheduling refresh timers...');
    
    // Kişisel ritüeller için
    for (final ritual in rituals) {
      if (ritual.reminderTime.isNotEmpty) {
        _scheduleRitualTimer(ritual);
      }
    }
    
    // Partnership ritüelleri için
    for (final partnership in partnerships) {
      if (partnership.myRitualTime != null && partnership.myRitualTime!.isNotEmpty) {
        _schedulePartnershipTimer(partnership);
      }
    }
    
    print('🕒 Scheduled ${_ritualTimers.length} ritual timers and ${_partnershipTimers.length} partnership timers');
  }

  /// Kişisel ritüel için timer kur
  void _scheduleRitualTimer(Ritual ritual) {
    final duration = _calculateNextRefreshTime(ritual.reminderTime);
    if (duration != null) {
      final scheduledTime = DateTime.now().add(duration);
      print('  ⏰ Ritual "${ritual.name}" refresh: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}');
      
      _ritualTimers[ritual.id] = Timer(duration, () {
        print('🔄 Refreshing ritual: ${ritual.name}');
        // Bu ritüelin completion status'unu sıfırla
        setState(() {
          _ritualCompletionStatus[ritual.id] = false;
        });
        
        // Bir sonraki gün için tekrar schedule et
        _scheduleRitualTimer(ritual);
      });
    }
  }

  /// Partnership ritüel için timer kur
  void _schedulePartnershipTimer(Partnership partnership) {
    final duration = _calculateNextRefreshTime(partnership.myRitualTime!);
    if (duration != null) {
      final scheduledTime = DateTime.now().add(duration);
      print('  ⏰ Partnership "${partnership.myRitualName}" refresh: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}');
      
      _partnershipTimers[partnership.id] = Timer(duration, () {
        print('🔄 Refreshing partnership: ${partnership.myRitualName}');
        setState(() {
          _partnershipCompletionStatus[partnership.id] = false;
        });
        _schedulePartnershipTimer(partnership);
      });
    }
  }

  /// Verilen saat için bir sonraki refresh zamanını hesapla
  Duration? _calculateNextRefreshTime(String timeString) {
    try {
      // "07:00" formatını parse et
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // Eğer bugünün o saati geçtiyse, yarının aynı saatini ayarla
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      return scheduledTime.difference(now);
    } catch (e) {
      print('❌ Error parsing time "$timeString": $e');
      return null;
    }
  }

  List<Ritual> _filterTodayRituals(List<Ritual> rituals) {
    return rituals.where((r) => r.reminderDays.contains(_todayShort)).toList();
  }

  List<Partnership> _filterTodayPartnerships(List<Partnership> partnerships) {
    return partnerships.where((p) => p.myRitualDays?.contains(_todayShort) ?? true).toList();
  }

  Future<void> _acceptRequest(int requestId) async {
    try {
      final result = await PartnershipService.acceptRequest(requestId);
      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Partner isteği kabul edildi! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRituals();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    try {
      final success = await PartnershipService.rejectRequest(requestId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner isteği reddedildi'),
          ),
        );
        _loadRituals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _loadRituals(),
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([_myRitualsFuture, _partnershipsFuture, _profileFuture]),
              builder: (context, snapshot) {
                if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final myRituals = snapshot.data?[0] as List<Ritual>? ?? [];
                final partnerships = snapshot.data?[1] as List<Partnership>? ?? [];
                final profile = snapshot.data?[2] as UserProfile?;

                final todayRituals = _filterTodayRituals(myRituals);
                final todayPartnerships = _filterTodayPartnerships(partnerships);
                
                // Partnership'i olmayan kişisel ritüelleri filtrele
                final todayRitualsWithoutPartnerships = todayRituals
                    .where((r) => r.partnershipId == null)
                    .toList();

                final totalToday = todayRitualsWithoutPartnerships.length + todayPartnerships.length;
                final completedToday = todayRitualsWithoutPartnerships.where((r) => _isCompletedToday(r)).length + 
                                     todayPartnerships.where((p) => _isPartnershipCompletedToday(p)).length;
                
                final progressPercent = totalToday > 0 ? (completedToday / totalToday) : 0.0;

                return CustomScrollView(
                  slivers: [
                    // New Modern Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Profile Avatar with Level Badge
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
                                      ),
                                      child: CircleAvatar(
                                         radius: 28,
                                         backgroundColor: AppTheme.darkSurface,
                                         backgroundImage: profile?.avatarUrl != null 
                                           ? NetworkImage(profile!.avatarUrl!)
                                           : null,
                                         child: profile?.avatarUrl == null
                                            ? const Icon(Icons.person, color: Colors.white, size: 32)
                                            : null,
                                       ),
                                     ),
                                     Positioned(
                                       bottom: -5,
                                       left: 0,
                                       right: 0,
                                       child: Center(
                                         child: Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                           decoration: BoxDecoration(
                                             color: AppTheme.darkSurface,
                                             borderRadius: BorderRadius.circular(10),
                                             border: Border.all(color: Colors.white24, width: 1),
                                           ),
                                           child: Text(
                                             'Lvl ${profile?.level ?? 1}',
                                             style: const TextStyle(
                                               fontSize: 10,
                                               fontWeight: FontWeight.bold,
                                               color: Colors.white,
                                             ),
                                           ),
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(width: 16),
                                 // Name and XP Bar
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         _getGreetingMessage(),
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                         style: const TextStyle(
                                           fontSize: 18,
                                           fontWeight: FontWeight.bold,
                                           color: Colors.white,
                                         ),
                                       ),
                                      const SizedBox(height: 6),
                                      // XP Bar
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              Container(
                                                height: 8,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.white10,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              FractionallySizedBox(
                                                widthFactor: ((profile?.xpProgressPercent ?? 0) / 100).clamp(0.0, 1.0),
                                                child: Container(
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    gradient: AppTheme.primaryGradient,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getXpProgressText(profile),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Coins and Streak
                                // Notification Icon
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                        onPressed: () => context.push('/notifications'),
                                      ),
                                      if (_unreadNotificationCount > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 8,
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Daily Progress Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              // Radial Progress
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 80,
                                    width: 80,
                                    child: CircularProgressIndicator(
                                      value: progressPercent,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.white10,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                    ),
                                  ),
                                  Text(
                                    '${(progressPercent * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              // Stats
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildStatTile('Rituals Completed', '$completedToday / $totalToday'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),


                    // Pending Requests (If any)
                    FutureBuilder<List<PartnerRequest>>(
                      future: _pendingRequestsFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Partner Requests',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                ...snapshot.data!.map((req) => PendingRequestCard(
                                  request: req,
                                  onAccept: () => _acceptRequest(req.id),
                                  onReject: () => _rejectRequest(req.id),
                                )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Today's Rituals Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Rituals",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            
                          ],
                        ),
                      ),
                    ),

                    // Active Rituals & Partnerships
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pendingRituals = todayRitualsWithoutPartnerships.where((r) => !_isCompletedToday(r)).toList();
                          final pendingPartnerships = todayPartnerships.where((p) => !_isPartnershipCompletedToday(p)).toList();

                          if (pendingRituals.isEmpty && pendingPartnerships.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: EmptyTodayCard(
                                message: 'No rituals left for today!',
                                icon: Icons.check_circle_outline,
                              ),
                            );
                          }

                          if (index < pendingRituals.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: TodayRitualCard(
                                ritual: pendingRituals[index],
                                onComplete: () {
                                  setState(() {
                                    _ritualCompletionStatus[pendingRituals[index].id] = true;
                                  });
                                  _loadRituals();
                                },
                              ),
                            );
                          } else {
                            final partnershipIndex = index - pendingRituals.length;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: TodayPartnershipCard(
                                partnership: pendingPartnerships[partnershipIndex],
                                onComplete: () {
                                  setState(() {
                                    _partnershipCompletionStatus[pendingPartnerships[partnershipIndex].id] = true;
                                  });
                                  _loadRituals();
                                },
                              ),
                            );
                          }
                        },
                        childCount: (todayRitualsWithoutPartnerships.where((r) => !_isCompletedToday(r)).length + 
                                     todayPartnerships.where((p) => !_isPartnershipCompletedToday(p)).length).clamp(1, 999),
                      ),
                    ),

                    // Add New Ritual Button (Modern Dashed Design)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: GestureDetector(
                          onTap: () => context.push('/ritual/create'),
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.textSecondary.withOpacity(0.2),
                                width: 1.5,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: AppTheme.textSecondary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Add New Ritual',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Completed Rituals Section
                    if (completedToday > 0)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final completedRitualsList = todayRitualsWithoutPartnerships.where((r) => _isCompletedToday(r)).toList();
                            final completedPartnershipsList = todayPartnerships.where((p) => _isPartnershipCompletedToday(p)).toList();

                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                                child: Row(
                                  children: [
      
       
                                    const Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final dataIndex = index - 1;
                            if (dataIndex < completedRitualsList.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                child: TodayRitualCard(
                                  ritual: completedRitualsList[dataIndex],
                                  onComplete: () {}, // Already completed
                                  isCompleted: true,
                                ),
                              );
                            } else {
                              final pIndex = dataIndex - completedRitualsList.length;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                child: Opacity(
                                  opacity: 0.6,
                                  child: TodayPartnershipCard(
                                    partnership: completedPartnershipsList[pIndex],
                                    onComplete: () {}, // Already completed
                                    isCompleted: true,
                                  ),
                                ),
                              );
                            }
                          },
                          childCount: 1 + completedToday,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }


  // Helper methods to check if ritual/partnership is completed today
  bool _isCompletedToday(Ritual ritual) {
    return _ritualCompletionStatus[ritual.id] ?? false;
  }

  bool _isPartnershipCompletedToday(Partnership partnership) {
    return _partnershipCompletionStatus[partnership.id] ?? false;
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground1,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.grid_view_rounded, 'Home', true, () {}),
                _buildNavItem(Icons.people_alt_rounded, 'Social', false, () => context.push('/friends')),
                const SizedBox(width: 60), // Space for FAB
                _buildNavItem(Icons.bar_chart_rounded, 'Stats', false, () => context.push('/stats')),
                _buildNavItem(Icons.person_rounded, 'Profile', false, () => context.push('/profile')),
              ],
            ),
          ),
          // Floating Center Button with Glow
          Positioned(
            top: -25,
            child: GestureDetector(
              onTap: () => context.push('/ritual/create'),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF007ADF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _getMotivationalMessage() {
    final messages = [
      '✨ Every small step builds great habits',
      '🌟 Today is a great day to grow',
      '🚀 Your future self will thank you today',
      '💪 Consistency is your superpower',
      '🎯 Small habits, big transformations',
      '🌱 Progress, not perfection',
      '🌱 Progress, not perfection',
    ];
    return messages[DateTime.now().day % messages.length];
  }

  String _getXpProgressText(UserProfile? profile) {
    if (profile == null) return '0 / 100 XP';
    
    final currentXp = profile.xp;
    // Backend verisinde 'xpForNextLevel' bazen şimdiki seviyenin BAŞLANGIÇ değerini dönüyor olabilir.
    // Örnek: XP=260, Next=240, Progress=20%.
    // Bu durumda Next(240) aslında Base.
    // Hesap: (260 - 240) = 20. TotalDelta = 20 / 0.20 = 100. RealTarget = 240 + 100 = 340.
    
    int targetXp = profile.xpForNextLevel;

    if (currentXp >= targetXp) {
       final percent = profile.xpProgressPercent / 100.0;
       if (percent > 0.01 && percent < 0.99) {
          final levelStart = targetXp; // Misnamed field assumption
          final currentDelta = currentXp - levelStart;
          final totalDelta = (currentDelta / percent).round();
          targetXp = levelStart + totalDelta;
       } else {
          // Hesaplayamıyorsak sadece XP göster, kafa karıştırma
          return '$currentXp XP';
       }
    }
    
    return '$currentXp / $targetXp XP';
  }
}
