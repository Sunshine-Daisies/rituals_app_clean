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
import swaggerUi from 'swagger-ui-express';
import swaggerSpec from './config/swagger';

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

// Root endpoint
app.get('/', (req, res) => {
  res.send('Rituals API is running. Go to /docs for documentation.');
});

// DB Setup Endpoint (Temporary)
import pool from './config/db';
app.get('/setup-db', async (req, res) => {
  try {
    const createTablesQuery = `
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

      CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS rituals (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID REFERENCES users(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          reminder_time TEXT,
          reminder_days TEXT[],
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS ritual_steps (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          is_completed BOOLEAN DEFAULT FALSE,
          order_index INTEGER DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS ritual_logs (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE,
          step_index INTEGER,
          source TEXT,
          completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS llm_usage (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID REFERENCES users(id) ON DELETE CASCADE,
          model TEXT,
          tokens_in INTEGER,
          tokens_out INTEGER,
          session_id TEXT,
          intent TEXT,
          prompt_type TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS devices (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          profile_id UUID REFERENCES users(id) ON DELETE CASCADE,
          device_token TEXT NOT NULL,
          platform TEXT,
          app_version TEXT,
          locale TEXT,
          last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `;
    await pool.query(createTablesQuery);
    res.send('Database tables created successfully!');
  } catch (error) {
    console.error(error);
    res.status(500).send('Error creating tables: ' + error);
  }
});

// =================================================================
// API DOCUMENTATION (Swagger)
// =================================================================
const swaggerOptions = {
  customSiteTitle: "Rituals API Docs",
  customCss: `
    .swagger-ui .topbar { display: none; }
    .swagger-ui .info { margin: 20px 0; }
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
