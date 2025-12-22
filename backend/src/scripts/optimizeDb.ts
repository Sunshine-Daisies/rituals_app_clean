import pool from '../config/db';

const optimizeDatabase = async () => {
    console.log('🚀 Starting Database Optimization...');
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        console.log('Creating Indexes...');

        // 1. User Profiles - XP Index for Leaderboards (CRITICAL)
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_user_profiles_xp 
      ON user_profiles (xp DESC);
    `);
        console.log('✅ Index created: idx_user_profiles_xp');

        // 2. User Badges - Foreign Keys
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_user_badges_user_id 
      ON user_badges (user_id);
    `);
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id 
      ON user_badges (badge_id);
    `);
        console.log('✅ Indexes created: user_badges(user_id, badge_id)');

        // 3. Rituals - User ID
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_rituals_user_id 
      ON rituals (user_id);
    `);
        console.log('✅ Index created: idx_rituals_user_id');

        // 4. Ritual Logs - Foreign Key & Date
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_ritual_logs_ritual_id 
      ON ritual_logs (ritual_id);
    `);
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_ritual_logs_completed_at 
      ON ritual_logs (completed_at);
    `);
        console.log('✅ Indexes created: ritual_logs(ritual_id, completed_at)');

        // 5. Friendships - Requester & Addressee
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_friendships_requester 
      ON friendships (requester_id);
    `);
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_friendships_addressee 
      ON friendships (addressee_id);
    `);
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_friendships_status 
      ON friendships (status);
    `);
        console.log('✅ Indexes created: friendships keys & status');

        await client.query('COMMIT');
        console.log('✨ Data optimization completed successfully!');

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ Error optimizing database:', error);
    } finally {
        client.release();
        process.exit(); // Close pool prevents hanging
    }
};

optimizeDatabase();
