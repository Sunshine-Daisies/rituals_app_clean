import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import pool from '../config/db';

// Log a ritual completion
export const logCompletion = async (req: AuthRequest, res: Response) => {
  const { ritual_id, step_index, source, completed_at } = req.body;
  
  try {
    const result = await pool.query(
      'INSERT INTO ritual_logs (ritual_id, step_index, source, completed_at) VALUES ($1, $2, $3, $4) RETURNING *',
      [ritual_id, step_index, source, completed_at || new Date()]
    );
    
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
