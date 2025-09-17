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
    region: process.env.VERTEX_LOCATION,
    model: process.env.GEMINI_MODEL,
    credentials: process.env.GOOGLE_APPLICATION_CREDENTIALS ? 'Set' : 'Not set'
  });
});

app.use('/voice', voiceRoutes);

// Test endpoint for direct Gemini testing
app.post('/test/gemini', async (req, res) => {
  try {
    const { parseTranscript } = await import('./services/gemini');
    const result = await parseTranscript({
      transcript: req.body.transcript || 'Make dishes for Emma tomorrow worth 20 points',
      children: req.body.children || [
        { id: '1', name: 'Emma' },
        { id: '2', name: 'Zayn' }
      ]
    });
    res.json(result);
  } catch (error) {
    console.error('Test Gemini error:', error);
    res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
  }
});

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
