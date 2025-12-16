import * as admin from 'firebase-admin';
import * as path from 'path';

// Service account dosyasının yolu
const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

// Firebase Admin SDK'yı başlat
if (!admin.apps.length) {
  try {
    let credential;

    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      // Production: Environment variable'dan oku
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      credential = admin.credential.cert(serviceAccount);
    } else {
      // Development: Dosyadan oku
      credential = admin.credential.cert(serviceAccountPath);
    }

    admin.initializeApp({
      credential: credential,
    });
    console.log('✅ Firebase Admin SDK initialized successfully');
  } catch (error) {
    console.error('❌ Firebase Admin SDK initialization error:', error);
  }
}

export default admin;
