import express from 'express';
import multer from 'multer';
import { speechToText } from '../services/stt';
import { parseTranscript } from '../services/gemini';
import { STTRequest, ParseRequest } from '../lib/schema';

const router = express.Router();

// Configure multer for audio uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'audio/wav' || file.mimetype === 'audio/wave') {
      cb(null, true);
    } else {
      cb(new Error('Only WAV audio files are allowed'));
    }
  }
});

/**
 * POST /voice/stt
 * Convert audio to text using Google Speech-to-Text
 */
router.post('/stt', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No audio file provided' });
    }

    const phraseHints = req.headers['x-phrase-hints'] as string;
    const hints = phraseHints ? phraseHints.split(',').map(h => h.trim()) : [];

    const sttRequest: STTRequest = {
      audio: req.file.buffer,
      phraseHints: hints
    };

    const result = await speechToText(sttRequest);
    res.json(result);

  } catch (error) {
    console.error('STT endpoint error:', error);
    res.status(500).json({ 
      error: 'Speech-to-Text failed', 
      details: error instanceof Error ? error.message : 'Unknown error' 
    });
  }
});

/**
 * POST /voice/parse
 * Parse transcript using Gemini to extract task fields
 */
router.post('/parse', async (req, res) => {
  try {
    const { transcript, children, currentDate } = req.body as ParseRequest;

    if (!transcript || !children) {
      return res.status(400).json({ error: 'Missing required fields: transcript, children' });
    }

    const parseRequest: ParseRequest = {
      transcript,
      children,
      currentDate
    };

    const result = await parseTranscript(parseRequest);
    res.json(result);

  } catch (error) {
    console.error('Parse endpoint error:', error);
    res.status(500).json({ 
      error: 'Transcript parsing failed', 
      details: error instanceof Error ? error.message : 'Unknown error' 
    });
  }
});

export default router;

