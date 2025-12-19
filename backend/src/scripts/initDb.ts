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

const createTablesQuery = `
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

  CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      is_premium BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS rituals (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      reminder_time TEXT,
      reminder_days TEXT[],
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS ritual_steps (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      is_completed BOOLEAN DEFAULT FALSE,
      order_index INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS ritual_logs (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
      step_index INTEGER,
      source TEXT,
      completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS llm_usage (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID REFERENCES users(id) ON DELETE CASCADE,
      model TEXT,
      tokens_in INTEGER,
      tokens_out INTEGER,
      session_id TEXT,
      intent TEXT,
      prompt_type TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS devices (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      profile_id UUID REFERENCES users(id) ON DELETE CASCADE,
      device_token TEXT NOT NULL,
      platform TEXT,
      app_version TEXT,
      locale TEXT,
      last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );
`;

async function setup() {
    const client = new Client(dbConfig);
    try {
        await client.connect();
        console.log('🔌 Veritabanına bağlanıldı.');

        await client.query(createTablesQuery);
        console.log('✅ Tablolar başarıyla oluşturuldu (veya zaten vardı)!');

        await client.end();
    } catch (err) {
        // Veritabanı yoksa oluşturmayı dene
        if ((err as any).code === '3D000') { // database does not exist
            console.log('⚠️ Veritabanı bulunamadı, oluşturuluyor...');
            await createDatabase();
        } else {
            console.error('❌ Hata:', err);
        }
    }
}

async function createDatabase() {
    const rootClient = new Client({
        ...dbConfig,
        database: 'postgres', // Varsayılan DB'ye bağlan
    });

    try {
        await rootClient.connect();
        await rootClient.query(`CREATE DATABASE ${dbConfig.database}`);
        console.log(`✅ Veritabanı '${dbConfig.database}' oluşturuldu.`);
        await rootClient.end();
        // Tekrar setup'ı çağır
        setup();
    } catch (error) {
        console.error('❌ Veritabanı oluşturulurken hata:', error);
    }
}

setup();
