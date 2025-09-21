import { ParseRequest, ParseResponse } from '../lib/schema';
/**
 * Call Google AI Studio Gemini API with strict JSON response
 */
export declare function geminiParseStrictJSON(system: string, user: string): Promise<string>;
/**
 * Parse transcript using Gemini to extract task fields
 */
export declare function parseTranscript(request: ParseRequest): Promise<ParseResponse>;
//# sourceMappingURL=gemini.d.ts.map