import pool from '../config/db';

/**
 * Migration: Owner-Partner modelinden Eşit Partner modeline geçiş
 * 
 * Yeni Model:
 * - Her kullanıcının KENDİ ritüeli var
 * - ritual_partnerships tablosu iki ritüeli birbirine bağlar
 * - Ayrılınca her iki taraf kendi ritüeline devam eder
 * - İkisi de eşit yetkilere sahip (düzenleme, silme kendi ritüelinde)
 */

async function migrateToEqualPartners() {
  const client = await pool.connect();
  
  try {
    console.log('🔄 Starting migration to Equal Partners model...\n');

    await client.query('BEGIN');

    // ============================================
    // 1. YENİ TABLO: ritual_partnerships
    // ============================================
    console.log('🤝 Creating ritual_partnerships table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS ritual_partnerships (
        id SERIAL PRIMARY KEY,
        
        -- Her iki tarafın ritüeli
        ritual_id_1 UUID REFERENCES rituals(id) ON DELETE CASCADE,
        user_id_1 UUID REFERENCES users(id) ON DELETE CASCADE,
        
        ritual_id_2 UUID REFERENCES rituals(id) ON DELETE CASCADE,
        user_id_2 UUID REFERENCES users(id) ON DELETE CASCADE,
        
        -- Ortak streak bilgileri
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        last_both_completed_at TIMESTAMP,
        
        -- Status
        status VARCHAR(20) DEFAULT 'active', -- active, ended
        ended_by UUID REFERENCES users(id),
        ended_at TIMESTAMP,
        
        -- Timestamps
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        -- Her iki ritüel çifti unique olmalı
        UNIQUE(ritual_id_1, ritual_id_2)
      );
    `);
    console.log('✅ ritual_partnerships table created\n');

    // ============================================
    // 2. INVITE CODES için ayrı tablo
    // ============================================
    console.log('📨 Creating ritual_invites table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS ritual_invites (
        id SERIAL PRIMARY KEY,
        ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        invite_code VARCHAR(20) UNIQUE NOT NULL,
        is_used BOOLEAN DEFAULT FALSE,
        used_by UUID REFERENCES users(id),
        used_at TIMESTAMP,
        expires_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ ritual_invites table created\n');

    // ============================================
    // 3. PENDING REQUESTS tablosu
    // ============================================
    console.log('⏳ Creating partnership_requests table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS partnership_requests (
        id SERIAL PRIMARY KEY,
        
        -- Davet eden (ritüeli paylaşan)
        inviter_ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
        inviter_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        
        -- Davet edilen
        invitee_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        invitee_ritual_id UUID REFERENCES rituals(id) ON DELETE SET NULL, -- Davet edilenin ritüeli (opsiyonel)
        
        -- Davet kodu referansı
        invite_id INTEGER REFERENCES ritual_invites(id),
        
        -- Status
        status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, rejected
        
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        responded_at TIMESTAMP,
        
        -- Aynı kullanıcı aynı ritüele birden fazla istek gönderemesin
        UNIQUE(inviter_ritual_id, invitee_user_id)
      );
    `);
    console.log('✅ partnership_requests table created\n');

    // ============================================
    // 4. MEVCUT VERİLERİ MİGRATE ET
    // ============================================
    console.log('📦 Migrating existing partner data...');
    
    // Aktif partnerlikleri bul
    const existingPartnerships = await client.query(`
      SELECT 
        sr.ritual_id as owner_ritual_id,
        sr.owner_id,
        sr.invite_code,
        rp.user_id as partner_user_id,
        rp.current_streak,
        rp.longest_streak,
        rp.last_completed_at,
        r.name as ritual_name,
        r.reminder_time,
        r.reminder_days
      FROM ritual_partners rp
      JOIN shared_rituals sr ON rp.shared_ritual_id = sr.id
      JOIN rituals r ON sr.ritual_id = r.id
      WHERE rp.status = 'accepted'
    `);

    console.log(`  Found ${existingPartnerships.rows.length} active partnerships to migrate`);

    for (const old of existingPartnerships.rows) {
      // Partner için ritüel kopyası oluştur
      const newRitual = await client.query(`
        INSERT INTO rituals (user_id, name, reminder_time, reminder_days, is_public)
        VALUES ($1, $2, $3, $4, true)
        RETURNING id
      `, [
        old.partner_user_id,
        old.ritual_name,
        old.reminder_time,
        old.reminder_days
      ]);

      const partnerRitualId = newRitual.rows[0].id;

      // Partnership oluştur
      await client.query(`
        INSERT INTO ritual_partnerships (
          ritual_id_1, user_id_1,
          ritual_id_2, user_id_2,
          current_streak, longest_streak, last_both_completed_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      `, [
        old.owner_ritual_id, old.owner_id,
        partnerRitualId, old.partner_user_id,
        old.current_streak || 0,
        old.longest_streak || 0,
        old.last_completed_at
      ]);

      // Eski invite code'u yeni tabloya taşı
      if (old.invite_code) {
        await client.query(`
          INSERT INTO ritual_invites (ritual_id, user_id, invite_code, is_used, used_by, used_at)
          VALUES ($1, $2, $3, true, $4, NOW())
          ON CONFLICT (invite_code) DO NOTHING
        `, [old.owner_ritual_id, old.owner_id, old.invite_code, old.partner_user_id]);
      }

      console.log(`  ✓ Migrated partnership: ${old.ritual_name}`);
    }

    // ============================================
    // 5. PENDING REQUESTS'i migrate et
    // ============================================
    const pendingRequests = await client.query(`
      SELECT 
        sr.ritual_id,
        sr.owner_id,
        sr.invite_code,
        rp.user_id as requester_id
      FROM ritual_partners rp
      JOIN shared_rituals sr ON rp.shared_ritual_id = sr.id
      WHERE rp.status = 'pending'
    `);

    console.log(`  Found ${pendingRequests.rows.length} pending requests to migrate`);

    for (const req of pendingRequests.rows) {
      // Invite kaydı oluştur
      const invite = await client.query(`
        INSERT INTO ritual_invites (ritual_id, user_id, invite_code)
        VALUES ($1, $2, $3)
        ON CONFLICT (invite_code) DO UPDATE SET ritual_id = $1
        RETURNING id
      `, [req.ritual_id, req.owner_id, req.invite_code]);

      // Request kaydı oluştur
      await client.query(`
        INSERT INTO partnership_requests (inviter_ritual_id, inviter_user_id, invitee_user_id, invite_id)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (inviter_ritual_id, invitee_user_id) DO NOTHING
      `, [req.ritual_id, req.owner_id, req.requester_id, invite.rows[0].id]);
    }

    await client.query('COMMIT');

    console.log('\n✅ Migration completed successfully!');
    console.log('\nNew tables created:');
    console.log('  - ritual_partnerships (equal partner links)');
    console.log('  - ritual_invites (invite codes)');
    console.log('  - partnership_requests (pending requests)');
    console.log('\n⚠️  Old tables (shared_rituals, ritual_partners) are kept for safety.');
    console.log('    You can drop them after verifying the migration.\n');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Run if called directly
if (require.main === module) {
  migrateToEqualPartners()
    .then(() => {
      console.log('Done!');
      process.exit(0);
    })
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}

export default migrateToEqualPartners;
