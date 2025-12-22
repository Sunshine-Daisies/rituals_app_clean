import { Request, Response } from 'express';
import pool from '../config/db';
import { addXp } from '../services/xpService';
import crypto from 'crypto';

// XP Rewards
const XP_REWARDS = {
  ritual_share: 10,
  partner_join: 15,
};

// Davet kodu oluştur (6 karakterlik)
function generateInviteCode(): string {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

// ============================================
// SHARE RITUAL
// ============================================

// POST /api/sharing/ritual/:ritualId/share - Rituali paylaş
export const shareRitual = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { ritualId } = req.params;

    // Ritual sahibi mi kontrol et
    const ritualCheck = await pool.query(
      'SELECT * FROM rituals WHERE id = $1 AND user_id = $2',
      [ritualId, userId]
    );

    if (ritualCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Ritual not found or does not belong to you' });
    }

    const ritual = ritualCheck.rows[0];

    // Private ritual paylaşılamaz
    if (ritual.is_public === false) {
      return res.status(400).json({ error: 'Private rituals cannot be shared. Make it public first.' });
    }

    // Zaten paylaşılmış mı?
    const existingShare = await pool.query(
      'SELECT * FROM shared_rituals WHERE ritual_id = $1 AND owner_id = $2',
      [ritualId, userId]
    );

    if (existingShare.rows.length > 0) {
      return res.json({
        message: 'Ritual already shared',
        inviteCode: existingShare.rows[0].invite_code,
        sharedRitualId: existingShare.rows[0].id,
      });
    }

    // Yeni davet kodu oluştur
    const inviteCode = generateInviteCode();

    const result = await pool.query(
      `INSERT INTO shared_rituals (ritual_id, owner_id, invite_code, is_public)
       VALUES ($1, $2, $3, true)
       RETURNING *`,
      [ritualId, userId, inviteCode]
    );

    // XP ver
    await addXp(userId, XP_REWARDS.ritual_share, 'ritual_share', parseInt(ritualId));

    res.status(201).json({
      message: 'Ritual shared',
      inviteCode: inviteCode,
      sharedRitualId: result.rows[0].id,
    });
  } catch (error) {
    console.error('Share ritual error:', error);
    res.status(500).json({ error: 'Error sharing ritual' });
  }
};

// ============================================
// JOIN RITUAL
// ============================================

