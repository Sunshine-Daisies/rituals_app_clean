import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import ritualsRoutes from './routes/ritualsRoutes';
import authRoutes from './routes/authRoutes';
import ritualLogsRoutes from './routes/ritualLogsRoutes';
import llmUsageRoutes from './routes/llmUsageRoutes';
import devicesRoutes from './routes/devicesRoutes';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Rotalar
app.use('/api/auth', authRoutes);
app.use('/api/rituals', ritualsRoutes);
app.use('/api/ritual-logs', ritualLogsRoutes);
app.use('/api/llm-usage', llmUsageRoutes);
app.use('/api/devices', devicesRoutes);

app.get('/', (req, res) => {
  res.send('Rituals API Çalışıyor v1.0');
});

app.listen(port, () => {
  console.log(`Server http://localhost:${port} adresinde çalışıyor`);
});
