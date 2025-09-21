"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChildSchema = exports.VoiceResponseSchema = exports.ParseResultSchema = exports.TaskFieldsSchema = void 0;
const zod_1 = require("zod");
// Task fields schema
exports.TaskFieldsSchema = zod_1.z.object({
    childId: zod_1.z.string().min(1, 'Child ID is required'),
    title: zod_1.z.string().min(1, 'Title is required'),
    dueAt: zod_1.z.string().regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[+-]\d{2}:\d{2})$/, 'Invalid ISO date format'),
    points: zod_1.z.number().int().min(1, 'Points must be a positive integer')
});
// Parse result schemas
exports.ParseResultSchema = zod_1.z.discriminatedUnion('needsFollowup', [
    zod_1.z.object({
        needsFollowup: zod_1.z.literal(true),
        missing: zod_1.z.array(zod_1.z.string()),
        question: zod_1.z.string()
    }),
    zod_1.z.object({
        needsFollowup: zod_1.z.literal(false),
        result: exports.TaskFieldsSchema
    })
]);
// Standardized response envelope
exports.VoiceResponseSchema = zod_1.z.object({
    type: zod_1.z.enum(['followup', 'confirmed']),
    parsed: zod_1.z.any(), // Will be ParseResult or TaskFields
    speak: zod_1.z.string() // Exact sentence to speak aloud
});
// Child schema for fuzzy matching
exports.ChildSchema = zod_1.z.object({
    id: zod_1.z.string(),
    name: zod_1.z.string()
});
//# sourceMappingURL=schema.js.map