// POST /api/sharing/join/:code - Davet koduyla rituale katıl
export const joinRitual = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { code } = req.params;

    // Davet kodunu bul
    const sharedRitual = await pool.query(
      `SELECT sr.*, r.name as ritual_name, r.user_id as ritual_owner_id,
              u.email as owner_email, up.username as owner_username
       FROM shared_rituals sr
       JOIN rituals r ON sr.ritual_id = r.id
       JOIN users u ON sr.owner_id = u.id
       LEFT JOIN user_profiles up ON sr.owner_id = up.user_id
       WHERE sr.invite_code = $1`,
      [code.toUpperCase()]
    );

    if (sharedRitual.rows.length === 0) {
      return res.status(404).json({ error: 'Invalid invite code' });
    }

    const shared = sharedRitual.rows[0];

    // Kendi ritualine katılamaz
    if (shared.owner_id === userId) {
      return res.status(400).json({ error: 'You cannot join your own ritual' });
    }

    // Zaten katılmış mı?
    const existingPartner = await pool.query(
      'SELECT * FROM ritual_partners WHERE shared_ritual_id = $1 AND user_id = $2',
      [shared.id, userId]
    );

    if (existingPartner.rows.length > 0) {
      const partner = existingPartner.rows[0];
      if (partner.status === 'accepted') {
        return res.status(400).json({ error: 'You have already joined this ritual' });
      } else if (partner.status === 'pending') {
        return res.status(400).json({ error: 'Your join request is already pending' });
      }
    }

    // 1v1 kontrolü - zaten bir partner var mı?
    const partnerCount = await pool.query(
      `SELECT COUNT(*) FROM ritual_partners 
       WHERE shared_ritual_id = $1 AND status = 'accepted'`,
      [shared.id]
    );

    if (parseInt(partnerCount.rows[0].count) >= 1) {
      return res.status(400).json({ error: 'Bu ritualin zaten bir partneri var (1v1 limit)' });
    }

    // Partner olarak ekle
    const result = await pool.query(
      `INSERT INTO ritual_partners (shared_ritual_id, user_id, status)
       VALUES ($1, $2, 'pending')
       RETURNING *`,
      [shared.id, userId]
    );

    // Ritual sahibine bildirim gönder
    const joinerProfile = await pool.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    const joinerUsername = joinerProfile.rows[0]?.username || 'A user';

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, 'ritual_invite', 'Partner Request 🎯', $2, $3)`,
      [
        shared.owner_id,
        `${joinerUsername} wants to join your ritual "${shared.ritual_name}"`,
        JSON.stringify({
          shared_ritual_id: shared.id,
          partner_id: result.rows[0].id,
          requester_id: userId
        }),
      ]
    );

    res.status(201).json({
      message: 'Join request sent',
      partnerId: result.rows[0].id,
      ritualName: shared.ritual_name,
      ownerUsername: shared.owner_username,
    });
  } catch (error) {
    console.error('Join ritual error:', error);
    res.status(500).json({ error: 'Error joining ritual' });
  }
};

// ============================================
// PARTNER MANAGEMENT
// ============================================

// PUT /api/sharing/partner/:partnerId/accept - Partner isteğini kabul et
export const acceptPartner = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { partnerId } = req.params;

    const partnerCheck = await pool.query(
      `SELECT rp.*, sr.owner_id, sr.ritual_id, r.name as ritual_name
       FROM ritual_partners rp
       JOIN shared_rituals sr ON rp.shared_ritual_id = sr.id
       JOIN rituals r ON sr.ritual_id = r.id
       WHERE rp.id = $1`,
      [partnerId]
    );

    if (partnerCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Partner request not found' });
    }

    const partner = partnerCheck.rows[0];

    if (partner.owner_id !== userId) {
      return res.status(403).json({ error: 'You are not authorized to accept this request' });
    }

    if (partner.status !== 'pending') {
      return res.status(400).json({ error: 'This request has already been processed' });
    }

    // Kabul et
    await pool.query(
      `UPDATE ritual_partners SET status = 'accepted', joined_at = NOW()
       WHERE id = $1`,
      [partnerId]
    );

    // Partner'a XP ver
    await addXp(partner.user_id, XP_REWARDS.partner_join, 'partner_join', partner.shared_ritual_id);

    // Partner'a bildirim gönder
    const ownerProfile = await pool.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    const ownerUsername = ownerProfile.rows[0]?.username || 'Ritual owner';

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, 'partner_accepted', 'Request Accepted ✅', $2, $3)`,
      [
        partner.user_id,
        `${ownerUsername} accepted your join request for ritual "${partner.ritual_name}"`,
        JSON.stringify({ shared_ritual_id: partner.shared_ritual_id }),
      ]
    );

    res.json({ message: 'Partner accepted' });
  } catch (error) {
    console.error('Accept partner error:', error);
    res.status(500).json({ error: 'Error accepting partner' });
  }
};

// PUT /api/sharing/partner/:partnerId/reject - Partner isteğini reddet
export const rejectPartner = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { partnerId } = req.params;

    const partnerCheck = await pool.query(
      `SELECT rp.*, sr.owner_id
       FROM ritual_partners rp
       JOIN shared_rituals sr ON rp.shared_ritual_id = sr.id
       WHERE rp.id = $1`,
      [partnerId]
    );

    if (partnerCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Partner request not found' });
    }

    const partner = partnerCheck.rows[0];

    if (partner.owner_id !== userId) {
      return res.status(403).json({ error: 'You are not authorized to reject this request' });
    }

    await pool.query(
      `UPDATE ritual_partners SET status = 'rejected' WHERE id = $1`,
      [partnerId]
    );

    res.json({ message: 'Partner request rejected' });
  } catch (error) {
    console.error('Reject partner error:', error);
    res.status(500).json({ error: 'Error rejecting request' });
  }
};

