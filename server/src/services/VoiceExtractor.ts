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
Extract slot information from user transcripts into JSON format.

CRITICAL RULES:
1. Respond with VALID JSON ONLY - no other text, no explanations
2. Extract ALL available information from the transcript - do not leave fields empty if they are mentioned
3. When user provides complete information, extract EVERYTHING in one response
4. Title must be the actual task description, not generic words like "task" or "chore"
5. Points must be a positive integer (extract the number only)
6. Dates must be natural language (e.g., "December 10th", "tomorrow", "Friday") - do NOT convert to ISO
7. Child names must match exactly from the available children roster
8. Intent: "new_task" for creating tasks, "answer" for responding to questions, "cancel" for cancellation

EXTRACTION PATTERNS (works for ANY sentence structure):
- Child names: Look for names from roster in phrases like "for [NAME]", "assign to [NAME]", "[NAME] should", etc.
- Task titles: Look for action descriptions after "task is to", "make [child] [action]", "to [action]", or standalone action phrases
- Dates: Look for time references like "tomorrow", "today", "[Day]", "[Month] [day]", "due on [date]", etc.
- Points: Look for numbers followed by "points", "worth [X] points", "for [X] points", etc.

AVAILABLE CHILDREN: ${childrenRoster.map(c => c.name).join(', ')}

JSON SCHEMA:
{
  "intent": "new_task" | "answer" | "cancel",
  "slot_updates": {
    "assignedChildName": "string (if child mentioned)",
    "title": "string (if task described)",
    "dueText": "string (if date/time mentioned)",
    "points": number (if points mentioned)
  }
}`;

    const userPrompt = `TRANSCRIPT: "${utterance}"

CURRENT CONTEXT:
- Existing slots: ${JSON.stringify(currentSlots)}
- Expected next slot: ${expectedSlot || 'none (any slot)'}
- Available children: ${childrenRoster.map(c => c.name).join(', ')}

INSTRUCTIONS:
Analyze the transcript and extract ALL mentioned information:
1. Child name: Any name from the roster list above
2. Task title: Any description of what needs to be done (action verbs, nouns describing work)
3. Due date: Any time reference (relative like "tomorrow" or absolute like "December 10th")
4. Points: Any number mentioned with "points" or "worth"

IMPORTANT:
- If information is present in the transcript, extract it - do not leave fields empty
- Handle any sentence structure, phrasing, or word order
- Extract natural language as-is (don't convert dates or format)
- Match child names case-insensitively but return the exact roster name

Return JSON with all extracted fields.`;

    try {
      // Check if API key is set
      if (!process.env.GOOGLE_AI_STUDIO_API_KEY) {
        console.error('❌ GOOGLE_AI_STUDIO_API_KEY is not set in environment variables!');
        throw new Error('GOOGLE_AI_STUDIO_API_KEY is missing');
      }

      console.log('🤖 Calling Gemini to extract from:', utterance.substring(0, 100) + '...');
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
      
      console.log('✅ Parsed Delta:', JSON.stringify(delta, null, 2));
      return delta;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('❌ Error extracting slot delta:', errorMessage);
      console.error('❌ Full error:', error);
      
      // Try to extract basic information from utterance even if AI fails
      const utteranceLower = utterance.toLowerCase();
      const extractedSlots: any = {};
      
      // Try to extract child name
      for (const child of childrenRoster) {
        if (utteranceLower.includes(child.name.toLowerCase())) {
          extractedSlots.assignedChildName = child.name;
          break;
        }
      }
      
      // Try to extract points
      const pointsMatch = utterance.match(/(\d+)\s*points?/i);
      if (pointsMatch) {
        extractedSlots.points = parseInt(pointsMatch[1]);
      }
      
      // Try to extract date (simple patterns)
      const datePatterns = [
        /(tomorrow|today)/i,
        /(december|january|february|march|april|may|june|july|august|september|october|november)\s+\d+/i,
        /due\s+(on\s+)?([a-z]+day|[a-z]+\s+\d+)/i
      ];
      for (const pattern of datePatterns) {
        const match = utterance.match(pattern);
        if (match) {
          extractedSlots.dueText = match[0];
          break;
        }
      }
      
      // Try to extract task title (anything after "task is to" or "task is")
      const taskMatch = utterance.match(/task\s+is\s+(?:to\s+)?(.+?)(?:\.|$|due|worth|points|and\s+is|it\s+is)/i);
      if (taskMatch) {
        let title = taskMatch[1].trim();
        // Clean up common trailing words
        title = title.replace(/\s+(and\s+is|is\s+worth|worth)\s+\d+.*$/i, '').trim();
        extractedSlots.title = title;
      }
      
      console.log('⚠️ Using fallback extraction:', extractedSlots);
      
      // Return safe fallback with extracted info if available
      if (utteranceLower.includes('cancel') || utteranceLower.includes('stop')) {
        return {
          intent: 'cancel',
          slot_updates: {},
          notes: 'Extraction failed, assuming cancel'
        };
      } else if (utteranceLower.includes('create') || utteranceLower.includes('task')) {
        return {
          intent: 'new_task',
          slot_updates: Object.keys(extractedSlots).length > 0 ? extractedSlots : {},
          notes: `Extraction failed: ${errorMessage}. Fallback extraction: ${Object.keys(extractedSlots).length} fields`
        };
      } else {
        return {
          intent: 'answer',
          slot_updates: extractedSlots,
          notes: `Extraction failed: ${errorMessage}. Fallback extraction: ${Object.keys(extractedSlots).length} fields`
        };
      }
    }
  }
}

export const voiceExtractor = new VoiceExtractor();
