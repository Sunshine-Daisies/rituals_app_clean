import { Request, Response } from 'express';
import pool from '../config/db';

export const setupFullDatabase = async (req: Request, res: Response) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ============================================
    // 0. CORE TABLES & MIGRATIONS (Fixing missing columns)
    // ============================================

    // Ensure users table exists (Basic schema)
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Add missing columns to users
    await client.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_token TEXT;`);
    await client.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;`);

    // Ensure rituals table exists
    await client.query(`
      CREATE TABLE IF NOT EXISTS rituals (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID REFERENCES users(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          reminder_time TEXT,
          reminder_days TEXT[],
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          is_public BOOLEAN DEFAULT FALSE,
          current_streak INTEGER DEFAULT 0,
          longest_streak INTEGER DEFAULT 0
      );
    `);

    // Add missing columns to rituals (Migration)
    await client.query(`ALTER TABLE rituals ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;`);
    await client.query(`ALTER TABLE rituals ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0;`);
    await client.query(`ALTER TABLE rituals ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;`);

    // Ensure ritual_logs table exists
    await client.query(`
      CREATE TABLE IF NOT EXISTS ritual_logs (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
          step_index INTEGER,
          source TEXT,
          completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Add user_id to ritual_logs if missing
    await client.query(`ALTER TABLE ritual_logs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;`);

    // ============================================
    // 1. GAMIFICATION TABLES
    // ============================================
    
    // user_profiles
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
        current_streak INTEGER DEFAULT 0,
        last_freeze_used TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // friendships
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
    await client.query(`CREATE INDEX IF NOT EXISTS idx_friendships_requester ON friendships(requester_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON friendships(addressee_id);`);

    // shared_rituals
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

    // ritual_partners
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

    // freeze_logs
    await client.query(`
      CREATE TABLE IF NOT EXISTS freeze_logs (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        ritual_partner_id INTEGER REFERENCES ritual_partners(id),
        streak_saved INTEGER,
        used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // badges
    await client.query(`
      CREATE TABLE IF NOT EXISTS badges (
        id SERIAL PRIMARY KEY,
        badge_key VARCHAR(50) UNIQUE,
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

    // user_badges
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_badges (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        badge_id INTEGER REFERENCES badges(id) ON DELETE CASCADE,
        earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, badge_id)
      );
    `);

    // xp_history
    await client.query(`
      CREATE TABLE IF NOT EXISTS xp_history (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        amount INTEGER NOT NULL,
        source VARCHAR(100),
        source_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_xp_history_user ON xp_history(user_id);`);

    // coin_history
    await client.query(`
      CREATE TABLE IF NOT EXISTS coin_history (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        amount INTEGER NOT NULL,
        source VARCHAR(100),
        source_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_coin_history_user ON coin_history(user_id);`);

    // notifications
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
    await client.query(`CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;`);

    // freeze_history
    await client.query(`
      CREATE TABLE IF NOT EXISTS freeze_history (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        streak_preserved INTEGER DEFAULT 0,
        used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_freeze_history_user ON freeze_history(user_id);`);

    // Alter rituals table
    await client.query(`ALTER TABLE rituals ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;`);

    // Seed Badges
    const badgeCheck = await client.query('SELECT COUNT(*) FROM badges');
    if (parseInt(badgeCheck.rows[0].count) === 0) {
      await client.query(`
        INSERT INTO badges (badge_key, name, description, icon, category, xp_reward, coin_reward, requirement_type, requirement_value) VALUES
        ('streak_starter', 'Kıvılcım', '3 günlük streak''e ulaştın!', '🔥', 'streak', 15, 5, 'streak_days', 3),
        ('streak_week', 'Alev', '7 günlük streak''e ulaştın!', '🔥🔥', 'streak', 30, 10, 'streak_days', 7),
        ('streak_fortnight', 'Ateş Topu', '14 günlük streak''e ulaştın!', '🔥🔥🔥', 'streak', 50, 20, 'streak_days', 14),
        ('streak_month', 'Meteor', '30 günlük streak''e ulaştın!', '☄️', 'streak', 100, 50, 'streak_days', 30),
        ('streak_legend', 'Efsane', '100 günlük streak''e ulaştın!', '💎', 'streak', 500, 200, 'streak_days', 100),
        ('first_friend', 'İlk Arkadaş', 'İlk arkadaşını edindin!', '🤝', 'social', 10, 5, 'friends_count', 1),
        ('social_butterfly', 'Sosyal Kelebek', '10 arkadaşa ulaştın!', '👥', 'social', 50, 25, 'friends_count', 10),
        ('popular', 'Popüler', '25 arkadaşa ulaştın!', '🌟', 'social', 100, 50, 'friends_count', 25),
        ('team_player', 'Takım Oyuncusu', 'İlk partner ritualine katıldın!', '🎯', 'social', 20, 10, 'partner_rituals', 1),
        ('mentor', 'Mentor', '5 kişi ritualine katıldı!', '🏅', 'social', 100, 50, 'ritual_partners', 5),
        ('first_ritual', 'Başlangıç', 'İlk ritualini tamamladın!', '🎉', 'milestone', 15, 5, 'rituals_completed', 1),
        ('ritual_30', 'Düzenli', '30 ritual tamamladın!', '📅', 'milestone', 50, 25, 'rituals_completed', 30),
        ('collector', 'Koleksiyoncu', '5 ritual oluşturdun!', '📚', 'milestone', 30, 15, 'rituals_created', 5),
        ('early_bird', 'Sabahçı', '10 sabah rituali tamamladın!', '🌅', 'milestone', 40, 20, 'morning_rituals', 10),
        ('night_owl', 'Gececi', '10 akşam rituali tamamladın!', '🌙', 'milestone', 40, 20, 'evening_rituals', 10);
      `);
    }

    // Create profiles for existing users
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

    // ============================================
    // 2. PARTNERSHIP TABLES (Migration)
    // ============================================

    // ritual_partnerships
    await client.query(`
      CREATE TABLE IF NOT EXISTS ritual_partnerships (
        id SERIAL PRIMARY KEY,
        ritual_id_1 UUID REFERENCES rituals(id) ON DELETE CASCADE,
        user_id_1 UUID REFERENCES users(id) ON DELETE CASCADE,
        ritual_id_2 UUID REFERENCES rituals(id) ON DELETE CASCADE,
        user_id_2 UUID REFERENCES users(id) ON DELETE CASCADE,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        freeze_count INTEGER DEFAULT 2,
        last_both_completed_at TIMESTAMP,
        status VARCHAR(20) DEFAULT 'active',
        ended_by UUID REFERENCES users(id),
        ended_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(ritual_id_1, ritual_id_2)
      );
    `);

    // Add missing columns to ritual_partnerships (Migration)
    await client.query(`ALTER TABLE ritual_partnerships ADD COLUMN IF NOT EXISTS freeze_count INTEGER DEFAULT 2;`);

    // ritual_invites
    await client.query(`
      CREATE TABLE IF NOT EXISTS ritual_invites (
        id SERIAL PRIMARY KEY,
        ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        invite_code VARCHAR(20) UNIQUE NOT NULL,
        is_used BOOLEAN DEFAULT FALSE,
        used_by UUID REFERENCES users(id),
        used_at TIMESTAMP,
        expires_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // partnership_requests
    await client.query(`
      CREATE TABLE IF NOT EXISTS partnership_requests (
        id SERIAL PRIMARY KEY,
        inviter_ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
        inviter_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        invitee_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        invitee_ritual_id UUID REFERENCES rituals(id) ON DELETE SET NULL,
        invite_id INTEGER REFERENCES ritual_invites(id),
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        responded_at TIMESTAMP,
        UNIQUE(inviter_ritual_id, invitee_user_id)
      );
    `);

    await client.query('COMMIT');
    res.send('✅ All tables (Gamification & Partnerships) created successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Setup error:', error);
    res.status(500).send('Error setting up database: ' + error);
  } finally {
    client.release();
  }
};
