import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import pool from '../config/db';

// Register or update device
export const registerDevice = async (req: AuthRequest, res: Response) => {
  const { device_token, platform, app_version, locale } = req.body;
  const userId = req.user.id;

  try {
    // Check if device exists
    const existingDevice = await pool.query(
      'SELECT * FROM devices WHERE device_token = $1 AND profile_id = $2',
      [device_token, userId]
    );

    if (existingDevice.rows.length > 0) {
      // Update
      const updatedDevice = await pool.query(
        'UPDATE devices SET platform = $1, app_version = $2, locale = $3, last_seen = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = $4 RETURNING *',
        [platform, app_version, locale, existingDevice.rows[0].id]
      );
      return res.json(updatedDevice.rows[0]);
    } else {
      // Create
      const newDevice = await pool.query(
        'INSERT INTO devices (profile_id, device_token, platform, app_version, locale) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [userId, device_token, platform, app_version, locale]
      );
      return res.status(201).json(newDevice.rows[0]);
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Device could not be registered' });
  }
};

// Update last seen
export const updateLastSeen = async (req: AuthRequest, res: Response) => {
  const { deviceId } = req.params;
  const userId = req.user.id;

  try {
    await pool.query(
      'UPDATE devices SET last_seen = CURRENT_TIMESTAMP WHERE id = $1 AND profile_id = $2',
      [deviceId, userId]
    );
    res.json({ message: 'Last seen updated' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Update failed' });
  }
};
