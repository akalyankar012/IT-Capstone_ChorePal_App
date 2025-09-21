"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.voiceExtractor = exports.VoiceExtractor = void 0;
const generative_ai_1 = require("@google/generative-ai");
require('dotenv').config();
const genAI = new generative_ai_1.GoogleGenerativeAI(process.env.GOOGLE_AI_STUDIO_API_KEY);
class VoiceExtractor {
    constructor() {
        this.model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    }
    async extractSlotDelta(utterance, currentSlots, expectedSlot, childrenRoster) {
        const systemPrompt = `You are an intelligent task creation assistant. Extract information from user speech and return JSON only.
        
        AVAILABLE CHILDREN: ${childrenRoster.map(c => c.name).join(', ')}
        
        EXTRACTION RULES:
        1. CHILD: Extract any child name mentioned from the available children list above
        2. TASK: Extract task description (clean room, do dishes, take out trash, etc.)
        3. TIME: Extract due date/time (tomorrow, today, Friday, next week, etc.)
        4. POINTS: Extract point value (20 points, 50, worth 100, etc.)
        5. INTENT: Determine user intent (new_task, answer, cancel, noop)
        
        CONTEXT AWARENESS:
        - If user says "create task" or "new task", set intent to "new_task"
        - If user provides missing information, set intent to "answer"
        - If user says "cancel" or "stop", set intent to "cancel"
        - If unclear, set intent to "noop"
        
        CHILD NAME MATCHING:
        - Match names exactly as they appear in the available children list
        - Be flexible with variations (e.g., "Mike" matches "Michael", "Alex" matches "Alexander")
        - If a name is not in the available children list, still extract it but note it may not be recognized
        
        EXAMPLES:
        - "Create task for Emma to clean room tomorrow worth 50 points" → {"intent": "new_task", "slot_updates": {"assignedChildName": "Emma", "title": "clean room", "dueText": "tomorrow", "points": 50}}
        - "Create task for Emma" → {"intent": "new_task", "slot_updates": {"assignedChildName": "Emma", "title": "task"}}
        - "Emma" → {"intent": "answer", "slot_updates": {"assignedChildName": "Emma"}}
        - "clean room" → {"intent": "answer", "slot_updates": {"title": "clean room"}}
        - "tomorrow" → {"intent": "answer", "slot_updates": {"dueText": "tomorrow"}}
        - "50 points" → {"intent": "answer", "slot_updates": {"points": 50}}
        - "cancel" → {"intent": "cancel", "slot_updates": {}}
        
        Return JSON only.`;
        const userPrompt = `User said: "${utterance}"
Extract what they want.`;
        try {
            const result = await this.model.generateContent([systemPrompt, userPrompt]);
            const response = await result.response;
            const text = response.text();
            console.log('🤖 AI Response:', text);
            // Clean up the response - remove markdown code blocks if present
            let cleanText = text.trim();
            if (cleanText.startsWith('```json')) {
                cleanText = cleanText.replace(/^```json\s*/, '').replace(/\s*```$/, '');
            }
            else if (cleanText.startsWith('```')) {
                cleanText = cleanText.replace(/^```\s*/, '').replace(/\s*```$/, '');
            }
            console.log('🧹 Cleaned text:', cleanText);
            // Parse JSON response with validation
            const delta = JSON.parse(cleanText);
            // Validate delta structure
            if (!delta || typeof delta !== 'object') {
                throw new Error('Invalid delta structure');
            }
            if (!delta.intent || !delta.slot_updates) {
                throw new Error('Missing required delta fields');
            }
            console.log('✅ Parsed Delta:', delta);
            return delta;
        }
        catch (error) {
            console.error('❌ Error extracting slot delta:', error);
            // Return safe fallback based on utterance
            const utteranceLower = utterance.toLowerCase();
            if (utteranceLower.includes('cancel') || utteranceLower.includes('stop')) {
                return {
                    intent: 'cancel',
                    slot_updates: {},
                    notes: 'Extraction failed, assuming cancel'
                };
            }
            else if (utteranceLower.includes('create') || utteranceLower.includes('task')) {
                return {
                    intent: 'new_task',
                    slot_updates: {},
                    notes: 'Extraction failed, assuming new task'
                };
            }
            else {
                return {
                    intent: 'answer',
                    slot_updates: {},
                    notes: 'Extraction failed, assuming answer'
                };
            }
        }
    }
}
exports.VoiceExtractor = VoiceExtractor;
exports.voiceExtractor = new VoiceExtractor();
//# sourceMappingURL=VoiceExtractor.js.map