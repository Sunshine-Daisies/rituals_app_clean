import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import pool from '../config/db';
import { Ritual } from '../types/ritual';
import { scheduleRitualStreakCheck, cancelRitualStreakCheck, schedulePartnershipStreakCheck, cancelPartnershipStreakCheck } from '../services/streakScheduler';

// Tüm ritüelleri getir (kendi ritüelleri + partnership ritüelleri)
export const getRituals = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user.id;

    // Kendi ritüellerini + partnership yapılan ritüelleri getir
    const query = `
      WITH own_rituals AS (
        SELECT 
          r.id,
          r.user_id,
          r.name,
          r.reminder_time,
          r.reminder_days,
          r.created_at,
          r.updated_at,
          r.is_public,
          r.current_streak,
          r.longest_streak,
          r.user_id as profile_id,
          true as is_mine,
          rp.id as partnership_id,
          CASE 
            WHEN rp.ritual_id_1 = r.id THEN rp.ritual_id_2
            WHEN rp.ritual_id_2 = r.id THEN rp.ritual_id_1
          END as partner_ritual_id,
          COALESCE(
            (
              SELECT json_agg(s.* ORDER BY s.order_index)
              FROM ritual_steps s
              WHERE s.ritual_id = r.id
            ),
            '[]'
          ) as steps
        FROM rituals r
        LEFT JOIN ritual_partnerships rp ON (
          (rp.ritual_id_1 = r.id OR rp.ritual_id_2 = r.id)
          AND rp.status = 'active'
        )
        WHERE r.user_id = $1
      ),
      partner_rituals AS (
        SELECT 
          r.id,
          r.user_id,
          r.name,
          r.reminder_time,
          r.reminder_days,
          r.created_at,
          r.updated_at,
          r.is_public,
          r.current_streak,
          r.longest_streak,
          r.user_id as profile_id,
          false as is_mine,
          rp.id as partnership_id,
          partner_ritual.id as partner_ritual_id,
          COALESCE(
            (
              SELECT json_agg(s.* ORDER BY s.order_index)
              FROM ritual_steps s
              WHERE s.ritual_id = r.id
            ),
            '[]'
          ) as steps
        FROM rituals r
        INNER JOIN ritual_partnerships rp ON (
          (rp.ritual_id_1 = r.id OR rp.ritual_id_2 = r.id)
          AND rp.status = 'active'
        )
        INNER JOIN rituals partner_ritual ON (
          CASE 
            WHEN rp.ritual_id_1 = r.id THEN rp.ritual_id_2
            WHEN rp.ritual_id_2 = r.id THEN rp.ritual_id_1
          END = partner_ritual.id
        )
        WHERE partner_ritual.user_id = $1
      )
      SELECT * FROM own_rituals
      UNION ALL
      SELECT * FROM partner_rituals
      ORDER BY created_at DESC
    `;
    const result = await pool.query(query, [userId]);

    // Remove duplicates by ritual ID (in case a user has partnership with themselves somehow)
    const uniqueRituals = result.rows.filter((ritual, index, self) =>
      index === self.findIndex(r => r.id === ritual.id)
    );

    res.json(uniqueRituals);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error retrieving rituals' });
  }
};

// Yeni ritüel ekle
export const createRitual = async (req: AuthRequest, res: Response) => {
  const { name, reminder_time, reminder_days, steps } = req.body as any;
  const userId = req.user.id;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Ritüeli oluştur
    const ritualResult = await client.query(
      'INSERT INTO rituals (user_id, name, reminder_time, reminder_days) VALUES ($1, $2, $3, $4) RETURNING *, user_id as profile_id',
      [userId, name, reminder_time, reminder_days]
    );
    const ritual = ritualResult.rows[0];

    // 2. Adımları ekle
    if (steps && Array.isArray(steps)) {
      for (let i = 0; i < steps.length; i++) {
        const step = steps[i];
        await client.query(
          'INSERT INTO ritual_steps (ritual_id, title, is_completed, order_index) VALUES ($1, $2, $3, $4)',
          [ritual.id, step.title || step.name, step.is_completed || false, i]
        );
      }
    }

    // 3. Oluşturulan adımları ritüel objesine ekle
    ritual.steps = steps || [];

    await client.query('COMMIT');

    // 4. Schedule streak check for this ritual
    scheduleRitualStreakCheck({
      user_id: ritual.user_id,
      ritual_id: ritual.id,
      ritual_name: ritual.name,
      reminder_time: ritual.reminder_time,
      reminder_days: ritual.reminder_days
    });

    res.status(201).json(ritual);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Ritual could not be created' });
  } finally {
    client.release();
  }
};

