import pool from '../config/db';

/**
 * partnership_requests tablosuna invitee_ritual_id kolonu ekler
 */
async function addInviteeRitualIdColumn() {
  const client = await pool.connect();
  
  try {
    console.log('🔧 Adding invitee_ritual_id column to partnership_requests...');
    
    await client.query(`
      ALTER TABLE partnership_requests 
      ADD COLUMN IF NOT EXISTS invitee_ritual_id UUID REFERENCES rituals(id) ON DELETE SET NULL;
    `);
    
    console.log('✅ Column added successfully!');
  } catch (error) {
    console.error('❌ Error adding column:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Script'i çalıştır
addInviteeRitualIdColumn()
  .then(() => {
    console.log('\n✨ Migration completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Migration failed:', error);
    process.exit(1);
  });
