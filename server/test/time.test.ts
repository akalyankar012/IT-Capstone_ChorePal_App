import { parseRelativeDate, getCurrentDateISO } from '../src/lib/time';

describe('Time parsing', () => {
  test('should parse "today" correctly', () => {
    const result = parseRelativeDate('today');
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}-05:00$/);
  });

  test('should parse "tomorrow" correctly', () => {
    const result = parseRelativeDate('tomorrow');
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}T18:00:00\.000-05:00$/);
  });

  test('should parse "tomorrow 5pm" correctly', () => {
    const result = parseRelativeDate('tomorrow 5pm');
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}T17:00:00\.000-05:00$/);
  });

  test('should parse "Saturday 3pm" correctly', () => {
    const result = parseRelativeDate('Saturday 3pm');
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}T15:00:00\.000-05:00$/);
  });

  test('should default to 6 PM when only day is specified', () => {
    const result = parseRelativeDate('Saturday');
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}T18:00:00\.000-05:00$/);
  });
});

