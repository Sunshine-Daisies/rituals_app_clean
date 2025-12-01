import * as admin from 'firebase-admin';
import * as path from 'path';

// Service account dosyasının yolu
const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

// Firebase Admin SDK'yı başlat
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccountPath),
    });
    console.log('✅ Firebase Admin SDK initialized successfully');
  } catch (error) {
    console.error('❌ Firebase Admin SDK initialization error:', error);
  }
}

export default admin;
