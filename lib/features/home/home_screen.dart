import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ritual.dart';
import '../../services/rituals_service.dart';
import '../../services/ritual_logs_service.dart';
import '../../services/partnership_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

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

  void _loadRituals() async {
    setState(() {
      _myRitualsFuture = RitualsService.getRituals('temp_user_id');
      _partnershipsFuture = PartnershipService.getMyPartnerships();
      _pendingRequestsFuture = PartnershipService.getPendingRequests();
    });
    
    _loadUnreadNotifications();
    
    // Tamamlanma durumunu yükle
    await _loadCompletionStatus();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final result = await _gamificationService.getNotifications();
      if (mounted && result != null) {
        setState(() {
          _unreadNotificationCount = result.unreadCount;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadCompletionStatus() async {
    try {
      print('🔍 Loading completion status...');
      final rituals = await _myRitualsFuture;
      final partnerships = await _partnershipsFuture;
      
      final ritualStatus = <String, bool>{};
      final partnershipStatus = <int, bool>{};
      
      // Paralel kontroller
      await Future.wait([
        ...rituals.map((ritual) async {
          final isCompleted = await _checkRitualCompletedToday(ritual.id);
          ritualStatus[ritual.id] = isCompleted;
          print('  Ritual ${ritual.name}: ${isCompleted ? "✅" : "❌"}');
        }),
        ...partnerships.map((partnership) async {
          final isCompleted = await _checkPartnershipCompletedToday(partnership.id);
          partnershipStatus[partnership.id] = isCompleted;
          print('  Partnership ${partnership.myRitualName}: ${isCompleted ? "✅" : "❌"}');
        }),
      ]);
      
      if (mounted) {
        setState(() {
          _ritualCompletionStatus = ritualStatus;
          _partnershipCompletionStatus = partnershipStatus;
        });
        print('✅ Completion status loaded');
        
        // Ritüellerin belirlenen saatlerinde refresh için zamanlayicilar kur
        _scheduleRitualRefreshTimers(rituals, partnerships);
      }
    } catch (e) {
      print('❌ Error loading completion status: $e');
    }
  }



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
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreetingMessage(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getMotivationalMessage(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_outlined, size: 24),
                                onPressed: () => context.push('/notifications').then((_) => _loadUnreadNotifications()),
                                color: Colors.white,
                              ),
                            ),
                            if (_unreadNotificationCount > 0)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Pending Partnership Requests
                SliverToBoxAdapter(
                  child: FutureBuilder<List<PartnerRequest>>(
                    future: _pendingRequestsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      final requests = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_add,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Partner Requests (${requests.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...requests.map((request) => _PendingRequestCard(
                              request: request,
                              onAccept: () => _acceptRequest(request.id),
                              onReject: () => _rejectRequest(request.id),
                            )),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Today's Rituals Header (Combined)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.today,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'My Today\'s Rituals',
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

                // Combined Rituals (My Rituals + Partnerships)
                FutureBuilder<List<dynamic>>(
                  future: Future.wait([_myRitualsFuture, _partnershipsFuture]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                        ),
                      );
                    }

                    final myRituals = snapshot.data?[0] as List<Ritual>? ?? [];
                    final partnerships = snapshot.data?[1] as List<Partnership>? ?? [];
                    
                    final todayPartnerships = _filterTodayPartnerships(partnerships);
                    
                    // Partnership'i olmayan kişisel ritüelleri filtrele
                    final todayRituals = _filterTodayRituals(myRituals);
                    // Sadece partnershipId'si olmayan ve bana ait olan ritüelleri göster
                    // (Partner ritüelleri zaten partnershipId'ye sahip olacak)
                    final todayRitualsWithoutPartnerships = todayRituals
                        .where((r) => r.partnershipId == null)
                        .toList();

                    // Tamamlanmış ve tamamlanmamış olarak ayır
                    final pendingRituals = todayRitualsWithoutPartnerships.where((r) => !_isCompletedToday(r)).toList();
                    final completedRituals = todayRitualsWithoutPartnerships.where((r) => _isCompletedToday(r)).toList();
                    final pendingPartnerships = todayPartnerships.where((p) => !_isPartnershipCompletedToday(p)).toList();
                    final completedPartnerships = todayPartnerships.where((p) => _isPartnershipCompletedToday(p)).toList();

                    if (pendingRituals.isEmpty && pendingPartnerships.isEmpty && completedRituals.isEmpty && completedPartnerships.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _EmptyTodayCard(
                          message: 'No rituals for today',
                          icon: Icons.check_circle_outline,
                        ),
                      );
                    }

                    // Sadece bekleyen ritüelleri göster
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < pendingRituals.length) {
                            // Show personal ritual (without partnership)
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: _TodayRitualCard(
                                ritual: pendingRituals[index],
                                onComplete: () async {
                                  // Backend'e kaydedildi, completion status'u güncelle
                                  setState(() {
                                    _ritualCompletionStatus[pendingRituals[index].id] = true;
                                  });
                                  // Verileri yenile (streak güncellemeleri için)
                                  _loadRituals();
                                },
                              ),
                            );
                          } else {
                            // Show partnership ritual
                            final partnershipIndex = index - pendingRituals.length;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: _TodayPartnershipCard(
                                partnership: pendingPartnerships[partnershipIndex],
                                onComplete: () async {
                                  // Backend'e kaydedildi, completion status'u güncelle
                                  setState(() {
                                    _partnershipCompletionStatus[pendingPartnerships[partnershipIndex].id] = true;
                                  });
                                  // Verileri yenile (streak güncellemeleri için)
                                  _loadRituals();
                                },
                              ),
                            );
                          }
                        },
                        childCount: pendingRituals.length + pendingPartnerships.length,
                      ),
                    );
                  },
                ),

                // Completed Rituals Section
                FutureBuilder<List<dynamic>>(
                  future: Future.wait([_myRitualsFuture, _partnershipsFuture]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());

                    final myRituals = snapshot.data?[0] as List<Ritual>? ?? [];
                    final partnerships = snapshot.data?[1] as List<Partnership>? ?? [];
                    
                    final todayPartnerships = _filterTodayPartnerships(partnerships);
                    final todayRitualsWithoutPartnerships = _filterTodayRituals(myRituals)
                        .where((r) => r.partnershipId == null)
                        .toList();

                    final completedRituals = todayRitualsWithoutPartnerships.where((r) => _isCompletedToday(r)).toList();
                    final completedPartnerships = todayPartnerships.where((p) => _isPartnershipCompletedToday(p)).toList();

                    if (completedRituals.isEmpty && completedPartnerships.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Header
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.successColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'My Completed Rituals (${completedRituals.length + completedPartnerships.length})',
                                    style: const TextStyle(
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
                          if (dataIndex < completedRituals.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: Opacity(
                                opacity: 0.6,
                                child: _TodayRitualCard(
                                  ritual: completedRituals[dataIndex],
                                  onComplete: () {}, // Already completed
                                  isCompleted: true,
                                ),
                              ),
                            );
                          } else {
                            final partnershipIndex = dataIndex - completedRituals.length;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: Opacity(
                                opacity: 0.6,
                                child: _TodayPartnershipCard(
                                  partnership: completedPartnerships[partnershipIndex],
                                  onComplete: () {}, // Already completed
                                  isCompleted: true,
                                ),
                              ),
                            );
                          }
                        },
                        childCount: 1 + completedRituals.length + completedPartnerships.length,
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
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
      decoration: BoxDecoration(
        color: AppTheme.darkBackground1,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(icon: Icons.home, label: 'Home', isActive: true, onTap: () {}),
              _BottomNavItem(icon: Icons.list_alt, label: 'Rituals', isActive: false, onTap: () => context.go('/rituals')),
              _BottomNavItem(icon: Icons.person, label: 'Profile', isActive: false, onTap: () => context.go('/profile')),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning ☀️';
    if (hour >= 12 && hour < 17) return 'Good Afternoon 🌤️';
    if (hour >= 17 && hour < 21) return 'Good Evening 🌅';
    return 'Good Night 🌙';
  }

  String _getMotivationalMessage() {
    final messages = [
      '✨ Every small step builds great habits',
      '🌟 Today is a great day to grow',
      '🚀 Your future self will thank you today',
      '💪 Consistency is your superpower',
      '🎯 Small habits, big transformations',
      '🌱 Progress, not perfection',
    ];
    return messages[DateTime.now().day % messages.length];
  }
}

