import pool from '../config/db';

const initNotifications = async () => {
  console.log('🔔 Initializing notification tables...');

  try {
    // user_fcm_tokens tablosu
    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_fcm_tokens (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        fcm_token TEXT NOT NULL,
        device_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, fcm_token)
      );
    `);
    console.log('✅ user_fcm_tokens table created/verified');

    // notifications tablosu güncelle (data kolonu ekle)
    await pool.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'notifications' AND column_name = 'data'
        ) THEN
          ALTER TABLE notifications ADD COLUMN data JSONB;
        END IF;
      END $$;
    `);
    console.log('✅ notifications table updated with data column');

    // notifications tablosunda title kolonu kontrol et
    await pool.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'notifications' AND column_name = 'title'
        ) THEN
          ALTER TABLE notifications ADD COLUMN title TEXT;
        END IF;
      END $$;
    `);
    console.log('✅ notifications table has title column');

    // Index oluştur
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
      CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
      CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read);
    `);
    console.log('✅ Indexes created');

    console.log('🎉 Notification tables initialized successfully!');
  } catch (error) {
    console.error('❌ Error initializing notification tables:', error);
    throw error;
  }
};

// Script doğrudan çalıştırılırsa
if (require.main === module) {
  initNotifications()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

export default initNotifications;
