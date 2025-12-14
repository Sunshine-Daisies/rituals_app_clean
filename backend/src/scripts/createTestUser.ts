import { Pool } from 'pg';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import path from 'path';

// Load env vars from backend root
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'rituals_db',
  password: process.env.DB_PASSWORD || '123456',
  port: parseInt(process.env.DB_PORT || '5432'),
});

const createTestUser = async () => {
  const email = 'test@example.com';
  const password = 'password123';
  const username = 'test_user';

  try {
    console.log('🚀 Creating test user...');

    // 1. Check if user exists
    const userCheck = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length > 0) {
      console.log('⚠️ User already exists with email:', email);
      console.log('Credentials:');
      console.log('Email:', email);
      console.log('Password:', password);
      process.exit(0);
    }

    // 2. Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 3. Generate verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');

    // 4. Insert user
    // Note: We set is_verified to TRUE directly for the test user
    const userResult = await pool.query(
      'INSERT INTO users (email, password_hash, verification_token, is_verified) VALUES ($1, $2, $3, $4) RETURNING id',
      [email, passwordHash, verificationToken, true]
    );

    const userId = userResult.rows[0].id;
    console.log(`✅ User created with ID: ${userId}`);

    // 5. Create Gamification Profile
    // We replicate xpService.createUserProfile logic here to avoid importing the service which might have other dependencies
    await pool.query(
      `INSERT INTO user_profiles (user_id, username) 
       VALUES ($1, $2) 
       ON CONFLICT (user_id) DO NOTHING`,
      [userId, username]
    );
    console.log(`✅ User profile created with username: ${username}`);

    console.log('\n🎉 Test User Created Successfully!');
    console.log('-----------------------------------');
    console.log('Email:    ', email);
    console.log('Password: ', password);
    console.log('Username: ', username);
    console.log('-----------------------------------');

  } catch (error) {
    console.error('❌ Error creating test user:', error);
  } finally {
    await pool.end();
  }
};

createTestUser();
