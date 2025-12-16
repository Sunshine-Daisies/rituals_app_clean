import https from 'https';

export const sendVerificationEmail = async (email: string, token: string) => {
  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  const EMAIL_FROM = process.env.EMAIL_FROM || 'onboarding@resend.dev'; // Fallback for testing
  const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3000';
  
  if (!RESEND_API_KEY) {
    console.error('❌ RESEND_API_KEY is missing. Email not sent.');
    return;
  }

  const verificationLink = `${BACKEND_URL}/api/auth/verify?token=${token}`;

  const data = JSON.stringify({
    from: `Rituals App <${EMAIL_FROM}>`,
    to: [email],
    subject: 'Hesabını Onayla - Rituals App',
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #6C63FF;">Hoşgeldin!</h1>
        <p>Hesabını onaylamak için lütfen aşağıdaki butona tıkla:</p>
        <a href="${verificationLink}" style="background-color: #6C63FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 20px 0;">Hesabı Onayla</a>
        <p style="color: #666; font-size: 14px;">veya linki tarayıcıya yapıştır: <br>${verificationLink}</p>
      </div>
    `
  });

  const options = {
    hostname: 'api.resend.com',
    path: '/emails',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data)
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseBody = '';

      res.on('data', (chunk) => {
        responseBody += chunk;
      });

      res.on('end', () => {
        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
          console.log(`📧 Resend email sent successfully to ${email}`);
          resolve(JSON.parse(responseBody));
        } else {
          console.error(`❌ Resend API Error: ${res.statusCode}`, responseBody);
          reject(new Error(`Resend API Error: ${responseBody}`));
        }
      });
    });

    req.on('error', (error) => {
      console.error('❌ Email sending failed:', error);
      reject(error);
    });

    req.write(data);
    req.end();
  });
};
