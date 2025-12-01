import pool from '../config/db';

async function initGamification() {
  const client = await pool.connect();
  
  try {
    console.log('🎮 Starting Gamification tables initialization...\n');

    // ============================================
    // 1. USER PROFILES
    // ============================================
    console.log('📊 Creating user_profiles table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_profiles (
        id SERIAL PRIMARY KEY,
        user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        username VARCHAR(50) UNIQUE NOT NULL,
        xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        coins INTEGER DEFAULT 0,
        freeze_count INTEGER DEFAULT 2,
        total_freezes_used INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ user_profiles table created\n');

    // ============================================
    // 2. FRIENDSHIPS
    // ============================================
    console.log('👥 Creating friendships table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS friendships (
        id SERIAL PRIMARY KEY,
        requester_id UUID REFERENCES users(id) ON DELETE CASCADE,
        addressee_id UUID REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        accepted_at TIMESTAMP,
        UNIQUE(requester_id, addressee_id)
      );
    `);
    
    // Index for faster friend lookups
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_friendships_requester ON friendships(requester_id);
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON friendships(addressee_id);
    `);
    console.log('✅ friendships table created\n');

    // ============================================
    // 3. SHARED RITUALS
    // ============================================
    console.log('🔗 Creating shared_rituals table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS shared_rituals (
        id SERIAL PRIMARY KEY,
        ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
        owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
        invite_code VARCHAR(20) UNIQUE,
        is_public BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ shared_rituals table created\n');

    // ============================================
    // 4. RITUAL PARTNERS
    // ============================================
    console.log('🤝 Creating ritual_partners table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS ritual_partners (
        id SERIAL PRIMARY KEY,
        shared_ritual_id INTEGER REFERENCES shared_rituals(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(20) DEFAULT 'pending',
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        last_completed_at TIMESTAMP,
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(shared_ritual_id, user_id)
      );
    `);
    console.log('✅ ritual_partners table created\n');

    // ============================================
    // 5. FREEZE LOGS
    // ============================================
    console.log('❄️ Creating freeze_logs table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS freeze_logs (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        ritual_partner_id INTEGER REFERENCES ritual_partners(id),
        streak_saved INTEGER,
        used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ freeze_logs table created\n');

    // ============================================
    // 6. BADGES
    // ============================================
    console.log('🏆 Creating badges table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS badges (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        icon VARCHAR(50),
        category VARCHAR(50),
        xp_reward INTEGER DEFAULT 0,
        coin_reward INTEGER DEFAULT 0,
        requirement_type VARCHAR(50),
        requirement_value INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ badges table created\n');

    // ============================================
    // 7. USER BADGES
    // ============================================
    console.log('🎖️ Creating user_badges table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_badges (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        badge_id INTEGER REFERENCES badges(id) ON DELETE CASCADE,
        earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, badge_id)
      );
    `);
    console.log('✅ user_badges table created\n');

    // ============================================
    // 8. XP HISTORY
    // ============================================
    console.log('📈 Creating xp_history table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS xp_history (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        amount INTEGER NOT NULL,
        source VARCHAR(100),
        source_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_xp_history_user ON xp_history(user_id);
    `);
    console.log('✅ xp_history table created\n');

    // ============================================
    // 9. COIN HISTORY
    // ============================================
    console.log('🪙 Creating coin_history table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS coin_history (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        amount INTEGER NOT NULL,
        source VARCHAR(100),
        source_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_coin_history_user ON coin_history(user_id);
    `);
    console.log('✅ coin_history table created\n');

    // ============================================
    // 10. NOTIFICATIONS
    // ============================================
    console.log('🔔 Creating notifications table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(200),
        body TEXT,
        data JSONB,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
    `);
    console.log('✅ notifications table created\n');

    // ============================================
    // 11. ALTER RITUALS TABLE
    // ============================================
    console.log('📝 Adding is_public column to rituals table...');
    await client.query(`
      ALTER TABLE rituals ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;
    `);
    console.log('✅ rituals table updated\n');

    // ============================================
    // 12. SEED BADGES DATA
    // ============================================
    console.log('🌱 Seeding badges data...');
    
    // Check if badges already exist
    const badgeCheck = await client.query('SELECT COUNT(*) FROM badges');
    if (parseInt(badgeCheck.rows[0].count) === 0) {
      await client.query(`
        INSERT INTO badges (name, description, icon, category, xp_reward, coin_reward, requirement_type, requirement_value) VALUES
        -- Streak Badges
        ('Kıvılcım', '3 günlük streak''e ulaştın!', '🔥', 'streak', 15, 5, 'streak_days', 3),
        ('Alev', '7 günlük streak''e ulaştın!', '🔥🔥', 'streak', 30, 10, 'streak_days', 7),
        ('Ateş Topu', '14 günlük streak''e ulaştın!', '🔥🔥🔥', 'streak', 50, 20, 'streak_days', 14),
        ('Meteor', '30 günlük streak''e ulaştın!', '☄️', 'streak', 100, 50, 'streak_days', 30),
        ('Efsane', '100 günlük streak''e ulaştın!', '💎', 'streak', 500, 200, 'streak_days', 100),
        
        -- Social Badges
        ('İlk Arkadaş', 'İlk arkadaşını edindin!', '🤝', 'social', 10, 5, 'friends_count', 1),
        ('Sosyal Kelebek', '10 arkadaşa ulaştın!', '👥', 'social', 50, 25, 'friends_count', 10),
        ('Popüler', '25 arkadaşa ulaştın!', '🌟', 'social', 100, 50, 'friends_count', 25),
        ('Takım Oyuncusu', 'İlk partner ritualine katıldın!', '🎯', 'social', 20, 10, 'partner_rituals', 1),
        ('Mentor', '5 kişi ritualine katıldı!', '🏅', 'social', 100, 50, 'ritual_partners', 5),
        
        -- Milestone Badges
        ('Başlangıç', 'İlk ritualini tamamladın!', '🎉', 'milestone', 15, 5, 'rituals_completed', 1),
        ('Düzenli', '30 ritual tamamladın!', '📅', 'milestone', 50, 25, 'rituals_completed', 30),
        ('Koleksiyoncu', '5 ritual oluşturdun!', '📚', 'milestone', 30, 15, 'rituals_created', 5),
        ('Sabahçı', '10 sabah rituali tamamladın!', '🌅', 'milestone', 40, 20, 'morning_rituals', 10),
        ('Gececi', '10 akşam rituali tamamladın!', '🌙', 'milestone', 40, 20, 'evening_rituals', 10);
      `);
      console.log('✅ Badges seeded (15 badges)\n');
    } else {
      console.log('⏭️ Badges already exist, skipping seed\n');
    }

    // ============================================
    // 13. CREATE USER PROFILES FOR EXISTING USERS
    // ============================================
    console.log('👤 Creating profiles for existing users...');
    await client.query(`
      INSERT INTO user_profiles (user_id, username)
      SELECT id, COALESCE(
        LOWER(REPLACE(SPLIT_PART(email, '@', 1), '.', '_')),
        'user_' || SUBSTRING(id::text, 1, 8)
      ) || '_' || FLOOR(RANDOM() * 1000)::TEXT
      FROM users
      WHERE id NOT IN (SELECT user_id FROM user_profiles WHERE user_id IS NOT NULL)
      ON CONFLICT (user_id) DO NOTHING;
    `);
    console.log('✅ User profiles created for existing users\n');

    console.log('═══════════════════════════════════════════');
    console.log('🎮 Gamification initialization completed!');
    console.log('═══════════════════════════════════════════\n');

  } catch (error) {
    console.error('❌ Error initializing gamification:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

initGamification();
