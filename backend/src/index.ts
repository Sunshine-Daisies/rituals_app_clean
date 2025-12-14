import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import ritualsRoutes from './routes/ritualsRoutes';
import authRoutes from './routes/authRoutes';
import ritualLogsRoutes from './routes/ritualLogsRoutes';
import llmUsageRoutes from './routes/llmUsageRoutes';
import devicesRoutes from './routes/devicesRoutes';
import gamificationRoutes from './routes/gamificationRoutes';
import sharingRoutes from './routes/sharingRoutes';
import notificationRoutes from './routes/notificationRoutes';
import partnershipRoutes from './routes/partnershipRoutes';
import testRoutes from './routes/testRoutes';
import { initializeStreakScheduler, shutdownStreakScheduler } from './services/streakScheduler';

dotenv.config();

const app = express();
const port = parseInt(process.env.PORT || '3000', 10);

app.use(cors());
app.use(express.json());

// Test endpoints (before auth middleware)
app.use('/api/test', testRoutes);

// Rotalar
app.use('/api/auth', authRoutes);
app.use('/api/rituals', ritualsRoutes);
app.use('/api/ritual-logs', ritualLogsRoutes);
app.use('/api/llm-usage', llmUsageRoutes);
app.use('/api/devices', devicesRoutes);
app.use('/api', gamificationRoutes); // Gamification routes (/api/profile, /api/friends, etc.)
app.use('/api/sharing', sharingRoutes); // Ritual sharing routes (legacy)
app.use('/api/partnerships', partnershipRoutes); // New equal partnership routes
app.use('/api/notifications', notificationRoutes); // Push notification routes

app.get('/', (req, res) => {
  res.send('Rituals API Çalışıyor v1.4 - Equal Partnerships 🤝');
});

app.listen(port, '0.0.0.0', async () => {
  console.log(`Server http://0.0.0.0:${port} adresinde çalışıyor`);
  
  // Initialize streak scheduler for automatic streak checking
  try {
    await initializeStreakScheduler();
    console.log('✅ Streak scheduler initialized successfully');
  } catch (error) {
    console.error('❌ Failed to initialize streak scheduler:', error);
  }
});

// Graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  shutdownStreakScheduler();
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  shutdownStreakScheduler();
  process.exit(0);
});
