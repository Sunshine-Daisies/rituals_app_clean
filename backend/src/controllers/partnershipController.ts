import { Request, Response } from 'express';
import pool from '../config/db';
import { addXp } from '../services/xpService';
import { cacheService } from '../services/cacheService';
import { schedulePartnershipStreakCheck, cancelPartnershipStreakCheck, scheduleRitualStreakCheck, cancelRitualStreakCheck } from '../services/streakScheduler';
import { PartnershipService } from '../services/partnershipService';

// XP Rewards
const XP_REWARDS = {
  create_invite: 5,
  partnership_formed: 15,
};

// Davet kodu oluştur (6 karakterlik)


// ============================================
// INVITE MANAGEMENT
// ============================================

/**
 * POST /api/partnerships/invite/:ritualId
 * Bir ritüel için davet kodu oluştur
 */
export const createInvite = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { ritualId } = req.params;

    const result = await PartnershipService.createInvite(userId, ritualId);

    if (!result.isNew) {
      return res.json({
        message: 'Existing invite code',
        inviteCode: result.invite.invite_code,
        inviteId: result.invite.id,
      });
    }

    res.status(201).json({
      message: 'Invite code created',
      inviteCode: result.invite.invite_code,
      inviteId: result.invite.id,
      expiresAt: result.invite.expires_at,
    });
  } catch (error: any) {
    if (error.status) {
      return res.status(error.status).json({ error: error.message });
    }
    console.error('Create invite error:', error);
    res.status(500).json({ error: 'Error creating invite code' });
  }
};

/**
 * DELETE /api/partnerships/invite/:inviteId
 * Davet kodunu iptal et
 */
export const cancelInvite = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { inviteId } = req.params;

    const result = await pool.query(
      `DELETE FROM ritual_invites 
       WHERE id = $1 AND user_id = $2 AND is_used = false
       RETURNING *`,
      [inviteId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Invite not found or already used' });
    }

    res.json({ message: 'Invite cancelled' });
  } catch (error) {
    console.error('Cancel invite error:', error);
    res.status(500).json({ error: 'Error cancelling invite' });
  }
};

// ============================================
// JOIN PARTNERSHIP
// ============================================

/**
 * POST /api/partnerships/join/:code
 * Davet koduyla partnerlık isteği gönder
 */
