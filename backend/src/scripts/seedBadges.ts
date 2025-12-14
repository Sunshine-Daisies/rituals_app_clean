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

    // first_friend badge'ini ekle veya güncelle
    await client.query(`
      INSERT INTO badges (badge_key, name, description, icon, category, xp_reward, coin_reward, requirement_type, requirement_value)
      VALUES (
        'first_friend', 
        'İlk Arkadaş', 
        'İlk arkadaşını ekle', 
        '👋', 
        'social', 
        25, 
        5, 
        'friends', 
        1
      )
      ON CONFLICT (badge_key) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        icon = EXCLUDED.icon,
        category = EXCLUDED.category,
        xp_reward = EXCLUDED.xp_reward,
        coin_reward = EXCLUDED.coin_reward,
        requirement_type = EXCLUDED.requirement_type,
        requirement_value = EXCLUDED.requirement_value;
    `);
    
    console.log('✅ first_friend badge eklendi/güncellendi.');

  } catch (err) {
    console.error('❌ Hata:', err);
  } finally {
    await client.end();
  }
}

seedBadges();
