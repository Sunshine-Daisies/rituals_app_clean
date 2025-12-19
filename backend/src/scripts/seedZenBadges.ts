import pool from '../config/db';

async function seedZenBadges() {
    const client = await pool.connect();

    try {
        console.log('🧘 Starting Zen Badges seeding...\n');

        await client.query('BEGIN');

        // 1. Mevcut kazanılmış rozetleri ve tanımları sil (Kullanıcı verilerini sıfırlarız çünkü set tamamen değişti)
        console.log('🧹 Clearing old badges and user earnings...');
        await client.query('TRUNCATE TABLE user_badges CASCADE');
        await client.query('DELETE FROM badges');
        console.log('✅ Old data cleared\n');

        // 2. Yeni Zen Rozetlerini ekle
        console.log('🌱 Inserting new Zen badges...');
        await client.query(`
      INSERT INTO badges (badge_key, name, description, icon, category, xp_reward, coin_reward, requirement_type, requirement_value) VALUES
      -- Streak Badges
      ('zen_seed', 'Zen Seed', 'Reached a 3-day streak. The journey begins.', '🌱', 'streak', 20, 5, 'streak', 3),
      ('zen_sprout', 'Zen Sprout', '7 days of discipline. Your roots are strengthening.', '🌿', 'streak', 40, 10, 'streak', 7),
      ('zen_flower', 'Zen Flower', '14-day streak. Your practice is blooming.', '🌸', 'streak', 80, 25, 'streak', 14),
      ('zen_mountain', 'Zen Mountain', '30 days! You have reached unshakable resolve.', '⛰️', 'streak', 200, 50, 'streak', 30),
      ('zen_eternal', 'Zen Eternal', '100 days of ritual mastery.', '💎', 'streak', 1000, 250, 'streak', 100),
      
      -- Social Badges
      ('zen_companion', 'Zen Companion', 'Made your first friend. Walking together is easier.', '🤝', 'social', 25, 5, 'friends', 1),
      ('zen_sangha', 'Zen Sangha', 'Reached 10 friends. Grow with the power of community.', '🏘️', 'social', 150, 50, 'friends', 10),
      
      -- Milestone Badges
      ('zen_initiation', 'Initiation', 'Broke the silence and completed your first ritual.', '🔔', 'milestone', 15, 5, 'completions', 1),
      ('zen_lotus', 'Zen Lotus', '50 rituals completed. From chaos to purity.', '🧘', 'milestone', 100, 40, 'completions', 50),
      ('zen_harmonization', 'Harmonization', 'Created 5 rituals to find your own flow.', '🎨', 'milestone', 50, 20, 'rituals_created', 5),
      
      -- Partner Badges
      ('zen_duo', 'Duo Harmony', 'Joined your first partner ritual.', '☯️', 'social', 30, 10, 'partner_rituals', 1),
      ('zen_unity', 'Zen Unity', 'Reached a 7-day streak with your partner.', '✨', 'social', 100, 30, 'partner_streak', 7);
    `);

        await client.query('COMMIT');
        console.log('✅ Zen badges seeded successfully (14 badges)\n');

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ Error seeding Zen badges:', error);
        throw error;
    } finally {
        client.release();
        await pool.end();
    }
}

seedZenBadges();
