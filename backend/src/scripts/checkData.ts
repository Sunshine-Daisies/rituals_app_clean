import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'rituals_db',
  password: process.env.DB_PASSWORD || '123456',
  port: parseInt(process.env.DB_PORT || '5432'),
});

const checkData = async () => {
  try {
    console.log('Checking data...');

    // 1. List all users and their stats
    const users = await pool.query(`
      SELECT up.username, up.user_id, 
             (SELECT COUNT(*) FROM rituals r WHERE r.user_id = up.user_id) as ritual_count,
             (SELECT COUNT(*) FROM ritual_logs rl JOIN rituals r ON rl.ritual_id = r.id WHERE r.user_id = up.user_id) as log_count
      FROM user_profiles up
    `);

    console.table(users.rows);

  } catch (error) {
    console.error('Error checking data:', error);
  } finally {
    await pool.end();
  }
};

checkData();
