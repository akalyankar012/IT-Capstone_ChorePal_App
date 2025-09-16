import { zonedTimeToUtc, utcToZonedTime, format } from 'date-fns';
import { zonedTimeToUtc as zonedTimeToUtcTz, utcToZonedTime as utcToZonedTimeTz } from 'date-fns-tz';

const TIMEZONE = 'America/Chicago';

/**
 * Parse relative date expressions to ISO 8601 in America/Chicago timezone
 */
export function parseRelativeDate(text: string, baseDate: Date = new Date()): string {
  const now = utcToZonedTimeTz(baseDate, TIMEZONE);
  const textLower = text.toLowerCase().trim();
  
  // Today
  if (textLower.includes('today') || textLower.includes('tonight')) {
    const time = extractTime(textLower) || '18:00'; // Default to 6 PM
    const today = format(now, 'yyyy-MM-dd');
    return `${today}T${time}:00.000-05:00`;
  }
  
  // Tomorrow
  if (textLower.includes('tomorrow')) {
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const time = extractTime(textLower) || '18:00';
    const dateStr = format(tomorrow, 'yyyy-MM-dd');
    return `${dateStr}T${time}:00-05:00`;
  }
  
  // Day of week (this week or next week)
  const dayMatch = textLower.match(/(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/i);
  if (dayMatch) {
    const dayName = dayMatch[1].toLowerCase();
    const dayOfWeek = getDayOfWeek(dayName);
    const time = extractTime(textLower) || '18:00';
    
    // Calculate the next occurrence of this day
    const targetDate = new Date(now);
    const currentDay = now.getDay();
    const daysUntilTarget = (dayOfWeek - currentDay + 7) % 7;
    
    // If it's the same day and no time specified, assume next week
    if (daysUntilTarget === 0 && !extractTime(textLower)) {
      targetDate.setDate(targetDate.getDate() + 7);
    } else {
      targetDate.setDate(targetDate.getDate() + daysUntilTarget);
    }
    
    const dateStr = format(targetDate, 'yyyy-MM-dd');
    return `${dateStr}T${time}:00-05:00`;
  }
  
  // Next week
  if (textLower.includes('next week')) {
    const nextWeek = new Date(now);
    nextWeek.setDate(nextWeek.getDate() + 7);
    const time = extractTime(textLower) || '18:00';
    const dateStr = format(nextWeek, 'yyyy-MM-dd');
    return `${dateStr}T${time}:00-05:00`;
  }
  
  // Default to tomorrow at 6 PM if no clear date
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const dateStr = format(tomorrow, 'yyyy-MM-dd');
  return `${dateStr}T18:00:00-05:00`;
}

/**
 * Extract time from text (supports formats like "5pm", "5:30pm", "17:00")
 */
function extractTime(text: string): string | null {
  // Match patterns like "5pm", "5:30pm", "5:30 pm"
  const timeMatch = text.match(/(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/i);
  if (!timeMatch) return null;
  
  let hours = parseInt(timeMatch[1]);
  const minutes = timeMatch[2] ? parseInt(timeMatch[2]) : 0;
  const period = timeMatch[3]?.toLowerCase();
  
  // Convert to 24-hour format
  if (period === 'pm' && hours !== 12) {
    hours += 12;
  } else if (period === 'am' && hours === 12) {
    hours = 0;
  }
  
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
}

/**
 * Get day of week number (0 = Sunday, 1 = Monday, etc.)
 */
function getDayOfWeek(dayName: string): number {
  const days = {
    'sunday': 0, 'monday': 1, 'tuesday': 2, 'wednesday': 3,
    'thursday': 4, 'friday': 5, 'saturday': 6
  };
  return days[dayName.toLowerCase() as keyof typeof days] ?? 0;
}

/**
 * Get current date in America/Chicago timezone as ISO string
 */
export function getCurrentDateISO(): string {
  const now = utcToZonedTimeTz(new Date(), TIMEZONE);
  return now.toISOString();
}
