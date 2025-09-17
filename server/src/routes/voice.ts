import express from 'express';
import multer from 'multer';
import { speechToText } from '../services/stt';
import { voiceSessionStore } from '../services/VoiceSessionStore';
import { voiceExtractor } from '../services/VoiceExtractor';
import { voiceMergeLogic } from '../services/VoiceMergeLogic';
import { dateNormalizer } from '../services/DateNormalizer';
import { STTRequest, ParseRequest } from '../lib/schema';
import { v4 as uuidv4 } from 'uuid';

const router = express.Router();

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    activeSessions: voiceSessionStore.getSessionCount()
  });
});

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
 * Parse transcript using session-based slot filling
 */
router.post('/parse', async (req, res) => {
  try {
    const { transcript, children, currentDate, sessionId } = req.body;

    if (!transcript || !children) {
      return res.status(400).json({ error: 'Missing required fields: transcript, children' });
    }

    // Get or create session
    let session = sessionId ? voiceSessionStore.getSession(sessionId) : null;
    
    if (!session) {
      // Create new session
      const newSessionId = uuidv4();
      session = voiceSessionStore.createSession(newSessionId, children);
    }

    // Extract slot delta from utterance
    const delta = await voiceExtractor.extractSlotDelta(
      transcript,
      session.slots,
      session.expectedSlot,
      session.childrenRoster
    );

    // Handle cancellation
    if (delta.intent === 'cancel') {
      session = voiceSessionStore.updateSession(session.sessionId, { status: 'cancelled' });
      const response = {
        needsFollowup: false,
        missing: [],
        question: '',
        result: null,
        speak: 'Task creation cancelled.',
        sessionId: session.sessionId
      };
      return res.json(response);
    }

    // Handle new task
    if (delta.intent === 'new_task') {
      session = voiceSessionStore.createSession(uuidv4(), children);
    }

    // Normalize due date if provided
    if (delta.slot_updates.dueText) {
      delta.slot_updates.dueIso = dateNormalizer.normalizeDueText(delta.slot_updates.dueText);
    }

    // Merge slot updates
    session = voiceMergeLogic.mergeSlotUpdates(session, delta);
    session = voiceSessionStore.updateSession(session.sessionId, session);

    // Generate response
    const response = voiceMergeLogic.generateResponse(session, delta);

    // Convert to legacy format for iOS compatibility
    const legacyResponse = {
      needsFollowup: response.type === 'followup',
      missing: session.missing,
      question: response.speak,
      result: response.parsed || null,
      speak: response.speak,
      sessionId: response.sessionId
    };

    res.json(legacyResponse);

  } catch (error) {
    console.error('Parse endpoint error:', error);
    res.status(500).json({ 
      error: 'Transcript parsing failed', 
      details: error instanceof Error ? error.message : 'Unknown error' 
    });
  }
});

export default router;

