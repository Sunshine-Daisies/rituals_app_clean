import { Router, Request, Response } from 'express';
import { checkStreakBreak } from '../services/badgeService';
import pool from '../config/db';

const router = Router();

// Delete user by email (for testing purposes)
router.delete('/user/:email', async (req: Request, res: Response) => {
  try {
    const { email } = req.params;
    console.log(`🗑️ Deleting user with email: ${email}`);
    
    const result = await pool.query('DELETE FROM users WHERE email = $1 RETURNING id', [email]);
    
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ success: true, message: `User ${email} deleted successfully` });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// Test endpoint for streak check
router.post('/test-streak-check/:userId', async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    console.log(`🧪 Testing streak check for user: ${userId}`);
    
    const result = await checkStreakBreak(userId);
    
    res.json({
      success: true,
      result,
      message: 'Streak check completed'
    });
  } catch (error) {
    console.error('Test streak check error:', error);
    res.status(500).json({ error: 'Test failed' });
  }
});

// Test endpoint for partnership streak check
router.post('/test-partnership-streak-check/:partnershipId', async (req: Request, res: Response) => {
  try {
    const { partnershipId } = req.params;
    console.log(`🧪 Testing partnership streak check for partnership: ${partnershipId}`);
    
    // Get partnership data
    const partnership = await pool.query(
      `SELECT 
        rp.id as partnership_id,
        rp.ritual_id_1,
        rp.user_id_1,
        rp.ritual_id_2,
        rp.user_id_2,
        rp.current_streak,
        rp.freeze_count,
        r1.name as ritual_name,
        r1.reminder_time,
        r1.reminder_days
      FROM ritual_partnerships rp
      JOIN rituals r1 ON r1.id = rp.ritual_id_1
      WHERE rp.id = $1`,
      [partnershipId]
    );
    
    if (partnership.rows.length === 0) {
      return res.status(404).json({ error: 'Partnership not found' });
    }
    
    const p = partnership.rows[0];
    const today = new Date().toLocaleDateString('en-CA');
    
    // Check completions
    const completionCheck = await pool.query(
      `SELECT 
        (SELECT COUNT(*) FROM ritual_logs 
         WHERE ritual_id = $1 AND user_id = $2 
         AND DATE(completed_at) = $3 AND step_index = -1) as user1_completed,
        (SELECT COUNT(*) FROM ritual_logs 
         WHERE ritual_id = $4 AND user_id = $5 
         AND DATE(completed_at) = $3 AND step_index = -1) as user2_completed`,
      [p.ritual_id_1, p.user_id_1, today, p.ritual_id_2, p.user_id_2]
    );
    
    const user1Completed = parseInt(completionCheck.rows[0]?.user1_completed || '0') > 0;
    const user2Completed = parseInt(completionCheck.rows[0]?.user2_completed || '0') > 0;
    
    let result: any = {
      partnership_id: p.partnership_id,
      current_streak: p.current_streak,
      freeze_count: p.freeze_count,
      user1_completed: user1Completed,
      user2_completed: user2Completed,
      both_completed: user1Completed && user2Completed
    };
    
    // If not both completed, check streak
    if (!user1Completed || !user2Completed) {
      const streakResult = await checkPartnershipStreakBreak(
        p.partnership_id,
        p.current_streak,
        p.freeze_count,
        p.user_id_1,
        p.user_id_2
      );
      result = { ...result, ...streakResult };
    }
    
    res.json({
      success: true,
      result,
      message: 'Partnership streak check completed'
    });
  } catch (error) {
    console.error('Test partnership streak check error:', error);
    res.status(500).json({ error: 'Test failed' });
  }
});