// Empty Card
class _EmptyTodayCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyTodayCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.white38),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// Today Ritual Card
class _TodayRitualCard extends StatefulWidget {
  final Ritual ritual;
  final VoidCallback onComplete;
  final bool isCompleted;

  const _TodayRitualCard({
    required this.ritual, 
    required this.onComplete,
    this.isCompleted = false,
  });

  @override
  State<_TodayRitualCard> createState() => _TodayRitualCardState();
}

class _TodayRitualCardState extends State<_TodayRitualCard> {
  bool _isCompleting = false;
  bool _completedToday = false;

  @override
  void initState() {
    super.initState();
    // Bugün tamamlanıp tamamlanmadığını kontrol et
    _checkIfCompletedToday();
  }

  Future<void> _checkIfCompletedToday() async {
    // TODO: Backend'den bugün tamamlanmış mı kontrolü yap
    // Şimdilik false olarak kalacak
  }

  Future<void> _completeRitual() async {
    if (_completedToday || _isCompleting) return;
    
    setState(() => _isCompleting = true);
    try {
      await RitualLogsService.logCompletion(ritualId: widget.ritual.id, stepIndex: -1, source: 'manual');
      if (mounted) {
        setState(() {
          _completedToday = true;
          _isCompleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${widget.ritual.name} completed! 🎉'),
            ]),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer tamamlandıysa, swipe olmadan sadece kartı göster
    if (widget.isCompleted) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.ritual.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF00C853).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 12, color: Color(0xFF00C853)),
                              const SizedBox(width: 4),
                              Text('${widget.ritual.currentStreak}', style: const TextStyle(fontSize: 11, color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(widget.ritual.reminderTime, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Dismissible(
      key: Key(widget.ritual.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (!_isCompleting) {
          await _completeRitual();
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 32),
            SizedBox(width: 8),
              Text(
                'Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: _completedToday 
                ? null 
                : LinearGradient(
                    colors: [
                      const Color(0xFF00C853).withOpacity(0.15),
                      const Color(0xFF69F0AE).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: _completedToday ? AppTheme.surfaceColor : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _completedToday 
                  ? Colors.white.withOpacity(0.1) 
                  : const Color(0xFF00C853).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.ritual.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF00C853).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 12, color: Color(0xFF00C853)),
                              const SizedBox(width: 4),
                              Text('${widget.ritual.currentStreak}', style: const TextStyle(fontSize: 11, color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(widget.ritual.reminderTime, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Today Partnership Card (Eşit Partner Sistemi)
class _TodayPartnershipCard extends StatefulWidget {
  final Partnership partnership;
  final VoidCallback onComplete;
  final bool isCompleted;

  const _TodayPartnershipCard({
    required this.partnership, 
    required this.onComplete,
    this.isCompleted = false,
  });

  @override
  State<_TodayPartnershipCard> createState() => _TodayPartnershipCardState();
}

class _TodayPartnershipCardState extends State<_TodayPartnershipCard> {
  bool _isCompleting = false;
  bool _completedToday = false;

  @override
  void initState() {
    super.initState();
    _checkIfCompletedToday();
  }

  Future<void> _checkIfCompletedToday() async {
    // TODO: Backend'den bugün tamamlanmış mı kontrolü yap
  }

  Future<void> _completeRitual() async {
    if (_completedToday || _isCompleting) return;
    
    setState(() => _isCompleting = true);
    try {
      // Kendi ritüelimi tamamla
      await RitualLogsService.logCompletion(
        ritualId: widget.partnership.myRitualId, 
        stepIndex: -1, 
        source: 'manual'
      );
      if (mounted) {
        setState(() {
          _completedToday = true;
          _isCompleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${widget.partnership.myRitualName} completed! ${widget.partnership.partnerUsername} notified 🎉'),
            ]),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer tamamlandıysa, swipe olmadan sadece kartı göster
    if (widget.isCompleted) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.partnership.myRitualName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('${widget.partnership.currentStreak}', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(widget.partnership.partnerUsername, style: const TextStyle(fontSize: 13, color: Colors.orange)),
                        if (widget.partnership.partnerLevel != null) ...[
                          const SizedBox(width: 4),
                          Text('Lv.${widget.partnership.partnerLevel}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        ],
                        if (widget.partnership.myRitualTime != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time, size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(widget.partnership.myRitualTime!, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Dismissible(
      key: Key(widget.partnership.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (!_isCompleting) {
          await _completeRitual();
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 32),
            SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Container(
          decoration: BoxDecoration(
            gradient: _completedToday 
                ? null 
                : LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.15),
                      Colors.deepOrange.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: _completedToday ? AppTheme.surfaceColor : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _completedToday 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.orange.withOpacity(0.5), 
              width: 2,
            ),
          ),
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.partnership.myRitualName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text('${widget.partnership.currentStreak}', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(widget.partnership.partnerUsername, style: const TextStyle(fontSize: 13, color: Colors.orange)),
                      if (widget.partnership.partnerLevel != null) ...[
                        const SizedBox(width: 4),
                        Text('Lv.${widget.partnership.partnerLevel}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                      ],
                      if (widget.partnership.myRitualTime != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(widget.partnership.myRitualTime!, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// Pending Partnership Request Card
class _PendingRequestCard extends StatelessWidget {
  final PartnerRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterUsername,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'wants to join your "${request.ritualName}" ritual',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Bottom Nav Item
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppTheme.primaryColor : Colors.white54, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppTheme.primaryColor : Colors.white54, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}
