import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import ritualsRoutes from './routes/ritualsRoutes';
import authRoutes from './routes/authRoutes';
import ritualLogsRoutes from './routes/ritualLogsRoutes';
import llmUsageRoutes from './routes/llmUsageRoutes';
import llmRoutes from './routes/llmRoutes'; // New LLM Service Routes
import devicesRoutes from './routes/devicesRoutes';
import gamificationRoutes from './routes/gamificationRoutes';
import sharingRoutes from './routes/sharingRoutes';
import notificationRoutes from './routes/notificationRoutes';
import partnershipRoutes from './routes/partnershipRoutes';
import testRoutes from './routes/testRoutes';
import { initializeStreakScheduler, shutdownStreakScheduler } from './services/streakScheduler';
import swaggerUi from 'swagger-ui-express';
import swaggerSpec from './config/swagger';
import { connectRedis } from './services/cacheService';

dotenv.config();

const app = express();
const port = parseInt(process.env.PORT || '3000', 10);

// Railway gibi proxy arkasında çalışırken gerekli
app.enable('trust proxy');

// CORS ayarları
app.use(cors({
  origin: '*', // Tüm originlere izin ver (Production'da daha spesifik olabilir)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

app.use(express.json());
app.use('/public', express.static('public'));

app.use(express.static('public'));

// Root endpoint - Serve React App
app.get('/', (req, res) => {
  res.sendFile('index.html', { root: 'public' });
});

// DB Setup Endpoint (Temporary)
import pool from './config/db';
import { setupFullDatabase, runMigrations, seedZenBadges } from './controllers/setupController';

app.get('/setup-db', async (req, res) => {
  // ... existing simple setup ...
  try {
    const createTablesQuery = `
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      
      -- (Existing tables)
      CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      -- ... (rest of the simple setup)
    `;
    // We keep the old one for basic tables, but let's redirect to the full setup or just add a new endpoint
    // Actually, let's just replace the old setup-db logic with the new one or add a new endpoint.
    // The user is used to /setup-db. Let's make /setup-db do the basic stuff (which is already done) AND the new stuff.
    // But to be safe, let's add /setup-full and tell the user to go there.

    // For now, let's just add the new endpoint.
    res.send('Please use /setup-full for complete installation.');
  } catch (error) {
    res.status(500).send('Error: ' + error);
  }
});

app.get('/setup-full', setupFullDatabase);
app.get('/setup/zen-badges', seedZenBadges);

// =================================================================
// API DOCUMENTATION (Swagger)
// =================================================================
const swaggerOptions = {
  customSiteTitle: "Rituals API Docs",
  customCss: `
    .swagger-ui .topbar { display: none; }
    .swagger-ui .info { margin: 20px 0; }
    .swagger-ui .servers-title { display: none; }
    .swagger-ui .servers { display: none; }
  `,
  swaggerOptions: {
    persistAuthorization: true,
    docExpansion: 'none',
    filter: true,
  },
};

app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, swaggerOptions));

// Test endpoints (before auth middleware)
app.use('/api/test', testRoutes);

// Rotalar
app.use('/api/auth', authRoutes);
app.use('/api/rituals', ritualsRoutes);
app.use('/api/ritual-logs', ritualLogsRoutes);
app.use('/api/llm-usage', llmUsageRoutes); // Telemetry only
app.use('/api/llm', llmRoutes); // Actual LLM Logic (Chat/Intent)
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
    await runMigrations();
    console.log('✅ Database migrations applied successfully');

    await initializeStreakScheduler();
    console.log('✅ Streak scheduler initialized successfully');
    await connectRedis();
    console.log('✅ Redis connection initialized');
  } catch (error) {
    console.error('❌ Startup error:', error);
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
