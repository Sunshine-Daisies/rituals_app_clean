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

    // reset_password_token sütunu ekle
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS reset_password_token TEXT;
    `);

    // reset_password_expires sütunu ekle
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS reset_password_expires BIGINT;
    `);

    console.log('✅ Tablo güncellendi: reset_password_token ve reset_password_expires eklendi.');
  } catch (err) {
    console.error('❌ Hata:', err);
  } finally {
    await client.end();
  }
}

update();
