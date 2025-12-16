import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import pool from '../config/db';
import { sendVerificationEmail } from '../services/emailService';
import xpService from '../services/xpService';

// Username oluştur (email'den)
function generateUsername(email: string): string {
  const base = email.split('@')[0].toLowerCase().replace(/[^a-z0-9]/g, '_');
  const random = Math.floor(Math.random() * 1000);
  return `${base}_${random}`;
}

// Kayıt Ol
export const register = async (req: Request, res: Response) => {
  const { email, password } = req.body;

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

    // 4. Kullanıcıyı kaydet (is_verified varsayılan TRUE yapıyoruz çünkü SMTP çalışmıyor)
    const userResult = await pool.query(
      'INSERT INTO users (email, password_hash, verification_token, is_verified) VALUES ($1, $2, $3, TRUE) RETURNING id',
      [email, passwordHash, verificationToken]
    );

    // 5. Gamification profili oluştur
    const userId = userResult.rows[0].id;
    const username = generateUsername(email);
    await xpService.createUserProfile(userId, username);

    // 6. Mail gönderimi devre dışı (Railway SMTP engeli nedeniyle)
    // sendVerificationEmail(email, verificationToken).catch(err => {
    //   console.error('Arka planda mail gönderme hatası:', err);
    // });

    // Token DÖNMÜYORUZ. Sadece mesaj.
    res.status(201).json({
      message: 'Kayıt başarılı! Giriş yapabilirsiniz.',
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
    return res.status(400).send('Geçersiz istek');
  }

  try {
    const result = await pool.query(
      'UPDATE users SET is_verified = TRUE, verification_token = NULL WHERE verification_token = $1 RETURNING email',
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).send('<h1>Geçersiz veya süresi dolmuş onay linki.</h1>');
    }

    res.send('<h1>✅ Hesabın başarıyla onaylandı! Uygulamaya dönüp giriş yapabilirsin.</h1>');

  } catch (err) {
    console.error(err);
    res.status(500).send('Sunucu hatası');
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
      { id: user.id, email: user.email },
      process.env.JWT_SECRET as string,
      { expiresIn: '30d' }
    );

    res.json({
      message: 'Giriş başarılı',
      user: { id: user.id, email: user.email },
      token
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
};
