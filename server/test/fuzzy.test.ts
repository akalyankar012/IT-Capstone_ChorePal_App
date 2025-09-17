import { findBestChildMatch, generateChildFollowUpQuestion } from '../src/lib/fuzzy';
import { Child } from '../src/lib/schema';

const mockChildren: Child[] = [
  { id: '1', name: 'Emma' },
  { id: '2', name: 'Zayn' },
  { id: '3', name: 'Liam' },
  { id: '4', name: 'Sophia' }
];

describe('Fuzzy matching', () => {
  test('should find exact match', () => {
    const result = findBestChildMatch('Emma', mockChildren);
    expect(result.match?.name).toBe('Emma');
    expect(result.isAmbiguous).toBe(false);
  });

  test('should find starts with match', () => {
    const result = findBestChildMatch('Em', mockChildren);
    expect(result.match?.name).toBe('Emma');
    expect(result.isAmbiguous).toBe(false);
  });

  test('should handle ambiguous matches', () => {
    const result = findBestChildMatch('E', mockChildren);
    expect(result.match).toBeNull();
    expect(result.isAmbiguous).toBe(true);
    expect(result.candidates.length).toBeGreaterThan(1);
  });

  test('should handle no matches', () => {
    const result = findBestChildMatch('Xavier', mockChildren);
    expect(result.match).toBeNull();
    expect(result.isAmbiguous).toBe(false);
    expect(result.candidates).toEqual([]);
  });
});

describe('Follow-up questions', () => {
  test('should generate question for two candidates', () => {
    const candidates = [mockChildren[0], mockChildren[1]];
    const question = generateChildFollowUpQuestion(candidates);
    expect(question).toContain('Did you mean');
    expect(question).toContain('Emma');
    expect(question).toContain('Zayn');
  });

  test('should generate question for multiple candidates', () => {
    const candidates = mockChildren.slice(0, 3);
    const question = generateChildFollowUpQuestion(candidates);
    expect(question).toContain('Which child');
    expect(question).toContain('Emma');
    expect(question).toContain('Zayn');
    expect(question).toContain('Liam');
  });
});

