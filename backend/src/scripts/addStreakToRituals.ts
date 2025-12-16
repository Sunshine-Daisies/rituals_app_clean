import { Client } from 'pg';
import dotenv from 'dotenv';
import path from 'path';

// .env dosyasını bir üst dizinden oku
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const dbConfig = {
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'rituals_db',
  password: process.env.DB_PASSWORD || '123456',
  port: parseInt(process.env.DB_PORT || '5432'),
};

async function migrate() {
  const client = new Client(dbConfig);
  try {
    await client.connect();
    console.log('🔌 Veritabanına bağlanıldı.');

    // Check if columns exist
    const checkQuery = `
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name='rituals' AND column_name='current_streak';
    `;
    
    const res = await client.query(checkQuery);
    
    if (res.rows.length === 0) {
      console.log('Adding streak columns to rituals table...');
      await client.query(`
        ALTER TABLE rituals 
        ADD COLUMN current_streak INTEGER DEFAULT 0,
        ADD COLUMN longest_streak INTEGER DEFAULT 0;
      `);
      console.log('✅ Columns added successfully!');
    } else {
      console.log('⚠️ Columns already exist.');
    }
    
    await client.end();
  } catch (err) {
    console.error('❌ Hata:', err);
    process.exit(1);
  }
}

migrate();
