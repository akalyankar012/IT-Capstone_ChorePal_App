import { Child } from './schema';
/**
 * Simple fuzzy matching for child names
 */
export declare function findBestChildMatch(inputName: string, children: Child[]): {
    match: Child | null;
    isAmbiguous: boolean;
    candidates: Child[];
};
/**
 * Generate follow-up question for ambiguous child names
 */
export declare function generateChildFollowUpQuestion(candidates: Child[]): string;
//# sourceMappingURL=fuzzy.d.ts.map