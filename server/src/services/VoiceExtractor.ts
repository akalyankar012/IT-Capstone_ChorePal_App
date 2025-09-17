import { GoogleGenerativeAI } from '@google/generative-ai';
import { SlotDelta } from '../models/VoiceSession';

require('dotenv').config();

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_STUDIO_API_KEY!);

export class VoiceExtractor {
  private model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

  async extractSlotDelta(
    utterance: string,
    currentSlots: any,
    expectedSlot: string | undefined,
    childrenRoster: Array<{id: string; name: string}>
  ): Promise<SlotDelta> {
    const systemPrompt = `You are a slot extraction assistant for a voice task creation app. Extract information from user utterances and return JSON only.

CRITICAL: Return ONLY valid JSON, no other text.

SLOT MAPPING:
- Child names from roster → assignedChildName
- Task descriptions → title  
- Time references → dueText
- Point values → points

EXAMPLES:
- "Emma" → {"intent": "answer", "slot_updates": {"assignedChildName": "Emma"}}
- "clean her room" → {"intent": "answer", "slot_updates": {"title": "clean her room"}}
- "tomorrow" → {"intent": "answer", "slot_updates": {"dueText": "tomorrow"}}
- "50 points" → {"intent": "answer", "slot_updates": {"points": 50}}
- "Create task for Emma, due tomorrow, worth 50 points" → {"intent": "answer", "slot_updates": {"assignedChildName": "Emma", "dueText": "tomorrow", "points": 50}}

RESPONSE FORMAT:
{
  "intent": "answer|revise|new_task|cancel|noop",
  "slot_updates": {
    "assignedChildName": "Emma",
    "title": "clean her room", 
    "dueText": "tomorrow",
    "points": 50
  },
  "ambiguous": [],
  "notes": "optional"
}`;

    const userPrompt = `Current slots: ${JSON.stringify(currentSlots)}
Expected slot: ${expectedSlot || 'none'}
Children roster: ${JSON.stringify(childrenRoster)}
User utterance: "${utterance}"

EXTRACTION RULES:
1. If user mentions a child name from the roster, set assignedChildName
2. If user describes a task (clean, make, do, etc.), set title
3. If user mentions time (today, tomorrow, Friday, etc.), set dueText
4. If user mentions points (10 points, worth 20, etc.), set points
5. If this is a follow-up answer, extract only what the user provided
6. If this is a complete command, extract ALL available information

EXAMPLES:
- "Create task for Emma" → {"assignedChildName": "Emma"}
- "clean her room" → {"title": "clean her room"}
- "tomorrow" → {"dueText": "tomorrow"}
- "50 points" → {"points": 50}
- "Create task for Emma, that is due tomorrow worth 50 points" → {"assignedChildName": "Emma", "dueText": "tomorrow", "points": 50}

Extract the slot updates from this utterance.`;

    try {
      const result = await this.model.generateContent([systemPrompt, userPrompt]);
      const response = await result.response;
      const text = response.text();
      
      console.log('AI Response:', text);
      
      // Clean up the response - remove markdown code blocks if present
      let cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.replace(/^```json\s*/, '').replace(/\s*```$/, '');
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.replace(/^```\s*/, '').replace(/\s*```$/, '');
      }
      
      console.log('Cleaned text:', cleanText);
      
      // Parse JSON response
      const delta = JSON.parse(cleanText) as SlotDelta;
      console.log('Parsed Delta:', delta);
      return delta;
    } catch (error) {
      console.error('Error extracting slot delta:', error);
      return {
        intent: 'noop',
        slot_updates: {},
        notes: 'Extraction failed'
      };
    }
  }
}

export const voiceExtractor = new VoiceExtractor();
