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
    console.log('Seeding data for nuriokumuş...');

    // 1. Find User
    // Try exact match first
    let userResult = await pool.query("SELECT user_id FROM user_profiles WHERE username = 'nuriokumuş'");
    
    let userId;
    if (userResult.rows.length === 0) {
      console.log('User nuriokumuş not found!');
      
      // Try fuzzy match or specific alternative
      userResult = await pool.query("SELECT user_id, username FROM user_profiles WHERE username LIKE '%nuri%' LIMIT 1");
      
      if (userResult.rows.length > 0) {
         console.log(`Found similar user: ${userResult.rows[0].username}`);
         userId = userResult.rows[0].user_id;
      } else {
          // List existing users
          const allUsers = await pool.query("SELECT username, user_id FROM user_profiles LIMIT 5");
          if (allUsers.rows.length > 0) {
            console.log('Available users:', allUsers.rows.map(r => r.username).join(', '));
            console.log(`Falling back to user: ${allUsers.rows[0].username}`);
            userId = allUsers.rows[0].user_id;
          } else {
            console.error('No users found in the database. Please register a user in the app first.');
            process.exit(1);
          }
      }
    } else {
      userId = userResult.rows[0].user_id;
    }

    console.log(`Using user ID: ${userId}`);

    // 2. Create Rituals
    const rituals = [
      { name: 'Sabah Meditasyonu', streak: 5 },
      { name: 'Kitap Okuma', streak: 12 },
      { name: 'Su İçme', streak: 3 },
      { name: 'Yürüyüş', streak: 0 },
      { name: 'Kodlama', streak: 20 }
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
        // reminder_days: [1,2,3,4,5,6,7] for daily
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
    
    // Clear existing logs for these rituals to avoid duplicates/mess
    // await pool.query("DELETE FROM ritual_logs WHERE ritual_id = ANY($1)", [ritualIds]);

    const today = new Date();
    
    for (let i = 0; i < 30; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      
      // Randomly decide which rituals were done on this day
      // Higher probability for recent days to simulate consistency
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

    console.log('Seeding completed successfully!');
  } catch (error) {
    console.error('Error seeding data:', error);
  } finally {
    await pool.end();
  }
};

seedData();
