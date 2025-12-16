import { Pool, PoolConfig } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const dbConfig: PoolConfig = process.env.DATABASE_URL
  ? { 
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false } // Railway için genelde gereklidir
    }
  : {
      user: process.env.DB_USER || 'postgres',
      host: process.env.DB_HOST || 'localhost',
      database: process.env.DB_NAME || 'rituals_db',
      password: process.env.DB_PASSWORD || '123456',
      port: parseInt(process.env.DB_PORT || '5432'),
    };

const pool = new Pool(dbConfig);

pool.on('connect', () => {
  console.log('Veritabanına bağlandı');
});

pool.on('error', (err) => {
  console.error('Beklenmeyen veritabanı hatası', err);
  process.exit(-1);
});

export default pool;
