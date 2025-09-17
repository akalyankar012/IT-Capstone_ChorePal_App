import fetch from "node-fetch";
import { ParseRequest, ParseResponse, ParseResultSchema, TaskFieldsSchema } from '../lib/schema';
import { parseRelativeDate, getCurrentDateISO } from '../lib/time';
import { findBestChildMatch, generateChildFollowUpQuestion } from '../lib/fuzzy';

// Load environment variables first
require('dotenv').config();

const MODEL = (process.env.GEMINI_MODEL || "gemini-2.0-flash").trim();
const API_KEY = (process.env.GOOGLE_AI_STUDIO_API_KEY || "").trim();

if (!API_KEY) {
  console.warn("[Gemini] GOOGLE_AI_STUDIO_API_KEY is not set. Calls will fail until provided.");
}

console.log('🔧 AI Studio Configuration:');
console.log(`   Model: ${MODEL}`);
console.log(`   API Key: ${API_KEY ? 'Set' : 'Not set'}`);

/**
 * Call Google AI Studio Gemini API with strict JSON response
 */
export async function geminiParseStrictJSON(system: string, user: string): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}`;
  const body = {
    systemInstruction: { parts: [{ text: system }] },
    contents: [{ role: "user", parts: [{ text: user }] }],
    generationConfig: {
      responseMimeType: "application/json", // force JSON
      temperature: 0.2,
      maxOutputTokens: 512
    }
  };

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`AI Studio error ${res.status}: ${text}`);
  }

  const data = await res.json();
  const out =
    data?.candidates?.[0]?.content?.parts?.[0]?.text ??
    data?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data ??
    "";

  if (!out) throw new Error("AI Studio returned empty response");
  return out;
}

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

    // Call AI Studio with strict JSON
    const jsonResponse = await geminiParseStrictJSON(systemPrompt, userPrompt);
    
    console.log('🤖 AI Studio response:', jsonResponse);
    
    // Parse JSON response
    let parsedResponse;
    try {
      parsedResponse = JSON.parse(jsonResponse);
    } catch (parseError) {
      console.error('❌ Failed to parse AI Studio JSON:', parseError);
      throw new Error('Invalid JSON response from AI Studio');
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
    console.error('❌ AI Studio parsing error:', error);
    throw new Error(`AI Studio parsing failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}