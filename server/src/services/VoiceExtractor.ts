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
        const systemPrompt = `You are a task extraction assistant for a family chore app.
Your job is to extract slot information from a user transcript.

Rules:
- Respond with JSON ONLY using the schema provided.
- Do not generate ISO dates. Always return natural text in dueText.
- Do not generate child IDs. Only return assignedChildName if heard.
- Title must be the actual task, not placeholders like "task" or "chore".
- Points must be integers if given.
- Intent must be "new_task", "answer", or "cancel".
- If any required info is missing, set needsFollowup=true and ask ONE short question.

AVAILABLE CHILDREN: ${childrenRoster.map(c => c.name).join(', ')}

Examples:
User: "Create task for Emma tomorrow worth 20 points"
→ {"intent": "new_task", "slot_updates": {"assignedChildName":"Emma","dueText":"tomorrow","points":20}}

User: "Clean her room"
→ {"intent": "answer", "slot_updates": {"title":"clean her room"}}

User: "Make Zayn take out trash on October 8"
→ {"intent": "new_task", "slot_updates": {"assignedChildName":"Zayn","title":"take out trash","dueText":"October 8"}}

User: "15 points"
→ {"intent": "answer", "slot_updates": {"points":15}}

User: "cancel"
→ {"intent": "cancel", "slot_updates": {}}`;

    const userPrompt = `Transcript: "${utterance}"

Extract slot information from this transcript.`;

    try {
      const result = await this.model.generateContent([systemPrompt, userPrompt]);
      const response = await result.response;
      const text = response.text();
      
      console.log('🤖 AI Response:', text);
      
      // Clean up the response - remove markdown code blocks if present
      let cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.replace(/^```json\s*/, '').replace(/\s*```$/, '');
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.replace(/^```\s*/, '').replace(/\s*```$/, '');
      }
      
      console.log('🧹 Cleaned text:', cleanText);
      
      // Parse JSON response with validation
      const delta = JSON.parse(cleanText) as SlotDelta;
      
      // Validate delta structure
      if (!delta || typeof delta !== 'object') {
        throw new Error('Invalid delta structure');
      }
      
      if (!delta.intent || !delta.slot_updates) {
        throw new Error('Missing required delta fields');
      }
      
      console.log('✅ Parsed Delta:', delta);
      return delta;
    } catch (error) {
      console.error('❌ Error extracting slot delta:', error);
      
      // Return safe fallback based on utterance
      const utteranceLower = utterance.toLowerCase();
      if (utteranceLower.includes('cancel') || utteranceLower.includes('stop')) {
        return {
          intent: 'cancel',
          slot_updates: {},
          notes: 'Extraction failed, assuming cancel'
        };
      } else if (utteranceLower.includes('create') || utteranceLower.includes('task')) {
        return {
          intent: 'new_task',
          slot_updates: {},
          notes: 'Extraction failed, assuming new task'
        };
      } else {
        return {
          intent: 'answer',
          slot_updates: {},
          notes: 'Extraction failed, assuming answer'
        };
      }
    }
  }
}

export const voiceExtractor = new VoiceExtractor();
