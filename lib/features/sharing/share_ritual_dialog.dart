import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import '../../services/partnership_service.dart';
import '../../theme/app_theme.dart';

/// Dialog for sharing a ritual with invite code (Equal Partner System)
class ShareRitualDialog extends StatefulWidget {
  final String ritualId;
  final String ritualTitle;

  const ShareRitualDialog({
    super.key,
    required this.ritualId,
    required this.ritualTitle,
  });

  @override
  State<ShareRitualDialog> createState() => _ShareRitualDialogState();
}

class _ShareRitualDialogState extends State<ShareRitualDialog> {
  bool _isCreatingInvite = false;
  String? _errorMessage;
  InviteResult? _invite;

  Future<void> _createInvite() async {
    setState(() {
      _isCreatingInvite = true;
      _errorMessage = null;
    });

    try {
      final result = await PartnershipService.createInvite(widget.ritualId);
      if (result.success) {
        setState(() {
          _invite = result;
          _isCreatingInvite = false;
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Davet kodu oluşturulamadı';
          _isCreatingInvite = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isCreatingInvite = false;
      });
    }
  }

  Future<void> _cancelInvite() async {
    if (_invite?.inviteId == null) return;
    
    setState(() {
      _isCreatingInvite = true;
      _errorMessage = null;
    });

    try {
      await PartnershipService.cancelInvite(_invite!.inviteId!);
      setState(() {
        _invite = null;
        _isCreatingInvite = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isCreatingInvite = false;
      });
    }
  }

  void _copyCode() {
    if (_invite?.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _invite!.inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet kodu kopyalandı!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareCode() {
    if (_invite?.inviteCode != null) {
      final shareText = '${widget.ritualTitle} ritualime katıl!\n\nDavet Kodu: ${_invite!.inviteCode}\n\nUygulamada "Rituale Katıl" seçeneğini kullanarak bu kodu gir.';
      Clipboard.setData(ClipboardData(text: shareText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşım metni kopyalandı!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatExpiryDate(DateTime? expiresAt) {
    if (expiresAt == null) return '';
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return '${remaining.inDays} gün geçerli';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} saat geçerli';
    } else {
      return 'Süresi dolmak üzere';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
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
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner Davet Et',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          widget.ritualTitle,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
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
                    icon: Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Eşit Partner Sistemi: Her iki taraf da ritüeli birlikte yapar ve aynı haklara sahip olur.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
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

              // Invite Code Section
              if (_invite != null) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Davet Kodu',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _invite!.inviteCode ?? '',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: Colors.white,
                        ),
                      ),
                      if (_invite!.expiresAt != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatExpiryDate(_invite!.expiresAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _copyCode,
                            icon: const Icon(Icons.copy, size: 18, color: Colors.white),
                            label: const Text('Kopyala', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _shareCode,
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Gönder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bu kodu partnerinle paylaş. Katılım isteği geldiğinde onaylamanız gerekecek.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Cancel Invite Button
                TextButton.icon(
                  onPressed: _isCreatingInvite ? null : _cancelInvite,
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Daveti İptal Et'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],

              // Create Invite Button (when no invite yet)
              if (_invite == null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isCreatingInvite ? null : _createInvite,
                      icon: _isCreatingInvite
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.link),
                      label: Text(_isCreatingInvite ? 'Kod Oluşturuluyor...' : 'Davet Kodu Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
}) {
  return showDialog(
    context: context,
    builder: (context) => ShareRitualDialog(
      ritualId: ritualId,
      ritualTitle: ritualTitle,
    ),
  );
}
