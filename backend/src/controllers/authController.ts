import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import pool from '../config/db';
import { sendVerificationEmail, sendPasswordResetEmail } from '../services/emailService';
import xpService from '../services/xpService';

// Username oluştur (email'den)
function generateUsername(email: string): string {
  const base = email.split('@')[0].toLowerCase().replace(/[^a-z0-9]/g, '_');
  const random = Math.floor(Math.random() * 1000);
  return `${base}_${random}`;
}

// Kayıt Ol
export const register = async (req: Request, res: Response) => {
  const { email, password, name } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email ve şifre zorunludur' });
  }

  try {
    // 1. Email kullanımda mı kontrol et
    const userCheck = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Bu email zaten kayıtlı' });
    }

    // 2. Şifreyi hashle
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 3. Rastgele onay kodu oluştur
    const verificationToken = crypto.randomBytes(32).toString('hex');

    // 4. Kullanıcıyı kaydet (is_verified varsayılan FALSE)
    const userResult = await pool.query(
      'INSERT INTO users (email, password_hash, verification_token) VALUES ($1, $2, $3) RETURNING id',
      [email, passwordHash, verificationToken]
    );

    // 5. Gamification profili oluştur
    const userId = userResult.rows[0].id;
    // Kullanıcı adı varsa onu kullan, yoksa email'den üret
    const username = name
      ? name.toLowerCase().replace(/[^a-z0-9_]/g, '_') + '_' + Math.floor(Math.random() * 100)
      : generateUsername(email);

    await xpService.createUserProfile(userId, username);

    // 6. Mail gönder (arka planda — istemci cevabını engellemesin)
    // Not: SMTP / nodemailer bazen ağa/kimlik doğrulamaya bağlı olarak yavaşlayabilir.
    // Burada e-postayı arka planda gönderiyoruz, böylece istemci zaman aşımına uğramaz.
    sendVerificationEmail(email, verificationToken).catch(err => console.error('sendVerificationEmail error:', err));

    // Token DÖNMÜYORUZ. Sadece mesaj.
    res.status(201).json({
      message: 'Registration successful! Please check your email to verify your account.',
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
};

// Mail Onaylama Endpoint'i
export const verifyEmail = async (req: Request, res: Response) => {
  const { token } = req.query;

  if (!token) {
    return res.status(400).send('Invalid request');
  }

  const logoUrl = `${process.env.BACKEND_URL}/public/logo.png`;

  try {
    const result = await pool.query(
      'UPDATE users SET is_verified = TRUE, verification_token = NULL WHERE verification_token = $1 RETURNING email',
      [token]
    );

    if (result.rows.length === 0) {
      return res.send(`
        <html>
          <head>
            <title>Invalid Link</title>
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f8f9fa; margin: 0; }
              .card { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); text-align: center; max-width: 400px; width: 90%; }
              h1 { color: #333; font-size: 24px; margin-bottom: 12px; }
              p { color: #666; font-size: 16px; line-height: 1.5; }
              .icon { color: #ff3b30; font-size: 48px; margin-bottom: 20px; }
              .logo { width: 60px; height: 60px; margin-bottom: 24px; }
            </style>
          </head>
          <body>
            <div class="card">
              <img src="${logoUrl}" alt="Rituals Logo" class="logo">
              <div class="icon">⚠️</div>
              <h1>Invalid or Expired Link</h1>
              <p>This verification link is invalid or has already been used.</p>
            </div>
          </body>
        </html>
      `);
    }

    res.send(`
      <html>
        <head>
          <title>Email Verified</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f8f9fa; margin: 0; }
            .card { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); text-align: center; max-width: 400px; width: 90%; }
            h1 { color: #333; font-size: 24px; margin-bottom: 12px; }
            p { color: #666; font-size: 16px; line-height: 1.5; }
            .success-icon { color: #34c759; font-size: 48px; margin-bottom: 20px; }
            .logo { width: 60px; height: 60px; margin-bottom: 24px; }
          </style>
        </head>
        <body>
          <div class="card">
            <img src="${logoUrl}" alt="Rituals Logo" class="logo">
            <div class="success-icon">✅</div>
            <h1>Email Verified</h1>
            <p>Your account has been successfully verified. You can now return to the app and sign in.</p>
          </div>
        </body>
      </html>
    `);

  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
};

// Giriş Yap
export const login = async (req: Request, res: Response) => {
  const { email, password } = req.body;

  try {
    // 1. Kullanıcıyı bul
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (userResult.rows.length === 0) {
      return res.status(400).json({ error: 'Kullanıcı bulunamadı' });
    }

    const user = userResult.rows[0];

    // 2. Şifreyi kontrol et
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(400).json({ error: 'Hatalı şifre' });
    }

    // 3. Onay kontrolü
    if (!user.is_verified) {
      return res.status(403).json({ error: 'Lütfen önce e-posta adresini onayla.' });
    }

    // 4. Token oluştur
    const token = jwt.sign(
      { id: user.id, email: user.email, isPrem: user.is_premium },
      process.env.JWT_SECRET as string,
      { expiresIn: '30d' }
    );

    res.json({
      message: 'Giriş başarılı',
      user: { id: user.id, email: user.email, isPremium: user.is_premium },
      token
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
};

// Şifremi Unuttum
export const forgotPassword = async (req: Request, res: Response) => {
  const { email } = req.body;

  try {
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userResult.rows.length === 0) {
      // Security: return success even if user not found
      return res.json({ message: 'If this email is registered, a password reset link has been sent.' });
    }

    const token = crypto.randomBytes(32).toString('hex');
    const expires = Date.now() + 3600000; // 1 saat

    await pool.query(
      'UPDATE users SET reset_password_token = $1, reset_password_expires = $2 WHERE email = $3',
      [token, expires, email]
    );

    sendPasswordResetEmail(email, token).catch(console.error);

    res.json({ message: 'If this email is registered, a password reset link has been sent.' });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
};

// Şifre Sıfırlama Sayfası (HTML Form)
export const resetPasswordPage = async (req: Request, res: Response) => {
  const { token } = req.query;

  const logoUrl = `${process.env.BACKEND_URL}/public/logo.png`;

  res.send(`
    <html>
      <head>
        <title>Reset Password</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f8f9fa; margin: 0; }
          .card { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); width: 100%; max-width: 380px; text-align: center; }
          input { width: 100%; padding: 14px; margin: 10px 0; border: 1px solid #e1e4e8; border-radius: 8px; box-sizing: border-box; font-size: 16px; transition: border 0.2s; }
          input:focus { border-color: #6C63FF; outline: none; }
          button { width: 100%; padding: 14px; background-color: #6C63FF; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; font-weight: 600; margin-top: 10px; transition: background 0.2s; }
          button:hover { background-color: #5850d0; }
          .error { color: #ff3b30; font-size: 14px; margin-bottom: 16px; padding: 10px; background: #fff0f0; border-radius: 8px; display: none; }
          h2 { margin-top: 0; color: #333; }
          .logo { width: 50px; height: 50px; margin-bottom: 20px; }
        </style>
      </head>
      <body>
        <div class="card">
          <img src="${logoUrl}" alt="app logo" class="logo">
          <h2>Reset Password</h2>
          <div id="error-msg" class="error"></div>
          <form id="reset-form">
            <input type="hidden" id="token" value="${token}">
            <input type="password" id="password" placeholder="New Password" required minlength="6">
            <input type="password" id="confirmParams" placeholder="Confirm Password" required minlength="6">
            <button type="submit">Set New Password</button>
          </form>
        </div>

        <script>
          document.getElementById('reset-form').onsubmit = async (e) => {
            e.preventDefault();
            const password = document.getElementById('password').value;
            const confirm = document.getElementById('confirmParams').value;
            const token = document.getElementById('token').value;
            const errorDiv = document.getElementById('error-msg');
            const submitBtn = e.target.querySelector('button');

            if (password !== confirm) {
              errorDiv.innerText = 'Passwords do not match';
              errorDiv.style.display = 'block';
              return;
            }

            submitBtn.disabled = true;
            submitBtn.innerText = 'Updating...';

            try {
              const res = await fetch('/api/auth/reset-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ token, password })
              });
              
              const data = await res.json();
              
              if (res.ok) {
                document.body.innerHTML = \`
                  <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f8f9fa;">
                    <div style="background: white; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); text-align: center; max-width: 380px;">
                      <div style="font-size: 48px; margin-bottom: 16px;">✅</div>
                      <h2 style="color: #333; margin-bottom: 8px;">Password Updated!</h2>
                      <p style="color: #666; line-height: 1.5;">Your password has been reset successfully. You can now return to the app and sign in.</p>
                    </div>
                  </div>
                \`;
              } else {
                errorDiv.innerText = data.error || 'An error occurred';
                errorDiv.style.display = 'block';
                submitBtn.disabled = false;
                submitBtn.innerText = 'Set New Password';
              }
            } catch (err) {
              errorDiv.innerText = 'Connection error';
              errorDiv.style.display = 'block';
              submitBtn.disabled = false;
              submitBtn.innerText = 'Set New Password';
            }
          };
        </script>
      </body>
    </html>
  `);
};

// Şifre Sıfırlama İşlemi
export const resetPassword = async (req: Request, res: Response) => {
  const { token, password } = req.body;

  try {
    const userResult = await pool.query(
      'SELECT * FROM users WHERE reset_password_token = $1 AND reset_password_expires > $2',
      [token, Date.now()]
    );

    if (userResult.rows.length === 0) {
      return res.status(400).json({ error: 'Geçersiz veya süresi dolmuş link.' });
    }

    const user = userResult.rows[0];
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    await pool.query(
      'UPDATE users SET password_hash = $1, reset_password_token = NULL, reset_password_expires = NULL WHERE id = $2',
      [passwordHash, user.id]
    );

    res.json({ message: 'Password updated successfully' });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
};

// Mock Premium Toggle (For Demo)
export const togglePremium = async (req: any, res: Response) => {
  const userId = req.user?.id; // Authed user ID from middleware

  if (!userId) {
    return res.status(401).json({ error: 'Yetkisiz erişim' });
  }

  try {
    const result = await pool.query(
      'UPDATE users SET is_premium = NOT is_premium WHERE id = $1 RETURNING is_premium',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }

    const isPremium = result.rows[0].is_premium;
    res.json({
      message: isPremium ? 'Premium mod aktif!' : 'Premium mod pasif.',
      isPremium
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
};