export const joinWithCode = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { code } = req.params;
    const { ritualId } = req.body;

    const result = await PartnershipService.joinWithCode(userId, code, ritualId);

    // Notification Logic needs to stay or move? 
    // Ideally service handles it, but for partial refactor, let's keep it here or move it later.
    // For now, let's replicate the notification logic here using result data, or accept it's "mostly" moved.
    // To be perfectly clean, let's keep the notification logic here for now but use result.

    // ... Actually, the original code had notification logic inside. 
    // Let's simplified this: 

    // Davet sahibine bildirim gönder
    const joinerProfile = await pool.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    const joinerUsername = joinerProfile.rows[0]?.username || 'Bir kullanıcı';

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, 'partnership_request', 'Partner Request 🤝', $2, $3)`,
      [
        result.invite.user_id,
        `${joinerUsername} wants to partner up for "${result.invite.ritual_name}"`,
        JSON.stringify({
          request_id: result.request.id,
          requester_id: userId,
          requester_ritual_id: result.finalPartnerRitualId,
          ritual_name: result.invite.ritual_name
        }),
      ]
    );

    res.status(201).json({
      message: 'Partner request sent',
      requestId: result.request.id,
      ritualName: result.invite.ritual_name,
      ownerUsername: result.invite.owner_username,
      yourRitualId: result.finalPartnerRitualId,
    });
  } catch (error: any) {
    if (error.status) {
      return res.status(error.status).json({ error: error.message });
    }
    console.error('Join with code error:', error);
    res.status(500).json({ error: 'Error sending request' });
  }
};

/**
 * PUT /api/partnerships/request/:requestId/accept
 * Partner isteğini kabul et
 */
export const acceptRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { requestId } = req.params;
    const { partnerRitualId } = req.body; // Kabul eden, karşı tarafın ritual ID'si

    // İsteği bul
    const request = await pool.query(
      `SELECT pr.*, r.name as ritual_name, r.user_id as ritual_owner_id
       FROM partnership_requests pr
       JOIN rituals r ON pr.inviter_ritual_id = r.id
       WHERE pr.id = $1`,
      [requestId]
    );

    if (request.rows.length === 0) {
      return res.status(404).json({ error: 'İstek bulunamadı' });
    }

    const req_data = request.rows[0];

    // İsteği kabul etme yetkisi var mı? (davet eden kişi)
    if (req_data.inviter_user_id !== userId) {
      return res.status(403).json({ error: 'You are not authorized to accept this request' });
    }

    if (req_data.status !== 'pending') {
      return res.status(400).json({ error: 'This request has already been processed' });
    }

    // Karşı tarafın ritüelini bul veya oluştur
    let inviteeRitualId = req_data.invitee_ritual_id || partnerRitualId;

    if (!inviteeRitualId) {
      // Request oluştururken ritüel belirtilmemişse, şimdi oluştur
      const orig = await pool.query('SELECT * FROM rituals WHERE id = $1', [req_data.inviter_ritual_id]);
      if (orig.rows.length > 0) {
        const o = orig.rows[0];
        const newRitual = await pool.query(
          `INSERT INTO rituals (user_id, name, reminder_time, reminder_days, is_public)
           VALUES ($1, $2, $3, $4, true) RETURNING id`,
          [req_data.invitee_user_id, o.name, o.reminder_time, o.reminder_days]
        );
        inviteeRitualId = newRitual.rows[0].id;
      } else {
        return res.status(404).json({ error: 'Original ritual not found' });
      }
    }

    // Partnership oluştur
    const partnership = await pool.query(
      `INSERT INTO ritual_partnerships (
        ritual_id_1, user_id_1,
        ritual_id_2, user_id_2,
        current_streak, longest_streak
      ) VALUES ($1, $2, $3, $4, 0, 0)
      RETURNING *`,
      [
        req_data.inviter_ritual_id, req_data.inviter_user_id,
        inviteeRitualId, req_data.invitee_user_id
      ]
    );

    // İsteği güncelle
    await pool.query(
      `UPDATE partnership_requests SET status = 'accepted', responded_at = NOW() WHERE id = $1`,
      [requestId]
    );

    // Davet kodunu kullanıldı olarak işaretle
    if (req_data.invite_id) {
      await pool.query(
        `UPDATE ritual_invites SET is_used = true, used_by = $1, used_at = NOW() WHERE id = $2`,
        [req_data.invitee_user_id, req_data.invite_id]
      );
    }

    // Her iki tarafa XP ver
    await addXp(userId, XP_REWARDS.partnership_formed, 'partnership_formed', partnership.rows[0].id);
    await addXp(req_data.invitee_user_id, XP_REWARDS.partnership_formed, 'partnership_formed', partnership.rows[0].id);

    // Partner'a bildirim gönder
    const ownerProfile = await pool.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    const ownerUsername = ownerProfile.rows[0]?.username || 'Partner';

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, 'partnership_accepted', 'Partnership Formed! 🎉', $2, $3)`,
      [
        req_data.invitee_user_id,
        `You have partnered with ${ownerUsername} for "${req_data.ritual_name}"!`,
        JSON.stringify({ partnership_id: partnership.rows[0].id }),
      ]
    );

    // Cancel solo streak checks for both rituals (they're now partnership rituals)
    cancelRitualStreakCheck(req_data.inviter_user_id, req_data.inviter_ritual_id);
    cancelRitualStreakCheck(req_data.invitee_user_id, inviteeRitualId);

    // Schedule streak check for partnership
    const ritualData = await pool.query(
      `SELECT r.name, r.reminder_time, r.reminder_days
       FROM rituals r WHERE r.id = $1`,
      [req_data.inviter_ritual_id]
    );

    if (ritualData.rows.length > 0) {
      const ritual = ritualData.rows[0];
      schedulePartnershipStreakCheck({
        partnership_id: partnership.rows[0].id,
        ritual_id_1: req_data.inviter_ritual_id,
        user_id_1: req_data.inviter_user_id,
        ritual_id_2: inviteeRitualId,
        user_id_2: req_data.invitee_user_id,
        ritual_name: ritual.name,
        reminder_time: ritual.reminder_time,
        reminder_days: ritual.reminder_days,
        current_streak: 0,
        freeze_count: 2
      });
    }

    // Invalidate cache for both users
    await cacheService.del(`profile:${userId}`);
    await cacheService.del(`public_profile:${userId}`);
    await cacheService.del(`profile:${req_data.invitee_user_id}`);
    await cacheService.del(`public_profile:${req_data.invitee_user_id}`);

    res.json({
      message: 'Partner request accepted!',
      partnershipId: partnership.rows[0].id,
    });
  } catch (error) {
    console.error('Accept request error:', error);
    res.status(500).json({ error: 'Error accepting request' });
  }
};

