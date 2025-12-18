import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ritual.dart';
import '../../data/models/sharing_models.dart';
import '../../services/rituals_service.dart';
import '../../services/sharing_service.dart';
import '../../services/partnership_service.dart';
import '../../theme/app_theme.dart';

class RitualsListScreen extends StatefulWidget {
  const RitualsListScreen({super.key});

  @override
  State<RitualsListScreen> createState() => _RitualsListScreenState();
}

class _RitualsListScreenState extends State<RitualsListScreen> {
  late Future<List<Ritual>> _ritualsFuture;
  late Future<List<SharedRitual>> _partnerRitualsFuture;
  final SharingService _sharingService = SharingService();

  @override
  void initState() {
    super.initState();
    _loadRituals();
  }

  Future<void> _loadRituals() async {
    setState(() {
      _ritualsFuture = RitualsService.getRituals('temp_user_id');
      _partnerRitualsFuture = _sharingService.getMyPartnerRituals();
    });
  }

  Future<void> _deleteRitual(String ritualId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
            SizedBox(width: 12),
            Text('Delete Ritual'),
          ],
        ),
        content: const Text('This ritual will be permanently deleted. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.errorColor, Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await RitualsService.deleteRitual(ritualId);
        if (mounted) {
          _loadRituals();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Ritual deleted'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error: $e')),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          );
        }
      }
    }
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create New Ritual',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to proceed?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            
            // AI Option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.push('/llm-chat');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create with AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Plan your ritual by chatting with AI',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Manual Option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.push('/ritual/create');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_note, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Manually',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Write your own ritual step by step yourself',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(context),
        label: const Text('New Ritual'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
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
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.go('/home'),
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Rituals',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Your own and partner rituals',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // My Rituals Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.spacingL, AppTheme.spacingM, AppTheme.spacingL, AppTheme.spacingS),
                    child: Text(
                      'Personal Rituals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),

                // My Rituals List
                _buildMyRitualsList(showShared: false),

                // Partner Rituals Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.spacingL, AppTheme.spacingL, AppTheme.spacingL, AppTheme.spacingS),
                    child: Text(
                      'Partner Rituals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),

                // My Shared Rituals List
                _buildMyRitualsList(showShared: true),

                // Partner Rituals List
                _buildPartnerRitualsList(),

                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyRitualsList({bool showShared = false}) {
    return FutureBuilder<List<Ritual>>(
      future: _ritualsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Only show loader for the main list to avoid double loaders
          if (showShared) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }

        if (snapshot.hasError) {
          if (showShared) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.errorColor)),
            ),
          );
        }

        final rituals = snapshot.data ?? [];
        final filteredRituals = rituals.where((r) => r.isMine && r.hasPartner == showShared).toList();

        if (filteredRituals.isEmpty) {
          if (showShared) return const SliverToBoxAdapter(child: SizedBox.shrink());
          
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.psychology, size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'No rituals yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('New Ritual'),
                      onPressed: () => _showCreateOptions(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ritual = filteredRituals[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: _RitualCard(
                  ritual: ritual,
                  onEdit: () => context.push('/ritual/${ritual.id}'),
                  onDelete: () => _deleteRitual(ritual.id),
                  onRefresh: _loadRituals,
                  onShare: () => _showShareBottomSheet(context, ritual),
                ),
              );
            },
            childCount: filteredRituals.length,
          ),
        );
      },
    );
  }

  Widget _buildPartnerRitualsList() {
    return FutureBuilder<List<SharedRitual>>(
      future: _partnerRitualsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final partnerRituals = snapshot.data ?? [];

        if (partnerRituals.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'No partner rituals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.group_add),
                      label: const Text('Join Ritual'),
                      onPressed: () => context.push('/join-ritual'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final partnerRitual = partnerRituals[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: _PartnerRitualCard(
                  ritual: partnerRitual,
                  onTap: () {
                    context.push('/ritual/${partnerRitual.ritualId}');
                  },
                  onRefresh: _loadRituals,
                ),
              );
            },
            childCount: partnerRituals.length,
          ),
        );
      },
    );
  }

  void _showShareBottomSheet(BuildContext context, Ritual ritual) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ShareBottomSheet(ritual: ritual),
    );
  }
}

class _ShareBottomSheet extends StatefulWidget {
  final Ritual ritual;