// Ritüel güncelle
export const updateRitual = async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { name, reminder_time, reminder_days, steps } = req.body as any;
  const userId = req.user.id;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Ritüeli güncelle (Sadece kendi ritüelini güncelleyebilir)
    const result = await client.query(
      'UPDATE rituals SET name = COALESCE($1, name), reminder_time = COALESCE($2, reminder_time), reminder_days = COALESCE($3, reminder_days), updated_at = CURRENT_TIMESTAMP WHERE id = $4 AND user_id = $5 RETURNING *, user_id as profile_id',
      [name, reminder_time, reminder_days, id, userId]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Ritual not found or you are not authorized' });
    }

    const ritual = result.rows[0];

    // 2. Adımları güncelle
    if (steps && Array.isArray(steps)) {
      await client.query('DELETE FROM ritual_steps WHERE ritual_id = $1', [id]);

      for (let i = 0; i < steps.length; i++) {
        const step = steps[i];
        await client.query(
          'INSERT INTO ritual_steps (ritual_id, title, is_completed, order_index) VALUES ($1, $2, $3, $4)',
          [id, step.title || step.name, step.is_completed || false, i]
        );
      }
      ritual.steps = steps;
    } else {
      const stepsRes = await client.query('SELECT * FROM ritual_steps WHERE ritual_id = $1 ORDER BY order_index', [id]);
      ritual.steps = stepsRes.rows;
    }

    // 3. Partnership varsa partner ritüelini de güncelle
    const partnershipCheck = await client.query(
      `SELECT 
        CASE 
          WHEN ritual_id_1 = $1 THEN ritual_id_2
          WHEN ritual_id_2 = $1 THEN ritual_id_1
        END as partner_ritual_id,
        id as partnership_id
       FROM ritual_partnerships 
       WHERE (ritual_id_1 = $1 OR ritual_id_2 = $1) 
       AND status = 'active'`,
      [id]
    );

    if (partnershipCheck.rows.length > 0) {
      const partnerRitualId = partnershipCheck.rows[0].partner_ritual_id;
      const partnershipId = partnershipCheck.rows[0].partnership_id;

      // Partner ritüelini aynı şekilde güncelle
      await client.query(
        'UPDATE rituals SET name = COALESCE($1, name), reminder_time = COALESCE($2, reminder_time), reminder_days = COALESCE($3, reminder_days), updated_at = CURRENT_TIMESTAMP WHERE id = $4',
        [name, reminder_time, reminder_days, partnerRitualId]
      );

      // Partner ritüelinin adımlarını da güncelle
      if (steps && Array.isArray(steps)) {
        await client.query('DELETE FROM ritual_steps WHERE ritual_id = $1', [partnerRitualId]);

        for (let i = 0; i < steps.length; i++) {
          const step = steps[i];
          await client.query(
            'INSERT INTO ritual_steps (ritual_id, title, is_completed, order_index) VALUES ($1, $2, $3, $4)',
            [partnerRitualId, step.title || step.name, step.is_completed || false, i]
          );
        }
      }

      // Partnership scheduler'ı güncelle
      if (reminder_time) {
        cancelPartnershipStreakCheck(partnershipId);

        const partnerRitualData = await client.query(
          'SELECT user_id FROM rituals WHERE id = $1',
          [partnerRitualId]
        );

        if (partnerRitualData.rows.length > 0) {
          schedulePartnershipStreakCheck({
            partnership_id: partnershipId,
            ritual_id_1: id,
            user_id_1: userId,
            ritual_id_2: partnerRitualId,
            user_id_2: partnerRitualData.rows[0].user_id,
            ritual_name: ritual.name,
            reminder_time: ritual.reminder_time,
            reminder_days: ritual.reminder_days,
            current_streak: 0, // Will be fetched from DB by scheduler
            freeze_count: 0
          });
        }
      }
    } else {
      // Solo ritüel - sadece kendi scheduler'ını güncelle
      if (reminder_time) {
        cancelRitualStreakCheck(userId, id);
        scheduleRitualStreakCheck({
          user_id: ritual.user_id,
          ritual_id: ritual.id,
          ritual_name: ritual.name,
          reminder_time: ritual.reminder_time,
          reminder_days: ritual.reminder_days
        });
      }
    }

    await client.query('COMMIT');
    res.json(ritual);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Update failed' });
  } finally {
    client.release();
  }
};

// Ritüel sil
export const deleteRitual = async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    const result = await pool.query('DELETE FROM rituals WHERE id = $1 AND user_id = $2 RETURNING *', [id, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ritüel bulunamadı veya yetkiniz yok' });
    }

    // Cancel scheduled streak check for this ritual
    cancelRitualStreakCheck(userId, id);

    res.json({ message: 'Ritual deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Deletion failed' });
  }
};