/**
 * PUT /api/partnerships/request/:requestId/reject
 * Partner isteğini reddet
 */
export const rejectRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { requestId } = req.params;

    const request = await pool.query(
      `SELECT * FROM partnership_requests WHERE id = $1`,
      [requestId]
    );

    if (request.rows.length === 0) {
      return res.status(404).json({ error: 'İstek bulunamadı' });
    }

    if (request.rows[0].inviter_user_id !== userId) {
      return res.status(403).json({ error: 'You are not authorized to reject this request' });
    }

    await pool.query(
      `UPDATE partnership_requests SET status = 'rejected', responded_at = NOW() WHERE id = $1`,
      [requestId]
    );

    res.json({ message: 'Request rejected' });
  } catch (error) {
    console.error('Reject request error:', error);
    res.status(500).json({ error: 'Error rejecting request' });
  }
};

// ============================================
// PARTNERSHIP MANAGEMENT
// ============================================

/**
 * GET /api/partnerships/my
 * Benim partnerlıklarım
 */
export const getMyPartnerships = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

    const result = await pool.query(
      `SELECT 
        rp.*,
        r1.name as ritual_name_1, r1.reminder_time as time_1, r1.reminder_days as days_1,
        r2.name as ritual_name_2, r2.reminder_time as time_2, r2.reminder_days as days_2,
        up1.username as username_1, up1.level as level_1,
        up2.username as username_2, up2.level as level_2
       FROM ritual_partnerships rp
       JOIN rituals r1 ON rp.ritual_id_1 = r1.id
       JOIN rituals r2 ON rp.ritual_id_2 = r2.id
       LEFT JOIN user_profiles up1 ON rp.user_id_1 = up1.user_id
       LEFT JOIN user_profiles up2 ON rp.user_id_2 = up2.user_id
       WHERE (rp.user_id_1 = $1 OR rp.user_id_2 = $1) AND rp.status = 'active'
       ORDER BY rp.created_at DESC`,
      [userId]
    );

    // Bugünün başlangıcı ve sonu
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Kullanıcı perspektifinden formatla ve bugünkü tamamlama durumlarını kontrol et
    const partnerships = await Promise.all(result.rows.map(async (p) => {
      const isUser1 = p.user_id_1 === userId;
      const myRitualId = isUser1 ? p.ritual_id_1 : p.ritual_id_2;
      const partnerRitualId = isUser1 ? p.ritual_id_2 : p.ritual_id_1;

      // Benim bugünkü tamamlama durumum
      const myCompletionCheck = await pool.query(
        `SELECT 1 FROM ritual_logs 
         WHERE ritual_id = $1 AND step_index = -1 
         AND completed_at >= $2 AND completed_at < $3`,
        [myRitualId, today.toISOString(), tomorrow.toISOString()]
      );

      // Partnerin bugünkü tamamlama durumu
      const partnerCompletionCheck = await pool.query(
        `SELECT 1 FROM ritual_logs 
         WHERE ritual_id = $1 AND step_index = -1 
         AND completed_at >= $2 AND completed_at < $3`,
        [partnerRitualId, today.toISOString(), tomorrow.toISOString()]
      );

      return {
        id: p.id,
        myRitualId: myRitualId,
        myRitualName: isUser1 ? p.ritual_name_1 : p.ritual_name_2,
        myRitualTime: isUser1 ? p.time_1 : p.time_2,
        myRitualDays: isUser1 ? p.days_1 : p.days_2,
        partnerRitualId: partnerRitualId,
        partnerRitualName: isUser1 ? p.ritual_name_2 : p.ritual_name_1,
        partnerUserId: isUser1 ? p.user_id_2 : p.user_id_1,
        partnerUsername: isUser1 ? p.username_2 : p.username_1,
        partnerLevel: isUser1 ? p.level_2 : p.level_1,
        currentStreak: p.current_streak,
        longestStreak: p.longest_streak,
        lastBothCompletedAt: p.last_both_completed_at,
        myCompletedToday: myCompletionCheck.rows.length > 0,
        partnerCompletedToday: partnerCompletionCheck.rows.length > 0,
        createdAt: p.created_at,
      };
    }));

    res.json(partnerships);
  } catch (error) {
    console.error('Get my partnerships error:', error);
    res.status(500).json({ error: 'Error retrieving partnerships' });
  }
};

