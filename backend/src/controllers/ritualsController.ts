import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import pool from '../config/db';
import { Ritual } from '../types/ritual';

// Tüm ritüelleri getir
export const getRituals = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user.id;
    const query = `
      SELECT 
        r.*, 
        r.user_id as profile_id,
        COALESCE(
          (
            SELECT json_agg(s.* ORDER BY s.order_index)
            FROM ritual_steps s
            WHERE s.ritual_id = r.id
          ),
          '[]'
        ) as steps
      FROM rituals r
      WHERE r.user_id = $1
      ORDER BY r.created_at DESC
    `;
    const result = await pool.query(query, [userId]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Ritüeller alınırken hata oluştu' });
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
    res.status(201).json(ritual);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Ritüel oluşturulamadı' });
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
      return res.status(404).json({ error: 'Ritüel bulunamadı veya yetkiniz yok' });
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

    await client.query('COMMIT');
    res.json(ritual);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Güncelleme başarısız' });
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

    res.json({ message: 'Ritüel silindi' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Silme işlemi başarısız' });
  }
};
