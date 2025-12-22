import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

let pool: Pool;

if (process.env.DATABASE_URL) {
  // Railway veya Production ortamı (Tek satırlık bağlantı)
  console.log('🌍 Connecting to database using DATABASE_URL...');
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: false // Railway SSL gerektirir
    },
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  });
} else {
  // Local Development ortamı (Ayrı ayrı değişkenler)
  console.log('💻 Connecting to database using individual variables...');
  pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'rituals_db',
    password: process.env.DB_PASSWORD || '123456',
    port: parseInt(process.env.DB_PORT || '5432'),
    max: 20, // Max concurrent connections
    idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
    connectionTimeoutMillis: 2000, // Return an error after 2 seconds if connection could not be established
  });
}

pool.on('connect', () => {
  console.log('✅ Database connected successfully');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

export default pool;