// DELETE /api/sharing/ritual/:ritualId/leave - Partnerlıktan ayrıl
export const leavePartnership = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { ritualId } = req.params;

    const sharedRitual = await pool.query(
      'SELECT * FROM shared_rituals WHERE ritual_id = $1',
      [ritualId]
    );

    if (sharedRitual.rows.length === 0) {
      return res.status(404).json({ error: 'Shared ritual not found' });
    }

    const shared = sharedRitual.rows[0];

    const partnerCheck = await pool.query(
      `SELECT * FROM ritual_partners 
       WHERE shared_ritual_id = $1 AND user_id = $2 AND status = 'accepted'`,
      [shared.id, userId]
    );

    if (partnerCheck.rows.length === 0) {
      return res.status(400).json({ error: 'You are not a partner of this ritual' });
    }

    await pool.query(
      `UPDATE ritual_partners SET status = 'left' WHERE shared_ritual_id = $1 AND user_id = $2`,
      [shared.id, userId]
    );

    // Ritual sahibine bildirim
    const leaverProfile = await pool.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, 'partner_left', 'Partner Left 👋', $2, $3)`,
      [
        shared.owner_id,
        `${leaverProfile.rows[0]?.username || 'Partner'} left the ritual`,
        JSON.stringify({ ritual_id: ritualId }),
      ]
    );

    res.json({ message: 'You have left the partnership' });
  } catch (error) {
    console.error('Leave partnership error:', error);
    res.status(500).json({ error: 'Error leaving partnership' });
  }
};

// ============================================
// GET PARTNER INFO
// ============================================

// GET /api/sharing/ritual/:ritualId/partner - Ritual'ın partner bilgisini getir
export const getPartnerInfo = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { ritualId } = req.params;

    const sharedRitual = await pool.query(
      `SELECT sr.*, r.name as ritual_name, r.user_id as ritual_owner_id
       FROM shared_rituals sr
       JOIN rituals r ON sr.ritual_id = r.id
       WHERE sr.ritual_id = $1`,
      [ritualId]
    );

    if (sharedRitual.rows.length === 0) {
      return res.json({ hasPartner: false, isShared: false });
    }

    const shared = sharedRitual.rows[0];
    const isOwner = shared.owner_id === userId;

    const partners = await pool.query(
      `SELECT rp.*, up.username, up.level, up.xp
       FROM ritual_partners rp
       LEFT JOIN user_profiles up ON rp.user_id = up.user_id
       WHERE rp.shared_ritual_id = $1`,
      [shared.id]
    );

    const acceptedPartner = partners.rows.find((p: any) => p.status === 'accepted');
    const pendingPartners = partners.rows.filter((p: any) => p.status === 'pending');

    res.json({
      isShared: true,
      isOwner,
      inviteCode: shared.invite_code,
      sharedRitualId: shared.id,
      hasPartner: !!acceptedPartner,
      partner: acceptedPartner ? {
        id: acceptedPartner.id,
        oderId: acceptedPartner.user_id,
        username: acceptedPartner.username,
        level: acceptedPartner.level,
        currentStreak: acceptedPartner.current_streak || 0,
        longestStreak: acceptedPartner.longest_streak || 0,
        lastCompletedAt: acceptedPartner.last_completed_at,
      } : null,
      pendingRequests: isOwner ? pendingPartners.map((p: any) => ({
        id: p.id,
        oderId: p.user_id,
        username: p.username,
      })) : [],
    });
  } catch (error) {
    console.error('Get partner info error:', error);
    res.status(500).json({ error: 'Error getting partner info' });
  }
};

// GET /api/sharing/my-partner-rituals - Katıldığım partner ritualleri
export const getMyPartnerRituals = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

    const result = await pool.query(
      `SELECT rp.*, sr.invite_code, sr.owner_id,
              r.id as ritual_id, r.name as ritual_name, r.reminder_time as time, r.reminder_days as days,
              up.username as owner_username, up.level as owner_level
       FROM ritual_partners rp
       JOIN shared_rituals sr ON rp.shared_ritual_id = sr.id
       JOIN rituals r ON sr.ritual_id = r.id
       LEFT JOIN user_profiles up ON sr.owner_id = up.user_id
       WHERE rp.user_id = $1 AND rp.status = 'accepted'
       ORDER BY rp.joined_at DESC`,
      [userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get my partner rituals error:', error);
    res.status(500).json({ error: 'Error getting partner rituals' });
  }
};

// ============================================
// VISIBILITY
// ============================================

// PUT /api/sharing/ritual/:ritualId/visibility - Ritual visibility değiştir
export const updateRitualVisibility = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { ritualId } = req.params;
    const { isPublic } = req.body;

    const ritual = await pool.query(
      'SELECT * FROM rituals WHERE id = $1 AND user_id = $2',
      [ritualId, userId]
    );

    if (ritual.rows.length === 0) {
      return res.status(404).json({ error: 'Ritual not found' });
    }

    // Private yapılıyorsa ve aktif partneri varsa uyar
    if (!isPublic) {
      const sharedCheck = await pool.query(
        `SELECT rp.* FROM shared_rituals sr
         JOIN ritual_partners rp ON sr.id = rp.shared_ritual_id
         WHERE sr.ritual_id = $1 AND rp.status = 'accepted'`,
        [ritualId]
      );

      if (sharedCheck.rows.length > 0) {
        return res.status(400).json({
          error: 'Bu ritualin aktif partneri var. Önce partnerlığı sonlandırın.'
        });
      }
    }

    await pool.query(
      'UPDATE rituals SET is_public = $1 WHERE id = $2',
      [isPublic, ritualId]
    );

    res.json({ message: `Ritual ${isPublic ? 'public' : 'private'} yapıldı` });
  } catch (error) {
    console.error('Update visibility error:', error);
    res.status(500).json({ error: 'Görünürlük güncellenirken hata oluştu' });
  }
};

// ============================================
// PARTNER STREAK (Internal function)
// ============================================

// Partner streak güncelle (ritual tamamlandığında çağrılır)
export const updatePartnerStreak = async (userId: string, ritualId: number): Promise<void> => {
  try {
    // Bu kullanıcı bu ritualin partneri mi?
    const partnerCheck = await pool.query(
      `SELECT rp.*, sr.owner_id
       FROM ritual_partners rp
       JOIN shared_rituals sr ON rp.shared_ritual_id = sr.id
       WHERE sr.ritual_id = $1 AND rp.user_id = $2 AND rp.status = 'accepted'`,
      [ritualId, userId]
    );

    if (partnerCheck.rows.length === 0) {
      // Belki owner'dır, owner için de kontrol et
      const ownerCheck = await pool.query(
        `SELECT sr.* FROM shared_rituals sr
         JOIN ritual_partners rp ON sr.id = rp.shared_ritual_id
         WHERE sr.ritual_id = $1 AND sr.owner_id = $2 AND rp.status = 'accepted'`,
        [ritualId, userId]
      );

      if (ownerCheck.rows.length === 0) {
        return; // Partner ritual değil
      }
    }

    const partner = partnerCheck.rows[0];
    const today = new Date().toISOString().split('T')[0];
    const lastCompleted = partner?.last_completed_at?.toISOString().split('T')[0];

    let newStreak = 1;
    if (lastCompleted) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];

      if (lastCompleted === yesterdayStr) {
        newStreak = (partner.current_streak || 0) + 1;
      } else if (lastCompleted === today) {
        return; // Bugün zaten tamamlanmış
      }
    }

    const longestStreak = Math.max(newStreak, partner?.longest_streak || 0);

    await pool.query(
      `UPDATE ritual_partners 
       SET current_streak = $1, longest_streak = $2, last_completed_at = NOW()
       WHERE id = $3`,
      [newStreak, longestStreak, partner.id]
    );

  } catch (error) {
    console.error('Update partner streak error:', error);
  }
};
