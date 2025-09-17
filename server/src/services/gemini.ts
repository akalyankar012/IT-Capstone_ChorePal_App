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
    const systemPrompt = `You are an intelligent assistant that extracts chore task information from voice commands for a family app.

CRITICAL RULES:
1. You MUST respond with valid JSON only, no other text
2. Required fields: childId, title, dueAt (ISO 8601 in America/Chicago), points
3. If ANY field is missing or ambiguous, return needsFollowup: true with missing array and ONE specific question
4. Child names must match exactly from the provided children list
5. Parse relative dates like "today", "tomorrow", "Saturday 5pm" to ISO format
6. Default time is 6:00 PM if only a day is mentioned
7. Points must be positive integers
8. Task descriptions should be natural and clean - no "created with voice" or technical markers
9. Ask for ONE missing field at a time, not multiple fields
10. If user says "make bed" or "clean room", extract the task title from their words
11. If user mentions a child name, use that childId
12. If user mentions points, use those points
13. If user mentions a day/time, use that for dueAt
14. IMPORTANT: If user provides COMPLETE information in one command, extract ALL fields
15. If user says "Create a task for Ryan that is due tomorrow for 20 points" → extract ALL fields
16. If user says "Make Emma clean her room today worth 15 points" → extract ALL fields
17. Only ask follow-up questions if information is truly missing

FOLLOW-UP RESPONSE HANDLING:
- When user answers a follow-up question, combine their answer with previous context
- If user says "clean her room" when asked "What task should I create?", use "clean her room" as title
- If user says "Emma" when asked "Who should I assign this to?", use Emma's childId
- If user says "20 points" when asked "How many points?", use 20 for points
- If user says "tomorrow" when asked "When should this be completed?", use tomorrow for dueAt
- ALWAYS check if the user's response completes the missing information
- If the user's response fills the missing field, return the complete task
- If the user's response doesn't fill the missing field, ask for the next missing field

Children available: ${children.map(c => `${c.id}:${c.name}`).join(', ')}

Current date: ${currentDate}

RESPONSE FORMATS:
- Complete: {"needsFollowup": false, "result": {"childId": "id", "title": "task", "dueAt": "2024-01-15T18:00:00.000-05:00", "points": 20}}
- Missing child: {"needsFollowup": true, "missing": ["childId"], "question": "Who should I assign this to?"}
- Missing points: {"needsFollowup": true, "missing": ["points"], "question": "How many points should this be worth?"}
- Missing due date: {"needsFollowup": true, "missing": ["dueAt"], "question": "When should this be completed?"}
- Missing title: {"needsFollowup": true, "missing": ["title"], "question": "What task should I create?"}

EXAMPLES:
- "Make bed for Emma" → Missing: points, dueAt → Ask: "How many points should this be worth?"
- "Clean room for Zayn worth 10 points" → Missing: dueAt → Ask: "When should this be completed?"
- "Dishes tomorrow worth 15 points" → Missing: childId → Ask: "Who should I assign this to?"
- User says "50 points" when asked about points → Use 50 for points, ask for next missing field
- User says "Emma" when asked about child → Use Emma's childId, ask for next missing field`;

    const userPrompt = `Transcript: "${request.transcript}"
${request.conversationContext ? `\nRecent conversation: ${request.conversationContext}` : ''}

CRITICAL: Look for COMPLETE task information in the transcript. If the user provides multiple pieces of information, extract ALL of them.

STEP-BY-STEP PROCESSING:
1. First, check if this is a follow-up response by looking for "AI: What task should I create?" in the conversation
2. If yes, extract information from the previous "User:" message in the conversation
3. Combine the extracted information with the current transcript
4. If all fields are present, return the complete task
5. If any field is missing, ask for that specific field

FOLLOW-UP RESPONSE HANDLING:
- If the user is answering a follow-up question, combine their answer with previous context
- If user says "clean her room" when asked "What task should I create?", use "clean her room" as the title
- If user says "Emma" when asked "Who should I assign this to?", use Emma's childId
- If user says "20 points" when asked "How many points?", use 20 for points
- If user says "tomorrow" when asked "When should this be completed?", use tomorrow for dueAt

CONTEXT PARSING INSTRUCTIONS:
1. Look for "User: Create task for Emma, that is due tomorrow worth 50 points" in context
2. Extract: childId=Emma, dueAt=tomorrow, points=50
3. Look for "AI: What task should I create?" in context
4. This means the user is answering the question "What task should I create?"
5. If user says "clean her room", combine: childId=Emma, title="clean her room", dueAt=tomorrow, points=50
6. Return complete task with all fields filled

EXAMPLES OF FOLLOW-UP RESPONSES:
- Previous: "Create task for Emma, that is due tomorrow worth 50 points" → Missing: title
- User answers: "clean her room" → Complete: childId=Emma, title="clean her room", dueAt=tomorrow, points=50
- Previous: "Make a chore for Zayn" → Missing: title, dueAt, points
- User answers: "do dishes" → Still missing: dueAt, points → Ask: "When should this be completed?"

SPECIFIC EXAMPLE:
- Context: "User: Create task for Emma, that is due tomorrow worth 50 points | AI: What task should I create?"
- User says: "clean her room"
- Result: {"needsFollowup": false, "result": {"childId": "97CE6AF1-1EEC-4E9E-9C9B-3BA9164905AA", "title": "clean her room", "dueAt": "2025-09-18T18:00:00.000-05:00", "points": 50}}

ANOTHER EXAMPLE:
- Context: "User: Make a chore for Zayn | AI: What task should I create?"
- User says: "do dishes"
- Result: {"needsFollowup": true, "missing": ["dueAt", "points"], "question": "When should this be completed?"}

EXAMPLES OF COMPLETE COMMANDS:
- "Make Ryan clean his room tomorrow worth 15 points" → childId=Ryan, title="clean his room", dueAt=tomorrow, points=15
- "Have Emma do dishes today for 10 points" → childId=Emma, title="do dishes", dueAt=today, points=10
- "Emma should make her bed today for 5 points" → childId=Emma, title="make her bed", dueAt=today, points=5

EXAMPLES OF INCOMPLETE COMMANDS (should ask follow-up):
- "Create a task for Ryan that is due tomorrow for 20 points" → Missing: title → Ask: "What task should I create?"
- "Create task for Emma, that is due tomorrow worth 50 points" → Missing: title → Ask: "What task should I create?"
- "Make a chore for Zayn" → Missing: title, dueAt, points → Ask: "What task should I create?"

EXTRACTION RULES:
1. Look for child names: Emma, Zayn, Ryan, etc. → use that childId
2. Look for task descriptions: "clean room", "do dishes", "make bed" → use as title
3. Look for points: "20 points", "for 15 points" → use that number
4. Look for time: "tomorrow", "today", "Friday" → use for dueAt
5. If ALL fields are present, return complete task
6. If ANY field is missing, ask for that ONE field only
7. IMPORTANT: Generic words like "task", "chore", "assignment" are NOT valid task titles
8. If user says "create task" or "make a chore" without specifying what, ask "What task should I create?"

CONTEXT AWARENESS:
- Parse the conversation history to extract previous information
- Look for patterns like "User: Create task for Emma, that is due tomorrow worth 50 points" in context
- Look for patterns like "AI: What task should I create?" in context
- If context contains "Emma" and user says "clean her room", use Emma's childId
- If context contains "tomorrow" and user says "clean her room", use tomorrow for dueAt
- If context contains "50 points" and user says "clean her room", use 50 for points
- COMBINE all available information from context and current transcript
- If the conversation shows a follow-up question was asked, treat the current transcript as an answer to that question

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