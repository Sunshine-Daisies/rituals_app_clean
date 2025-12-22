import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import pool from '../config/db';

// Log LLM usage
export const logUsage = async (req: AuthRequest, res: Response) => {
  const { model, tokens_in, tokens_out, session_id, intent, prompt_type } = req.body;
  const userId = req.user.id;

  try {
    const result = await pool.query(
      'INSERT INTO llm_usage (user_id, model, tokens_in, tokens_out, session_id, intent, prompt_type) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [userId, model, tokens_in, tokens_out, session_id, intent, prompt_type]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to log LLM usage' });
  }
};

// Get usage stats
export const getUsage = async (req: AuthRequest, res: Response) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      'SELECT * FROM llm_usage WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve usage data' });
  }
};
