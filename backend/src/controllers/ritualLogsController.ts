import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import pool from '../config/db';
import xpService from '../services/xpService';

// Log a ritual completion
export const logCompletion = async (req: AuthRequest, res: Response) => {
  const { ritual_id, step_index, source, completed_at } = req.body;
  const userId = req.user?.id;
  
  try {
    const result = await pool.query(
      'INSERT INTO ritual_logs (ritual_id, step_index, source, completed_at) VALUES ($1, $2, $3, $4) RETURNING *',
      [ritual_id, step_index, source, completed_at || new Date()]
    );
    
    // Eğer tüm adımlar tamamlandıysa (step_index = -1 veya tam tamamlama) XP ver
    if (userId && (step_index === -1 || source === 'full_completion')) {
      try {
        // İlk ritual mi kontrol et
        const completionCount = await pool.query(
          `SELECT COUNT(*) FROM ritual_logs 
           WHERE ritual_id IN (SELECT id FROM rituals WHERE user_id = $1) 
           AND step_index = -1`,
          [userId]
        );
        
        const isFirstRitual = parseInt(completionCount.rows[0].count) === 1;
        
        // XP ekle
        const xpResult = await xpService.addXp(
          userId, 
          xpService.XP_REWARDS.ritual_complete, 
          'ritual_complete',
          ritual_id
        );
        
        // İlk ritual ise bonus XP
        if (isFirstRitual) {
          await xpService.addXp(
            userId,
            xpService.XP_REWARDS.first_ritual,
            'first_ritual',
            ritual_id
          );
        }
        
        // Streak kontrolü ve bonus
        const streakResult = await pool.query(
          `SELECT current_streak FROM user_profiles WHERE user_id = $1`,
          [userId]
        );
        
        if (streakResult.rows.length > 0) {
          const currentStreak = streakResult.rows[0].current_streak || 0;
          await xpService.checkAndAwardStreakBonus(userId, currentStreak);
        }
        
      } catch (xpError) {
        console.error('XP ekleme hatası (log yine de kaydedildi):', xpError);
      }
    }
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Log oluşturulamadı' });
  }
};

// Get logs for a ritual
export const getLogs = async (req: AuthRequest, res: Response) => {
  const { ritualId } = req.params;
  
  try {
    const result = await pool.query(
      'SELECT * FROM ritual_logs WHERE ritual_id = $1 ORDER BY completed_at DESC',
      [ritualId]
    );
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Loglar alınamadı' });
  }
};
