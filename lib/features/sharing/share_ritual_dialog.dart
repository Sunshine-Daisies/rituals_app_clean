import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/sharing_service.dart';
import '../../data/models/sharing_models.dart';

/// Dialog for sharing a ritual with invite code
class ShareRitualDialog extends StatefulWidget {
  final String ritualId;
  final String ritualTitle;
  final RitualVisibility currentVisibility;

  const ShareRitualDialog({
    super.key,
    required this.ritualId,
    required this.ritualTitle,
    required this.currentVisibility,
  });

  @override
  State<ShareRitualDialog> createState() => _ShareRitualDialogState();
}

class _ShareRitualDialogState extends State<ShareRitualDialog> {
  final _sharingService = SharingService();
  
  bool _isLoading = false;
  bool _isSharing = false;
  String? _errorMessage;
  String? _inviteCode;
  RitualVisibility _visibility = RitualVisibility.private_;

  @override
  void initState() {
    super.initState();
    _visibility = widget.currentVisibility;
  }

  Future<void> _shareRitual() async {
    // Check if private - private rituals cannot be shared
    if (_visibility == RitualVisibility.private_) {
      setState(() {
        _errorMessage = 'Özel ritualler paylaşılamaz. Önce görünürlüğü değiştirin.';
      });
      return;
    }

    setState(() {
      _isSharing = true;
      _errorMessage = null;
    });

    try {
      final result = await _sharingService.shareRitual(widget.ritualId);
      setState(() {
        _inviteCode = result.inviteCode;
        _isSharing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSharing = false;
      });
    }
  }

  Future<void> _updateVisibility(RitualVisibility newVisibility) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _sharingService.updateRitualVisibility(widget.ritualId, newVisibility);
      setState(() {
        _visibility = newVisibility;
        _isLoading = false;
        // Clear invite code if switching to private
        if (newVisibility == RitualVisibility.private_) {
          _inviteCode = null;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _copyCode() {
    if (_inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet kodu kopyalandı!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareCode() {
    if (_inviteCode != null) {
      final shareText = '${widget.ritualTitle} ritualime katıl!\n\nDavet Kodu: $_inviteCode\n\nUygulamada "Rituale Katıl" seçeneğini kullanarak bu kodu gir.';
      Share.share(shareText, subject: 'Rituals - Partner Daveti');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.share,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ritual Paylaş',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.ritualTitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Visibility Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Görünürlük',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...RitualVisibility.values.map((v) => _buildVisibilityOption(v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Invite Code Section
              if (_inviteCode != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Davet Kodu',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _inviteCode!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _copyCode,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Kopyala'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _shareCode,
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Gönder'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu kodu arkadaşınla paylaş. Katılım isteği geldiğinde onaylamanız gerekecek.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Share Button (when no code yet)
              if (_inviteCode == null && _visibility != RitualVisibility.private_) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareRitual,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(_isSharing ? 'Kod Oluşturuluyor...' : 'Davet Kodu Oluştur'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],

              // Private Warning
              if (_visibility == RitualVisibility.private_) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Özel ritualler paylaşılamaz. Paylaşmak için görünürlüğü değiştirin.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityOption(RitualVisibility visibility) {
    final isSelected = _visibility == visibility;
    
    IconData icon;
    switch (visibility) {
      case RitualVisibility.private_:
        icon = Icons.lock;
        break;
      case RitualVisibility.friendsOnly:
        icon = Icons.people;
        break;
      case RitualVisibility.public_:
        icon = Icons.public;
        break;
    }

    return InkWell(
      onTap: _isLoading ? null : () => _updateVisibility(visibility),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visibility.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    visibility.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            if (_isLoading && _visibility != visibility)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show share dialog
Future<void> showShareRitualDialog(
  BuildContext context, {
  required String ritualId,
  required String ritualTitle,
  RitualVisibility currentVisibility = RitualVisibility.private_,
}) {
  return showDialog(
    context: context,
    builder: (context) => ShareRitualDialog(
      ritualId: ritualId,
      ritualTitle: ritualTitle,
      currentVisibility: currentVisibility,
    ),
  );
}
