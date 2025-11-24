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

async function update() {
  try {
    await client.connect();
    console.log('🔌 Veritabanına bağlanıldı.');

    // is_verified sütunu ekle
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
    `);

    // verification_token sütunu ekle
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS verification_token TEXT;
    `);

    console.log('✅ Tablo güncellendi: is_verified ve verification_token eklendi.');
  } catch (err) {
    console.error('❌ Hata:', err);
  } finally {
    await client.end();
  }
}

update();
