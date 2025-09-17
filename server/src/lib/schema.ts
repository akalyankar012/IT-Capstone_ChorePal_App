import { z } from 'zod';

// Task fields schema
export const TaskFieldsSchema = z.object({
  childId: z.string().min(1, 'Child ID is required'),
  title: z.string().min(1, 'Title is required'),
  dueAt: z.string().regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[+-]\d{2}:\d{2})$/, 'Invalid ISO date format'),
  points: z.number().int().min(1, 'Points must be a positive integer')
});

// Parse result schemas
export const ParseResultSchema = z.discriminatedUnion('needsFollowup', [
  z.object({
    needsFollowup: z.literal(true),
    missing: z.array(z.string()),
    question: z.string()
  }),
  z.object({
    needsFollowup: z.literal(false),
    result: TaskFieldsSchema
  })
]);

// Standardized response envelope
export const VoiceResponseSchema = z.object({
  type: z.enum(['followup', 'confirmed']),
  parsed: z.any(), // Will be ParseResult or TaskFields
  speak: z.string() // Exact sentence to speak aloud
});

// Child schema for fuzzy matching
export const ChildSchema = z.object({
  id: z.string(),
  name: z.string()
});

// Type exports
export type TaskFields = z.infer<typeof TaskFieldsSchema>;
export type ParseResult = z.infer<typeof ParseResultSchema>;
export type Child = z.infer<typeof ChildSchema>;
export type VoiceResponse = z.infer<typeof VoiceResponseSchema>;

// Request/Response types
export interface STTRequest {
  audio: Buffer;
  phraseHints?: string[];
}

export interface STTResponse {
  transcript: string;
}

export interface ParseRequest {
  transcript: string;
  children: Child[];
  currentDate?: string; // ISO date for context
  conversationContext?: string; // Recent conversation for context
}

export interface ParseResponse extends ParseResult {}
