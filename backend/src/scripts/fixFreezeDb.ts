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

async function fixFreezeDb() {
  try {
    await client.connect();
    console.log('🔌 Veritabanına bağlanıldı.');

    // 1. ritual_partnerships tablosuna last_freeze_used ekle
    console.log('Checking ritual_partnerships...');
    await client.query(`
      ALTER TABLE ritual_partnerships 
      ADD COLUMN IF NOT EXISTS last_freeze_used TIMESTAMP;
    `);
    console.log('✅ ritual_partnerships.last_freeze_used added/verified.');

    // 2. user_profiles tablosuna last_freeze_used ekle (kişisel streak için)
    console.log('Checking user_profiles...');
    await client.query(`
      ALTER TABLE user_profiles 
      ADD COLUMN IF NOT EXISTS last_freeze_used TIMESTAMP;
    `);
    console.log('✅ user_profiles.last_freeze_used added/verified.');

    // 3. freeze_logs tablosunu kontrol et (freeze_history yerine)
    console.log('Checking freeze_logs...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS freeze_logs (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        partnership_id INTEGER REFERENCES ritual_partnerships(id),
        streak_saved INTEGER,
        used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ freeze_logs table verified.');

  } catch (err) {
    console.error('❌ Hata:', err);
  } finally {
    await client.end();
  }
}

fixFreezeDb();
