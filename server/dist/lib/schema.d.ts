import { z } from 'zod';
export declare const TaskFieldsSchema: z.ZodObject<{
    childId: z.ZodString;
    title: z.ZodString;
    dueAt: z.ZodString;
    points: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    childId: string;
    title: string;
    dueAt: string;
    points: number;
}, {
    childId: string;
    title: string;
    dueAt: string;
    points: number;
}>;
export declare const ParseResultSchema: z.ZodDiscriminatedUnion<"needsFollowup", [z.ZodObject<{
    needsFollowup: z.ZodLiteral<true>;
    missing: z.ZodArray<z.ZodString, "many">;
    question: z.ZodString;
}, "strip", z.ZodTypeAny, {
    needsFollowup: true;
    missing: string[];
    question: string;
}, {
    needsFollowup: true;
    missing: string[];
    question: string;
}>, z.ZodObject<{
    needsFollowup: z.ZodLiteral<false>;
    result: z.ZodObject<{
        childId: z.ZodString;
        title: z.ZodString;
        dueAt: z.ZodString;
        points: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        childId: string;
        title: string;
        dueAt: string;
        points: number;
    }, {
        childId: string;
        title: string;
        dueAt: string;
        points: number;
    }>;
}, "strip", z.ZodTypeAny, {
    needsFollowup: false;
    result: {
        childId: string;
        title: string;
        dueAt: string;
        points: number;
    };
}, {
    needsFollowup: false;
    result: {
        childId: string;
        title: string;
        dueAt: string;
        points: number;
    };
}>]>;
export declare const VoiceResponseSchema: z.ZodObject<{
    type: z.ZodEnum<["followup", "confirmed"]>;
    parsed: z.ZodAny;
    speak: z.ZodString;
}, "strip", z.ZodTypeAny, {
    type: "followup" | "confirmed";
    speak: string;
    parsed?: any;
}, {
    type: "followup" | "confirmed";
    speak: string;
    parsed?: any;
}>;
export declare const ChildSchema: z.ZodObject<{
    id: z.ZodString;
    name: z.ZodString;
}, "strip", z.ZodTypeAny, {
    id: string;
    name: string;
}, {
    id: string;
    name: string;
}>;
export type TaskFields = z.infer<typeof TaskFieldsSchema>;
export type ParseResult = z.infer<typeof ParseResultSchema>;
export type Child = z.infer<typeof ChildSchema>;
export type VoiceResponse = z.infer<typeof VoiceResponseSchema>;
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
    currentDate?: string;
    conversationContext?: string;
}
export interface ParseResponse {
    needsFollowup: boolean;
    missing: string[];
    question: string;
    result: TaskFields | null;
    speak: string;
    sessionId: string;
}
//# sourceMappingURL=schema.d.ts.map