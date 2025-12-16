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

const seedData = async () => {
  try {
    console.log('Seeding data for testuser_121...');

    // 1. Find User
    const userResult = await pool.query("SELECT user_id FROM user_profiles WHERE username = 'testuser_121'");
    
    if (userResult.rows.length === 0) {
      console.error('User testuser_121 not found!');
      process.exit(1);
    }

    const userId = userResult.rows[0].user_id;
    console.log(`Found user ID: ${userId}`);

    // 2. Create Rituals
    const rituals = [
      { name: 'Morning Meditation', streak: 5 },
      { name: 'Reading Book', streak: 12 },
      { name: 'Drink Water', streak: 3 },
      { name: 'Walking', streak: 0 },
      { name: 'Coding', streak: 20 }
    ];

    const ritualIds = [];

    for (const r of rituals) {
      // Check if exists
      let ritualResult = await pool.query(
        "SELECT id FROM rituals WHERE user_id = $1 AND name = $2",
        [userId, r.name]
      );

      let ritualId;
      if (ritualResult.rows.length > 0) {
        ritualId = ritualResult.rows[0].id;
        // Update streak
        await pool.query("UPDATE rituals SET current_streak = $1 WHERE id = $2", [r.streak, ritualId]);
      } else {
        // Create
        ritualResult = await pool.query(
          "INSERT INTO rituals (user_id, name, reminder_time, reminder_days, current_streak) VALUES ($1, $2, '09:00', $3, $4) RETURNING id",
          [userId, r.name, [1,2,3,4,5,6,7], r.streak]
        );
        ritualId = ritualResult.rows[0].id;
      }
      ritualIds.push(ritualId);
      console.log(`Ritual processed: ${r.name} (ID: ${ritualId})`);
    }

    // 3. Create Logs (Last 30 days)
    console.log('Generating logs...');
    
    const today = new Date();
    
    for (let i = 0; i < 30; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      
      const probability = 0.7; 

      for (const ritualId of ritualIds) {
        if (Math.random() < probability) {
          // Check if log exists
          const logCheck = await pool.query(
            "SELECT id FROM ritual_logs WHERE ritual_id = $1 AND DATE(completed_at) = DATE($2)",
            [ritualId, date]
          );

          if (logCheck.rows.length === 0) {
             await pool.query(
              "INSERT INTO ritual_logs (ritual_id, completed_at) VALUES ($1, $2)",
              [ritualId, date]
            );
          }
        }
      }
    }

    // 4. Update User Profile Stats
    await pool.query(
      "UPDATE user_profiles SET longest_streak = 25 WHERE user_id = $1",
      [userId]
    );

    console.log('Seeding completed successfully for testuser_121!');
  } catch (error) {
    console.error('Error seeding data:', error);
  } finally {
    await pool.end();
  }
};

seedData();