/**
 * GET /api/partnerships/ritual/:ritualId
 * Belirli bir ritüelin partnership bilgisi
 */
export const getPartnershipByRitual = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { ritualId } = req.params;

    const result = await pool.query(
      `SELECT 
        rp.*,
        r1.name as ritual_name_1, r1.reminder_time as time_1,
        r2.name as ritual_name_2, r2.reminder_time as time_2,
        up1.username as username_1, up1.level as level_1,
        up2.username as username_2, up2.level as level_2
       FROM ritual_partnerships rp
       JOIN rituals r1 ON rp.ritual_id_1 = r1.id
       JOIN rituals r2 ON rp.ritual_id_2 = r2.id
       LEFT JOIN user_profiles up1 ON rp.user_id_1 = up1.user_id
       LEFT JOIN user_profiles up2 ON rp.user_id_2 = up2.user_id
       WHERE (rp.ritual_id_1 = $1 OR rp.ritual_id_2 = $1) AND rp.status = 'active'`,
      [ritualId]
    );

    if (result.rows.length === 0) {
      return res.json({ hasPartner: false });
    }

    const p = result.rows[0];
    const isUser1 = p.user_id_1 === userId;

    res.json({
      hasPartner: true,
      partnershipId: p.id,
      partnerUserId: isUser1 ? p.user_id_2 : p.user_id_1,
      partnerUsername: isUser1 ? p.username_2 : p.username_1,
      partnerLevel: isUser1 ? p.level_2 : p.level_1,
      partnerRitualId: isUser1 ? p.ritual_id_2 : p.ritual_id_1,
      currentStreak: p.current_streak,
      longestStreak: p.longest_streak,
    });
  } catch (error) {
    console.error('Get partnership by ritual error:', error);
    res.status(500).json({ error: 'Error retrieving partnership information' });
  }
};

/**
 * DELETE /api/partnerships/:partnershipId/leave
 * Partnerlıktan ayrıl (her iki taraf da kendi ritüeline devam eder)
 */
