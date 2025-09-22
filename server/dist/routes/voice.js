"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const multer_1 = __importDefault(require("multer"));
const whisperSTT_1 = require("../services/whisperSTT");
const VoiceSessionStore_1 = require("../services/VoiceSessionStore");
const VoiceExtractor_1 = require("../services/VoiceExtractor");
const VoiceMergeLogic_1 = require("../services/VoiceMergeLogic");
const DateNormalizer_1 = require("../services/DateNormalizer");
const uuid_1 = require("uuid");
const router = express_1.default.Router();
// Health check endpoint
router.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        activeSessions: VoiceSessionStore_1.voiceSessionStore.getSessionCount()
    });
});
/**
 * POST /voice/session/start
 * Start a new voice session, invalidating any existing session for the user
 */
router.post('/session/start', async (req, res) => {
    try {
        const { userId } = req.body;
        if (!userId) {
            return res.status(400).json({ error: 'Missing required field: userId' });
        }
        // Close any existing active session for this user
        const existingSessions = VoiceSessionStore_1.voiceSessionStore.getSessionsByUser(userId);
        for (const session of existingSessions) {
            if (session.status === 'in_progress') {
                VoiceSessionStore_1.voiceSessionStore.updateSession(session.sessionId, { status: 'cancelled' });
                console.log(`🔄 Closed existing session ${session.sessionId} for user ${userId}`);
            }
        }
        // Create new session
        const sessionId = (0, uuid_1.v4)();
        const children = req.body.children || [];
        const session = VoiceSessionStore_1.voiceSessionStore.createSession(sessionId, children);
        console.log(`🆕 Started new session ${sessionId} for user ${userId}`);
        res.json({
            sessionId: sessionId,
            status: 'active',
            message: 'New voice session started'
        });
    }
    catch (error) {
        console.error('Session start error:', error);
        res.status(500).json({
            error: 'Failed to start session',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Configure multer for audio uploads
const upload = (0, multer_1.default)({
    storage: multer_1.default.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
    },
    fileFilter: (req, file, cb) => {
        if (file.mimetype === 'audio/wav' || file.mimetype === 'audio/wave') {
            cb(null, true);
        }
        else {
            cb(new Error('Only WAV audio files are allowed'));
        }
    }
});
/**
 * POST /voice/stt
 * Convert audio to text using OpenAI Whisper API
 */
router.post('/stt', upload.single('audio'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No audio file provided' });
        }
        const sttRequest = {
            audio: req.file.buffer,
            phraseHints: [] // Whisper handles context internally
        };
        const result = await (0, whisperSTT_1.speechToText)(sttRequest);
        res.json(result);
    }
    catch (error) {
        console.error('STT endpoint error:', error);
        res.status(500).json({
            error: 'Speech-to-Text failed',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
/**
 * POST /voice/turn
 * Process a turn in an active voice session
 */
router.post('/turn', async (req, res) => {
    try {
        // Extract headers
        const userId = req.headers['x-user-id'];
        const sessionId = req.headers['x-session-id'];
        const turnId = req.headers['x-turn-id'];
        const turnIndex = parseInt(req.headers['x-turn-index']);
        const { transcript, children, currentDate } = req.body;
        // Validate required headers
        if (!userId || !sessionId || !turnId || isNaN(turnIndex)) {
            return res.status(400).json({
                error: 'Missing required headers: x-user-id, x-session-id, x-turn-id, x-turn-index'
            });
        }
        if (!transcript || !children) {
            return res.status(400).json({ error: 'Missing required fields: transcript, children' });
        }
        // Get session and validate it's active
        const session = VoiceSessionStore_1.voiceSessionStore.getSession(sessionId);
        if (!session) {
            return res.status(409).json({
                error: 'Session not found. Please start a new session first.',
                code: 'SESSION_NOT_FOUND'
            });
        }
        if (session.status !== 'in_progress') {
            return res.status(409).json({
                error: 'Session is not active. Please start a new session first.',
                code: 'SESSION_INACTIVE'
            });
        }
        // Check turn ordering
        if (turnIndex <= session.lastTurnIndex) {
            console.log(`⚠️ Ignoring out-of-order turn ${turnIndex} (last: ${session.lastTurnIndex}) for session ${sessionId}`);
            return res.status(200).json({
                needsFollowup: false,
                missing: [],
                question: '',
                result: null,
                speak: 'Turn ignored (out of order)',
                sessionId: sessionId,
                turnId: turnId,
                turnIndex: turnIndex
            });
        }
        // Update session with turn info
        session.lastTurnIndex = turnIndex;
        session.lastTurnId = turnId;
        VoiceSessionStore_1.voiceSessionStore.updateSession(sessionId, session);
        console.log(`🔄 Processing turn ${turnIndex} (${turnId}) for session ${sessionId}`);
        // Extract slot delta from utterance
        const delta = await VoiceExtractor_1.voiceExtractor.extractSlotDelta(transcript, session.slots, session.expectedSlot, session.childrenRoster);
        // Handle cancellation
        if (delta.intent === 'cancel') {
            session.status = 'cancelled';
            VoiceSessionStore_1.voiceSessionStore.updateSession(sessionId, session);
            const response = {
                needsFollowup: false,
                missing: [],
                question: '',
                result: null,
                speak: 'Task creation cancelled.',
                sessionId: sessionId,
                turnId: turnId,
                turnIndex: turnIndex
            };
            return res.json(response);
        }
        // Normalize due date if provided
        if (delta.slot_updates.dueText) {
            delta.slot_updates.dueIso = DateNormalizer_1.dateNormalizer.normalizeDueText(delta.slot_updates.dueText);
        }
        // Merge slot updates
        try {
            session.slots = { ...session.slots, ...delta.slot_updates };
            // Compute missing slots manually
            const missing = [];
            if (!session.slots.assignedChildId)
                missing.push('assignedChild');
            if (!session.slots.title)
                missing.push('title');
            if (!session.slots.dueIso)
                missing.push('due');
            if (!session.slots.points)
                missing.push('points');
            session.missing = missing;
            session.expectedSlot = session.missing.length > 0 ? session.missing[0] : undefined;
            if (session.missing.length === 0) {
                session.status = 'ready_to_create';
            }
            VoiceSessionStore_1.voiceSessionStore.updateSession(sessionId, session);
            console.log(`📊 Updated session slots:`, session.slots);
            console.log(`📊 Session missing fields:`, session.missing);
        }
        catch (error) {
            console.error('Error merging slot updates:', error);
            return res.status(500).json({
                error: 'Failed to process voice command',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
        // Generate response
        const response = VoiceMergeLogic_1.voiceMergeLogic.generateResponse(session, delta);
        console.log(`📤 Generated response:`, {
            type: response.type,
            speak: response.speak,
            sessionId: sessionId,
            turnId: turnId,
            turnIndex: turnIndex
        });
        // Convert to legacy format for iOS compatibility
        const legacyResponse = {
            needsFollowup: response.type === 'followup',
            missing: session.missing,
            question: response.speak,
            result: response.result || response.parsed || null,
            speak: response.speak,
            sessionId: sessionId,
            turnId: turnId,
            turnIndex: turnIndex
        };
        console.log(`📤 Sending legacy response:`, legacyResponse);
        res.json(legacyResponse);
    }
    catch (error) {
        console.error('Turn endpoint error:', error);
        res.status(500).json({
            error: 'Turn processing failed',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
/**
 * POST /voice/parse
 * Parse transcript using session-based slot filling (DEPRECATED - use /voice/turn)
 */
router.post('/parse', async (req, res) => {
    try {
        const { transcript, children, currentDate, sessionId } = req.body;
        if (!transcript || !children) {
            return res.status(400).json({ error: 'Missing required fields: transcript, children' });
        }
        // Get or create session
        let session = sessionId ? VoiceSessionStore_1.voiceSessionStore.getSession(sessionId) : null;
        if (!session) {
            // Create new session
            const newSessionId = (0, uuid_1.v4)();
            session = VoiceSessionStore_1.voiceSessionStore.createSession(newSessionId, children);
            console.log(`🆕 Created new session: ${newSessionId} (requested: ${sessionId || 'none'})`);
        }
        else {
            console.log(`🔄 Using existing session: ${sessionId}`);
            console.log(`📊 Current session slots:`, session.slots);
        }
        // Extract slot delta from utterance
        const delta = await VoiceExtractor_1.voiceExtractor.extractSlotDelta(transcript, session.slots, session.expectedSlot, session.childrenRoster);
        // Handle cancellation
        if (delta.intent === 'cancel') {
            if (!session) {
                return res.status(400).json({ error: 'No active session to cancel' });
            }
            session = VoiceSessionStore_1.voiceSessionStore.updateSession(session.sessionId, { status: 'cancelled' });
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
        // Handle new task - only create fresh session if previous task was completed
        if (transcript.toLowerCase().includes('create task') || delta.intent === 'new_task') {
            // Only start fresh session if previous task was completed or if no active session
            if (session && session.status === 'ready_to_create') {
                console.log(`🔄 Previous task completed, starting fresh session`);
                const newSessionId = (0, uuid_1.v4)();
                session = VoiceSessionStore_1.voiceSessionStore.createSession(newSessionId, children);
                console.log(`🆕 Created fresh session: ${newSessionId} (old: ${sessionId})`);
            }
            else if (!session) {
                console.log(`🆕 No active session, creating new one`);
                const newSessionId = (0, uuid_1.v4)();
                session = VoiceSessionStore_1.voiceSessionStore.createSession(newSessionId, children);
                console.log(`🆕 Created new session: ${newSessionId}`);
            }
            else {
                console.log(`🔄 Continuing current session for new task`);
            }
        }
        // Handle child switching - clear current task but keep session
        if (delta.slot_updates.assignedChildName && session && session.slots.assignedChildName) {
            const currentChild = session.slots.assignedChildName;
            const newChild = delta.slot_updates.assignedChildName;
            if (currentChild.toLowerCase() !== newChild.toLowerCase()) {
                console.log(`🔄 Different child mentioned: ${currentChild} -> ${newChild}, clearing current task`);
                // Clear current task slots but keep session
                session.slots = {};
                session.missing = ['assignedChild', 'title', 'due', 'points'];
                session.expectedSlot = 'assignedChild';
                session.status = 'in_progress';
                VoiceSessionStore_1.voiceSessionStore.updateSession(session.sessionId, session);
            }
        }
        // Normalize due date if provided
        if (delta.slot_updates.dueText) {
            delta.slot_updates.dueIso = DateNormalizer_1.dateNormalizer.normalizeDueText(delta.slot_updates.dueText);
        }
        // Merge slot updates with comprehensive error handling
        try {
            if (!session) {
                console.error('❌ No active session found');
                return res.status(400).json({
                    error: 'No active session found',
                    code: 'NO_SESSION'
                });
            }
            // Validate delta before merging
            if (!delta || typeof delta !== 'object') {
                console.error('❌ Invalid delta received:', delta);
                return res.status(400).json({
                    error: 'Invalid voice data received',
                    code: 'INVALID_DELTA'
                });
            }
            session = VoiceMergeLogic_1.voiceMergeLogic.mergeSlotUpdates(session, delta);
            session = VoiceSessionStore_1.voiceSessionStore.updateSession(session.sessionId, session);
            console.log(`📊 Updated session slots:`, session.slots);
            console.log(`📊 Session missing fields:`, session.missing);
        }
        catch (error) {
            console.error('❌ Error merging slot updates:', error);
            return res.status(500).json({
                error: 'Failed to process voice command',
                details: error instanceof Error ? error.message : 'Unknown error',
                code: 'MERGE_ERROR'
            });
        }
        // Generate response
        if (!session) {
            return res.status(400).json({ error: 'No active session found for response generation' });
        }
        const response = VoiceMergeLogic_1.voiceMergeLogic.generateResponse(session, delta);
        console.log(`📤 Generated response:`, {
            type: response.type,
            speak: response.speak,
            sessionId: session.sessionId,
            hasResult: !!response.result,
            hasParsed: !!response.parsed
        });
        // Convert to legacy format for iOS compatibility
        const legacyResponse = {
            needsFollowup: response.type === 'followup',
            missing: session.missing,
            question: response.speak,
            result: response.result || response.parsed || null,
            speak: response.speak,
            sessionId: session.sessionId
        };
        console.log(`📤 Sending legacy response:`, legacyResponse);
        res.json(legacyResponse);
    }
    catch (error) {
        console.error('Parse endpoint error:', error);
        res.status(500).json({
            error: 'Transcript parsing failed',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
/**
 * GET /voice/session/debug
 * Debug endpoint to dump active session for a user (DEV only)
 */
router.get('/session/debug', (req, res) => {
    try {
        const { userId } = req.query;
        if (!userId) {
            return res.status(400).json({ error: 'Missing userId query parameter' });
        }
        const userSessions = VoiceSessionStore_1.voiceSessionStore.getSessionsByUser(userId);
        const activeSessions = VoiceSessionStore_1.voiceSessionStore.getActiveSessionsByUser(userId);
        res.json({
            userId: userId,
            totalSessions: userSessions.length,
            activeSessions: activeSessions.length,
            sessions: userSessions.map(session => ({
                sessionId: session.sessionId,
                status: session.status,
                slots: session.slots,
                missing: session.missing,
                lastTurnIndex: session.lastTurnIndex,
                lastTurnId: session.lastTurnId,
                createdAt: session.createdAt,
                expiresAt: session.expiresAt
            }))
        });
    }
    catch (error) {
        console.error('Debug endpoint error:', error);
        res.status(500).json({
            error: 'Debug endpoint failed',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
exports.default = router;
//# sourceMappingURL=voice.js.map