import { VertexAI } from '@google-cloud/vertexai';
import { ParseRequest, ParseResponse, ParseResultSchema, TaskFieldsSchema } from '../lib/schema';
import { parseRelativeDate, getCurrentDateISO } from '../lib/time';
import { findBestChildMatch, generateChildFollowUpQuestion } from '../lib/fuzzy';

const projectId = process.env.GCP_PROJECT_ID || 'chorepal-ios-app-472321';
const location = process.env.GCP_REGION || 'us-central1';

const vertexAI = new VertexAI({ project: projectId, location: location });
const model = 'gemini-1.5-flash';

/**
 * Parse transcript using Gemini to extract task fields
 */
export async function parseTranscript(request: ParseRequest): Promise<ParseResponse> {
  try {
    const currentDate = request.currentDate || getCurrentDateISO();
    const children = request.children || [];
    
    // System prompt for strict JSON extraction
    const systemPrompt = `You are an assistant that extracts chore task information from voice commands for a family app.

CRITICAL RULES:
1. You MUST respond with valid JSON only, no other text
2. Required fields: childId, title, dueAt (ISO 8601 in America/Chicago), points
3. If ANY field is missing or ambiguous, return needsFollowup: true with ONE short question
4. Child names must match exactly from the provided children list
5. Parse relative dates like "today", "tomorrow", "Saturday 5pm" to ISO format
6. Default time is 6:00 PM if only a day is mentioned
7. Points must be positive integers

Children available: ${children.map(c => `${c.id}:${c.name}`).join(', ')}

Current date: ${currentDate}

RESPONSE FORMATS:
- Complete: {"needsFollowup": false, "result": {"childId": "id", "title": "task", "dueAt": "2024-01-15T18:00:00.000-05:00", "points": 20}}
- Incomplete: {"needsFollowup": true, "missing": ["field1", "field2"], "question": "What time should this be due?"}`;

    const userPrompt = `Transcript: "${request.transcript}"

Extract the task information. If anything is missing or unclear, ask ONE specific question.`;

    const generativeModel = vertexAI.getGenerativeModel({ model });
    
    const result = await generativeModel.generateContent([
      { role: 'user', parts: [{ text: systemPrompt }] },
      { role: 'user', parts: [{ text: userPrompt }] }
    ]);

    const response = await result.response;
    const text = response.text();
    
    console.log('🤖 Gemini response:', text);
    
    // Parse JSON response
    let parsedResponse;
    try {
      parsedResponse = JSON.parse(text);
    } catch (parseError) {
      console.error('❌ Failed to parse Gemini JSON:', parseError);
      throw new Error('Invalid JSON response from Gemini');
    }
    
    // Validate with Zod schema
    const validatedResponse = ParseResultSchema.parse(parsedResponse);
    
    // If we have a complete result, validate the task fields
    if (!validatedResponse.needsFollowup && validatedResponse.result) {
      const taskFields = TaskFieldsSchema.parse(validatedResponse.result);
      
      // Validate child ID exists
      const childExists = children.some(c => c.id === taskFields.childId);
      if (!childExists) {
        return {
          needsFollowup: true,
          missing: ['childId'],
          question: `I don't recognize that child. Available children: ${children.map(c => c.name).join(', ')}`
        };
      }
      
      // Validate due date is in the future
      const dueDate = new Date(taskFields.dueAt);
      const now = new Date();
      if (dueDate <= now) {
        return {
          needsFollowup: true,
          missing: ['dueAt'],
          question: 'The due date must be in the future. When should this task be completed?'
        };
      }
    }
    
    return validatedResponse;

  } catch (error) {
    console.error('❌ Gemini parsing error:', error);
    throw new Error(`Gemini parsing failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
