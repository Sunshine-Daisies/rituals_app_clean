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
    subject: 'Confirm Your Account - Rituals App',
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; padding: 20px;">
        <h2 style="color: #6C63FF; text-align: center; margin-bottom: 24px;">Welcome to Rituals</h2>
        <p style="font-size: 16px; line-height: 1.5; color: #555; text-align: center;">There's one small step left. Please verify your email to get started.</p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="${verificationLink}" style="background-color: #6C63FF; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 16px; display: inline-block;">Verify Email</a>
        </div>
        <p style="font-size: 13px; color: #888; text-align: center; margin-top: 32px;">Or paste this link into your browser:<br><a href="${verificationLink}" style="color: #6C63FF;">${verificationLink}</a></p>
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

export const sendPasswordResetEmail = async (email: string, token: string) => {
  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  const EMAIL_FROM = process.env.EMAIL_FROM || 'onboarding@resend.dev';
  const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3000';

  if (!RESEND_API_KEY) {
    console.error('❌ RESEND_API_KEY is missing. Email not sent.');
    return;
  }

  // Link to the backend endpoint that serves the reset form
  const resetLink = `${BACKEND_URL}/api/auth/reset-password-page?token=${token}`;

  const data = JSON.stringify({
    from: `Rituals App <${EMAIL_FROM}>`,
    to: [email],
    subject: 'Reset Your Password - Rituals App',
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; padding: 20px;">
        <h2 style="color: #6C63FF; text-align: center; margin-bottom: 24px;">Reset Password</h2>
        <p style="font-size: 16px; line-height: 1.5; color: #555; text-align: center;">Forgot your password? No problem. Click the button below to reset it.</p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="${resetLink}" style="background-color: #6C63FF; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 16px; display: inline-block;">Reset Password</a>
        </div>
        <p style="font-size: 13px; color: #888; text-align: center; margin-top: 32px;">Or paste this link into your browser:<br><a href="${resetLink}" style="color: #6C63FF;">${resetLink}</a></p>
        <p style="font-size: 13px; color: #999; text-align: center;">If you didn't request this, you can safely ignore this email.</p>
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
      res.on('data', (chunk) => { responseBody += chunk; });
      res.on('end', () => {
        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
          console.log(`📧 Password reset email sent to ${email}`);
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
