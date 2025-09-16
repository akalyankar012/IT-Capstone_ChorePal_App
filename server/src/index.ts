import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import voiceRoutes from './routes/voice';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.raw({ type: 'audio/wav', limit: '10mb' }));

// Routes
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    project: process.env.GCP_PROJECT_ID,
    region: process.env.GCP_REGION
  });
});

app.use('/voice', voiceRoutes);

// Error handling
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`🚀 Voice server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🎤 STT endpoint: http://localhost:${PORT}/voice/stt`);
  console.log(`🤖 Parse endpoint: http://localhost:${PORT}/voice/parse`);
});

export default app;
