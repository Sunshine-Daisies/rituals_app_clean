import { Client } from 'pg';
import dotenv from 'dotenv';
import path from 'path';

// .env dosyasını bir üst dizinden oku
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const client = new Client({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'rituals_db',
  password: process.env.DB_PASSWORD || '123456',
  port: parseInt(process.env.DB_PORT || '5432'),
});

async function seedBadges() {
  try {
    await client.connect();
    console.log('🔌 Veritabanına bağlanıldı.');

    // Tüm badge'leri ekle veya güncelle
    const badges = [
      // Streak Badges
      { key: 'streak_starter', name: 'Spark', desc: 'Reached a 3-day streak!', icon: '🔥', cat: 'streak', xp: 15, coin: 5, type: 'streak_days', val: 3 },
      { key: 'streak_week', name: 'Flame', desc: 'Reached a 7-day streak!', icon: '🔥🔥', cat: 'streak', xp: 30, coin: 10, type: 'streak_days', val: 7 },
      { key: 'streak_fortnight', name: 'Fireball', desc: 'Reached a 14-day streak!', icon: '🔥🔥🔥', cat: 'streak', xp: 50, coin: 20, type: 'streak_days', val: 14 },
      { key: 'streak_month', name: 'Meteor', desc: 'Reached a 30-day streak!', icon: '☄️', cat: 'streak', xp: 100, coin: 50, type: 'streak_days', val: 30 },
      { key: 'streak_legend', name: 'Legend', desc: 'Reached a 100-day streak!', icon: '💎', cat: 'streak', xp: 500, coin: 200, type: 'streak_days', val: 100 },
      
      // Social Badges
      { key: 'first_friend', name: 'First Friend', desc: 'Made your first friend!', icon: '🤝', cat: 'social', xp: 10, coin: 5, type: 'friends_count', val: 1 },
      { key: 'social_butterfly', name: 'Social Butterfly', desc: 'Reached 10 friends!', icon: '👥', cat: 'social', xp: 50, coin: 25, type: 'friends_count', val: 10 },
      { key: 'popular', name: 'Popular', desc: 'Reached 25 friends!', icon: '🌟', cat: 'social', xp: 100, coin: 50, type: 'friends_count', val: 25 },
      { key: 'team_player', name: 'Team Player', desc: 'Joined your first partner ritual!', icon: '🎯', cat: 'social', xp: 20, coin: 10, type: 'partner_rituals', val: 1 },
      { key: 'mentor', name: 'Mentor', desc: '5 people joined your ritual!', icon: '🏅', cat: 'social', xp: 100, coin: 50, type: 'ritual_partners', val: 5 },
      
      // Milestone Badges
      { key: 'first_ritual', name: 'Starter', desc: 'Completed your first ritual!', icon: '🎉', cat: 'milestone', xp: 15, coin: 5, type: 'rituals_completed', val: 1 },
      { key: 'ritual_30', name: 'Regular', desc: 'Completed 30 rituals!', icon: '📅', cat: 'milestone', xp: 50, coin: 25, type: 'rituals_completed', val: 30 },
      { key: 'collector', name: 'Collector', desc: 'Created 5 rituals!', icon: '📚', cat: 'milestone', xp: 30, coin: 15, type: 'rituals_created', val: 5 },
      { key: 'early_bird', name: 'Early Bird', desc: 'Completed 10 morning rituals!', icon: '🌅', cat: 'milestone', xp: 40, coin: 20, type: 'morning_rituals', val: 10 },
      { key: 'night_owl', name: 'Night Owl', desc: 'Completed 10 evening rituals!', icon: '🌙', cat: 'milestone', xp: 40, coin: 20, type: 'evening_rituals', val: 10 }
    ];

    for (const b of badges) {
      await client.query(`
        INSERT INTO badges (badge_key, name, description, icon, category, xp_reward, coin_reward, requirement_type, requirement_value)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (badge_key) DO UPDATE SET
          name = EXCLUDED.name,
          description = EXCLUDED.description,
          icon = EXCLUDED.icon,
          category = EXCLUDED.category,
          xp_reward = EXCLUDED.xp_reward,
          coin_reward = EXCLUDED.coin_reward,
          requirement_type = EXCLUDED.requirement_type,
          requirement_value = EXCLUDED.requirement_value;
      `, [b.key, b.name, b.desc, b.icon, b.cat, b.xp, b.coin, b.type, b.val]);
      
      console.log(`✅ ${b.key} badge updated.`);
    }

  } catch (err) {
    console.error('❌ Hata:', err);
  } finally {
    await client.end();
  }
}

seedBadges();
