import nodemailer from 'nodemailer';

// Gmail ayarları
// process.env.EMAIL_USER ve process.env.EMAIL_PASS, docker-compose.yml veya .env dosyasından gelir.
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER || 'ritualsapp01@gmail.com', 
    pass: process.env.EMAIL_PASS || 'xyle cmgd mnnr pxrf'
  }
});

export const sendVerificationEmail = async (email: string, token: string) => {
  // Link, kullanıcının mailine gidecek.
  // Bilgisayardan tıklayacaksan 'localhost' kullanmalısın.
  // Emülatör içinden tıklayacaksan '10.0.2.2' olabilir ama genelde maili bilgisayarda açarsın.
  const verificationLink = `http://localhost:3000/api/auth/verify?token=${token}`;

  const mailOptions = {
    from: '"Rituals App" <no-reply@rituals.com>',
    to: email,
    subject: 'Hesabını Onayla - Rituals App',
    html: `
      <h1>Hoşgeldin!</h1>
      <p>Hesabını onaylamak için lütfen aşağıdaki linke tıkla:</p>
      <a href="${verificationLink}" style="background-color: #6C63FF; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Hesabı Onayla</a>
      <p>veya linki tarayıcıya yapıştır: ${verificationLink}</p>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`📧 Onay maili gönderildi: ${email}`);
  } catch (error) {
    console.error('Mail gönderme hatası:', error);
    // Geliştirme aşamasında hata fırlatmayalım ki akış bozulmasın, sadece loglayalım
    // throw new Error('Mail gönderilemedi'); 
  }
};