async function checkPartnershipStreakBreak(
  partnershipId: number,
  currentStreak: number,
  freezeCount: number,
  userId1: string,
  userId2: string
): Promise<{ streakBroken: boolean; freezeUsed: boolean }> {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const today = new Date().toISOString().split('T')[0];
    
    // Bugün freeze kullanılmış mı kontrol et
    const partnershipData = await client.query(
      `SELECT last_freeze_used FROM ritual_partnerships WHERE id = $1`,
      [partnershipId]
    );
    
    if (partnershipData.rows.length > 0 && partnershipData.rows[0].last_freeze_used) {
      const lastFreezeDate = new Date(partnershipData.rows[0].last_freeze_used).toISOString().split('T')[0];
      
      if (lastFreezeDate === today) {
        // Bugün freeze kullanılmış, streak korunuyor
        await client.query('COMMIT');
        return { streakBroken: false, freezeUsed: true };
      }
    }
    
    if (freezeCount > 0 && currentStreak > 0) {
      await client.query(
        `INSERT INTO notifications (user_id, type, title, body, data) 
         VALUES 
         ($1, $2, $3, $4, $5),
         ($6, $2, $3, $4, $5)`,
        [
          userId1,
          'partnership_streak_warning',
          'Partnership Streak Tehlikede! ⚠️',
          `${currentStreak} günlük partnership streak'iniz kırılmak üzere. Birinin freeze kullanması yeterli (${freezeCount} freeze hakkınız var).`,
          JSON.stringify({ partnership_id: partnershipId, streak: currentStreak, freezes_available: freezeCount }),
          userId2
        ]
      );
      
      await client.query('COMMIT');
      return { streakBroken: false, freezeUsed: false };
    }
    
    if (currentStreak > 0) {
      await client.query(
        `UPDATE ritual_partnerships SET current_streak = 0 WHERE id = $1`,
        [partnershipId]
      );
      
      await client.query(
        `INSERT INTO notifications (user_id, type, title, body, data) 
         VALUES 
         ($1, $2, $3, $4, $5),
         ($6, $2, $3, $4, $5)`,
        [
          userId1,
          'partnership_streak_broken',
          'Partnership Streak Kırıldı 💔',
          `${currentStreak} günlük partnership streak'iniz sona erdi.`,
          JSON.stringify({ partnership_id: partnershipId, old_streak: currentStreak }),
          userId2
        ]
      );
    }
    
    await client.query('COMMIT');
    return { streakBroken: true, freezeUsed: false };
    
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Test endpoint for using partnership freeze
router.post('/test-use-partnership-freeze/:partnershipId/:userId', async (req: Request, res: Response) => {
  try {
    const { partnershipId, userId } = req.params;
    console.log(`🧪 Testing partnership freeze usage for partnership: ${partnershipId}, user: ${userId}`);
    
    // Get partnership data
    const partnership = await pool.query(
      `SELECT * FROM ritual_partnerships WHERE id = $1`,
      [partnershipId]
    );
    
    if (partnership.rows.length === 0) {
      return res.status(404).json({ error: 'Partnership not found' });
    }
    
    const p = partnership.rows[0];
    
    if (p.freeze_count <= 0) {
      return res.status(400).json({ error: 'No freezes available' });
    }
    
    const today = new Date().toISOString().split('T')[0];
    
    if (p.last_freeze_used) {
      const lastFreezeDate = new Date(p.last_freeze_used).toISOString().split('T')[0];
      if (lastFreezeDate === today) {
        return res.status(400).json({ error: 'Freeze already used today' });
      }
    }
    
    // Use freeze
    await pool.query(
      `UPDATE ritual_partnerships 
       SET freeze_count = freeze_count - 1, 
           last_freeze_used = CURRENT_TIMESTAMP 
       WHERE id = $1`,
      [partnershipId]
    );
    
    // Record freeze history
    await pool.query(
      `INSERT INTO freeze_history (user_id, streak_preserved, partnership_id) 
       VALUES ($1, $2, $3)`,
      [userId, p.current_streak, partnershipId]
    );
    
    // Send notifications
    const otherUserId = p.user_id_1 === userId ? p.user_id_2 : p.user_id_1;
    const userProfile = await pool.query(
      'SELECT username FROM user_profiles WHERE user_id = $1',
      [userId]
    );
    const username = userProfile.rows[0]?.username || 'Partner';
    
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data) 
       VALUES 
       ($1, 'partnership_freeze_used', 'Freeze Kullanıldı! ❄️', $2, $3),
       ($4, 'partnership_freeze_used', 'Freeze Kullanıldı! ❄️', $5, $3)`,
      [
        userId,
        `${p.current_streak} günlük partnership streak'inizi korudunuz!`,
        JSON.stringify({ partnership_id: partnershipId, streak: p.current_streak }),
        otherUserId,
        `${username} freeze kullandı ve ${p.current_streak} günlük streak'iniz korundu!`,
      ]
    );
    
    res.json({
      success: true,
      message: 'Freeze used successfully',
      streakPreserved: p.current_streak,
      freezesRemaining: p.freeze_count - 1
    });
  } catch (error) {
    console.error('Test use partnership freeze error:', error);
    res.status(500).json({ error: 'Test failed' });
  }
});

export default router;