  const _ShareBottomSheet({required this.ritual});

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  bool _isLoading = false;
  String? _inviteCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createInvite();
  }

  Future<void> _createInvite() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await PartnershipService.createInvite(widget.ritual.id);
      if (result.success) {
        setState(() {
          _inviteCode = result.inviteCode;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Invite code could not be created';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyCode() {
    if (_inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Invite Partner',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'for the ritual "${widget.ritual.name}"',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          
          if (_isLoading)
            const CircularProgressIndicator(color: AppTheme.primaryColor)
          else if (_error != null)
            Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppTheme.errorColor), textAlign: TextAlign.center),
              ],
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
                  ),
                  child: Text(
                    _inviteCode ?? '',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                        onPressed: _copyCode,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PartnerRitualCard extends StatefulWidget {
  final SharedRitual ritual;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _PartnerRitualCard({
    required this.ritual,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  State<_PartnerRitualCard> createState() => _PartnerRitualCardState();
}

class _PartnerRitualCardState extends State<_PartnerRitualCard> {

  String _formatDays(List<String>? days) {
    if (days == null || days.isEmpty) return 'Every day';
    const dayLabels = {
      'Mon': 'Mon',
      'Tue': 'Tue',
      'Wed': 'Wed',
      'Thu': 'Thu',
      'Fri': 'Fri',
      'Sat': 'Sat',
      'Sun': 'Sun',
    };
    return days.map((d) => dayLabels[d] ?? d).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final ritual = widget.ritual;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon with Partner badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.handshake,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    
                    // Title and Owner
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ritual.ritualTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ritual.ownerUsername,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (ritual.ownerLevel != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Lv.${ritual.ownerLevel}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Streak badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ritual.partnerStreak > 0 
                            ? Colors.orange.withOpacity(0.1)
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: ritual.partnerStreak > 0 ? Colors.orange : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${ritual.partnerStreak}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ritual.partnerStreak > 0 ? Colors.orange : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Time and Days
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    if (ritual.time != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ritual.time!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                    ],
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatDays(ritual.days),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Longest Streak info
                if (ritual.longestStreak > 0) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Longest streak: ${ritual.longestStreak} days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualCard extends StatefulWidget {
  final Ritual ritual;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final VoidCallback onShare;

  const _RitualCard({
    required this.ritual,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.onShare,
  });

  @override
  State<_RitualCard> createState() => _RitualCardState();
}

class _RitualCardState extends State<_RitualCard> {

  String _formatDays(List<String> days) {
    const dayLabels = {
      'Mon': 'Mon',
      'Tue': 'Tue',
      'Wed': 'Wed',
      'Thu': 'Thu',
      'Fri': 'Fri',
      'Sat': 'Sat',
      'Sun': 'Sun',
    };
    return days.map((d) => dayLabels[d] ?? d).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final ritual = widget.ritual;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
        border: ritual.hasPartner 
            ? Border.all(color: Colors.green.withOpacity(0.3), width: 1) 
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon with partner badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: ritual.hasPartner 
                                ? const LinearGradient(colors: [Colors.green, Colors.teal])
                                : AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Icon(
                            ritual.hasPartner ? Icons.people : Icons.psychology,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (ritual.hasPartner)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.handshake,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    
                    // Title and Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ritual.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ritual.reminderTime,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Partner streak badge (if has partner)
                    if (ritual.hasPartner && ritual.partner != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              '${ritual.partner!.currentStreak}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                    ],
                    
                    // Share Button
                    if (!ritual.hasPartner) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: widget.onShare,
                          color: AppTheme.primaryColor,
                          iconSize: 20,
                          tooltip: 'Share with Partner',
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                    ],

                    // Delete Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: widget.onDelete,
                        color: AppTheme.errorColor,
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
                
                // Partner info section
                if (ritual.hasPartner && ritual.partner != null) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          child: Text(
                            ritual.partner!.username.isNotEmpty 
                                ? ritual.partner!.username[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Partner: ${ritual.partner!.username}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Lv.${ritual.partner!.level} • Longest streak: ${ritual.partner!.longestStreak} days',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.handshake, size: 20, color: Colors.green),
                      ],
                    ),
                  ),
                ],
                
                // Days
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDays(ritual.reminderDays),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Steps
                if (ritual.steps.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  const Divider(height: 1),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                          '${ritual.steps.length} steps',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      ritual.steps.length > 3 ? 3 : ritual.steps.length,
                      (index) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                              ritual.steps[index]['title'] ?? 'Step ${index + 1}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (ritual.steps.length > 3) ...[
                    const SizedBox(height: 6),
                    Text(
                      '+${ritual.steps.length - 3} more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