export const leavePartnership = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { partnershipId } = req.params;

    const partnership = await pool.query(
      `SELECT rp.*, 
              up1.username as username_1, up2.username as username_2,
              r1.name as ritual_name
       FROM ritual_partnerships rp
       LEFT JOIN user_profiles up1 ON rp.user_id_1 = up1.user_id
       LEFT JOIN user_profiles up2 ON rp.user_id_2 = up2.user_id
       LEFT JOIN rituals r1 ON rp.ritual_id_1 = r1.id
       WHERE rp.id = $1 AND rp.status = 'active'`,
      [partnershipId]
    );

    if (partnership.rows.length === 0) {
      return res.status(404).json({ error: 'Active partnership not found' });
    }

    const p = partnership.rows[0];

    // Bu kullanıcı partnerlığın bir tarafı mı?
    if (p.user_id_1 !== userId && p.user_id_2 !== userId) {
      return res.status(403).json({ error: 'You are not a part of this partnership' });
    }

    // Partnerlığı sonlandır
    await pool.query(
      `UPDATE ritual_partnerships 
       SET status = 'ended', ended_by = $1, ended_at = NOW()
       WHERE id = $2`,
      [userId, partnershipId]
    );

    // Cancel scheduled streak check
    cancelPartnershipStreakCheck(parseInt(partnershipId));

    // Schedule solo streak checks for both rituals
    const ritual1 = await pool.query(
      `SELECT id, user_id, name, reminder_time, reminder_days 
       FROM rituals WHERE id = $1`,
      [p.ritual_id_1]
    );
    const ritual2 = await pool.query(
      `SELECT id, user_id, name, reminder_time, reminder_days 
       FROM rituals WHERE id = $1`,
      [p.ritual_id_2]
    );

    if (ritual1.rows.length > 0) {
      const r1 = ritual1.rows[0];
      scheduleRitualStreakCheck({
        user_id: r1.user_id,
        ritual_id: r1.id,
        ritual_name: r1.name,
        reminder_time: r1.reminder_time,
        reminder_days: r1.reminder_days
      });
    }

    if (ritual2.rows.length > 0) {
      const r2 = ritual2.rows[0];
      scheduleRitualStreakCheck({
        user_id: r2.user_id,
        ritual_id: r2.id,
        ritual_name: r2.name,
        reminder_time: r2.reminder_time,
        reminder_days: r2.reminder_days
      });
    }

    // Diğer tarafa bildirim gönder
    const otherUserId = p.user_id_1 === userId ? p.user_id_2 : p.user_id_1;
    const leaverUsername = p.user_id_1 === userId ? p.username_1 : p.username_2;

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, 'partnership_ended', 'Partnership Ended 👋', $2, $3)`,
      [
        otherUserId,
        `${leaverUsername} left the partnership for "${p.ritual_name}". You can continue your ritual personally!`,
        JSON.stringify({ partnership_id: partnershipId }),
      ]
    );

    // Invalidate cache for both users
    await cacheService.del(`profile:${userId}`);
    await cacheService.del(`public_profile:${userId}`);
    await cacheService.del(`profile:${otherUserId}`);
    await cacheService.del(`public_profile:${otherUserId}`);

    res.json({
      message: 'You have left the partnership. Your ritual continues personally.',
    });
  } catch (error) {
    console.error('Leave partnership error:', error);
    res.status(500).json({ error: 'Error while leaving partnership' });
  }
};

// ============================================
// STREAK MANAGEMENT
// ============================================

/**
 * Update partnership streak when both complete
 * Called from ritualLogsController
 */
export const updatePartnershipStreak = async (userId: string, ritualId: string): Promise<{
  updated: boolean;
  currentStreak?: number;
  partnerUserId?: string;
}> => {
  try {
    // Bu ritüelin aktif partnerlığı var mı?
    const partnership = await pool.query(
      `SELECT * FROM ritual_partnerships 
       WHERE (ritual_id_1 = $1 OR ritual_id_2 = $1) AND status = 'active'`,
      [ritualId]
    );

    if (partnership.rows.length === 0) {
      return { updated: false };
    }

    const p = partnership.rows[0];
    const isUser1 = p.user_id_1 === userId;
    const otherUserId = isUser1 ? p.user_id_2 : p.user_id_1;
    const otherRitualId = isUser1 ? p.ritual_id_2 : p.ritual_id_1;

    // Bugün her iki taraf da tamamladı mı?
    const today = new Date().toISOString().split('T')[0];

    const myCompletion = await pool.query(
      `SELECT COUNT(*) as count FROM ritual_logs 
       WHERE ritual_id = $1 AND user_id = $2 AND DATE(completed_at) = $3`,
      [ritualId, userId, today]
    );

    const partnerCompletion = await pool.query(
      `SELECT COUNT(*) as count FROM ritual_logs 
       WHERE ritual_id = $1 AND user_id = $2 AND DATE(completed_at) = $3`,
      [otherRitualId, otherUserId, today]
    );

    const bothCompletedToday =
      parseInt(myCompletion.rows[0].count) > 0 &&
      parseInt(partnerCompletion.rows[0].count) > 0;

    if (!bothCompletedToday) {
      return { updated: false, partnerUserId: otherUserId };
    }

    // Bugün zaten streak güncellenmiş mi?
    const lastBothCompleted = p.last_both_completed_at?.toISOString().split('T')[0];
    if (lastBothCompleted === today) {
      return { updated: false, currentStreak: p.current_streak, partnerUserId: otherUserId };
    }

    // Streak hesapla
    let newStreak = 1;
    if (lastBothCompleted) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];

      if (lastBothCompleted === yesterdayStr) {
        newStreak = (p.current_streak || 0) + 1;
      }
    }

    const longestStreak = Math.max(newStreak, p.longest_streak || 0);

    await pool.query(
      `UPDATE ritual_partnerships 
       SET current_streak = $1, longest_streak = $2, last_both_completed_at = NOW()
       WHERE id = $3`,
      [newStreak, longestStreak, p.id]
    );

    return {
      updated: true,
      currentStreak: newStreak,
      partnerUserId: otherUserId
    };
  } catch (error) {
    console.error('Update partnership streak error:', error);
    return { updated: false };
  }
};

/**
 * GET /api/partnerships/pending
 * Bekleyen partner istekleri
 */
export const getPendingRequests = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

    const result = await pool.query(
      `SELECT pr.*, r.name as ritual_name, up.username as requester_username
       FROM partnership_requests pr
       JOIN rituals r ON pr.inviter_ritual_id = r.id
       LEFT JOIN user_profiles up ON pr.invitee_user_id = up.user_id
       WHERE pr.inviter_user_id = $1 AND pr.status = 'pending'
       ORDER BY pr.created_at DESC`,
      [userId]
    );

    res.json(result.rows.map(r => ({
      id: r.id,
      ritualName: r.ritual_name,
      requesterUsername: r.requester_username,
      requesterId: r.invitee_user_id,
      createdAt: r.created_at,
    })));
  } catch (error) {
    console.error('Get pending requests error:', error);
    res.status(500).json({ error: 'Error retrieving requests' });
  }
};

/**
 * Partnership için freeze kullan
 */
export const usePartnershipFreeze = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const { partnershipId } = req.params;

    // Partnership'i kontrol et
    const partnership = await pool.query(
      `SELECT * FROM ritual_partnerships 
       WHERE id = $1 AND status = 'active'`,
      [partnershipId]
    );

    if (partnership.rows.length === 0) {
      return res.status(404).json({ error: 'Partnership not found' });
    }

    const p = partnership.rows[0];

    // Kullanıcı bu partnership'in bir parçası mı?
    if (p.user_id_1 !== userId && p.user_id_2 !== userId) {
      return res.status(403).json({ error: 'You do not belong to this partnership' });
    }

    // Freeze var mı?
    if (p.freeze_count <= 0) {
      return res.status(400).json({ error: 'No freezes remaining' });
    }

    const today = new Date().toISOString().split('T')[0];

    // Bugün zaten freeze kullanılmış mı?
    if (p.last_freeze_used) {
      const lastFreezeDate = new Date(p.last_freeze_used).toISOString().split('T')[0];
      if (lastFreezeDate === today) {
        return res.status(400).json({ error: 'Freeze already used for today' });
      }
    }

    // Freeze kullan
    await pool.query(
      `UPDATE ritual_partnerships 
       SET freeze_count = freeze_count - 1, 
           last_freeze_used = CURRENT_TIMESTAMP 
       WHERE id = $1`,
      [partnershipId]
    );

    // Freeze history kaydet
    await pool.query(
      `INSERT INTO freeze_history (user_id, streak_preserved, partnership_id) 
       VALUES ($1, $2, $3)`,
      [userId, p.current_streak, partnershipId]
    );

    // Her iki partnera da bildirim gönder
    const otherUserId = p.user_id_1 === userId ? p.user_id_2 : p.user_id_1;
    const userProfile = await pool.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    const username = userProfile.rows[0]?.username || 'Partnerin';

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data) 
       VALUES 
       ($1, 'partnership_freeze_used', 'Freeze Used! ❄️', $2, $3),
       ($4, 'partnership_freeze_used', 'Freeze Used! ❄️', $5, $3)`,
      [
        userId,
        `You preserved your ${p.current_streak} day partnership streak!`,
        JSON.stringify({ partnership_id: partnershipId, streak: p.current_streak }),
        otherUserId,
        `${username} used a freeze and your ${p.current_streak} day streak was preserved!`,
      ]
    );

    res.json({
      message: 'Freeze used!',
      streakPreserved: p.current_streak,
      freezesRemaining: p.freeze_count - 1
    });
  } catch (error) {
    console.error('Use partnership freeze error:', error);
    res.status(500).json({ error: 'Error while using freeze' });
  }
};
