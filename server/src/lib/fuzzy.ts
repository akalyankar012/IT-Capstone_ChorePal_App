import { Child } from './schema';

/**
 * Simple fuzzy matching for child names
 */
export function findBestChildMatch(inputName: string, children: Child[]): {
  match: Child | null;
  isAmbiguous: boolean;
  candidates: Child[];
} {
  if (children.length === 0) {
    return { match: null, isAmbiguous: false, candidates: [] };
  }
  
  const input = inputName.toLowerCase().trim();
  
  // Exact match first
  const exactMatch = children.find(child => 
    child.name.toLowerCase() === input
  );
  if (exactMatch) {
    return { match: exactMatch, isAmbiguous: false, candidates: [exactMatch] };
  }
  
  // Starts with match
  const startsWithMatches = children.filter(child =>
    child.name.toLowerCase().startsWith(input)
  );
  if (startsWithMatches.length === 1) {
    return { match: startsWithMatches[0], isAmbiguous: false, candidates: startsWithMatches };
  }
  
  // Contains match
  const containsMatches = children.filter(child =>
    child.name.toLowerCase().includes(input)
  );
  if (containsMatches.length === 1) {
    return { match: containsMatches[0], isAmbiguous: false, candidates: containsMatches };
  }
  
  // Levenshtein distance for fuzzy matching
  const scoredMatches = children.map(child => ({
    child,
    score: levenshteinDistance(input, child.name.toLowerCase())
  })).filter(match => match.score <= 3); // Max distance of 3
  
  if (scoredMatches.length === 0) {
    return { match: null, isAmbiguous: false, candidates: [] };
  }
  
  // Sort by score (lower is better)
  scoredMatches.sort((a, b) => a.score - b.score);
  const bestScore = scoredMatches[0].score;
  const bestMatches = scoredMatches.filter(match => match.score === bestScore);
  
  if (bestMatches.length === 1) {
    return { match: bestMatches[0].child, isAmbiguous: false, candidates: [bestMatches[0].child] };
  }
  
  // Multiple matches with same score = ambiguous
  return {
    match: null,
    isAmbiguous: true,
    candidates: bestMatches.map(m => m.child)
  };
}

/**
 * Calculate Levenshtein distance between two strings
 */
function levenshteinDistance(str1: string, str2: string): number {
  const matrix = Array(str2.length + 1).fill(null).map(() => Array(str1.length + 1).fill(null));
  
  for (let i = 0; i <= str1.length; i++) matrix[0][i] = i;
  for (let j = 0; j <= str2.length; j++) matrix[j][0] = j;
  
  for (let j = 1; j <= str2.length; j++) {
    for (let i = 1; i <= str1.length; i++) {
      const indicator = str1[i - 1] === str2[j - 1] ? 0 : 1;
      matrix[j][i] = Math.min(
        matrix[j][i - 1] + 1,     // deletion
        matrix[j - 1][i] + 1,     // insertion
        matrix[j - 1][i - 1] + indicator // substitution
      );
    }
  }
  
  return matrix[str2.length][str1.length];
}

/**
 * Generate follow-up question for ambiguous child names
 */
export function generateChildFollowUpQuestion(candidates: Child[]): string {
  if (candidates.length === 0) {
    return "I didn't find any children with that name. Could you try again?";
  }
  
  if (candidates.length === 2) {
    return `Did you mean ${candidates[0].name} or ${candidates[1].name}?`;
  }
  
  const names = candidates.map(c => c.name);
  const last = names.pop();
  return `Which child did you mean: ${names.join(', ')}, or ${last}?`;
}

