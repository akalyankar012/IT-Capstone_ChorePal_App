export class DateNormalizer {
  normalizeDueText(dueText: string): string {
    if (!dueText) return '';
    
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    // Handle common relative phrases
    const lowerText = dueText.toLowerCase().trim();
    
    // Today
    if (lowerText.includes('today')) {
      const time = this.extractTime(dueText) || '18:00'; // Default to 6 PM
      const [hours, minutes] = time.split(':').map(Number);
      const dueDate = new Date(today);
      dueDate.setHours(hours, minutes, 0, 0);
      return dueDate.toISOString();
    }
    
    // Tomorrow
    if (lowerText.includes('tomorrow')) {
      const time = this.extractTime(dueText) || '18:00'; // Default to 6 PM
      const [hours, minutes] = time.split(':').map(Number);
      const dueDate = new Date(today);
      dueDate.setDate(dueDate.getDate() + 1);
      dueDate.setHours(hours, minutes, 0, 0);
      return dueDate.toISOString();
    }
    
    // This week days
    const dayMap: { [key: string]: number } = {
      'sunday': 0, 'monday': 1, 'tuesday': 2, 'wednesday': 3,
      'thursday': 4, 'friday': 5, 'saturday': 6
    };
    
    for (const [day, dayNum] of Object.entries(dayMap)) {
      if (lowerText.includes(day)) {
        const time = this.extractTime(dueText) || '18:00';
        const [hours, minutes] = time.split(':').map(Number);
        const dueDate = new Date(today);
        
        // Find next occurrence of this day
        const daysUntil = (dayNum - dueDate.getDay() + 7) % 7;
        dueDate.setDate(dueDate.getDate() + (daysUntil === 0 ? 7 : daysUntil));
        dueDate.setHours(hours, minutes, 0, 0);
        return dueDate.toISOString();
      }
    }
    
    // Handle specific dates (basic parsing)
    const dateMatch = dueText.match(/(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?/);
    if (dateMatch) {
      const [, month, day, year] = dateMatch;
      const fullYear = year ? (year.length === 2 ? `20${year}` : year) : now.getFullYear();
      const time = this.extractTime(dueText) || '18:00';
      const [hours, minutes] = time.split(':').map(Number);
      
      const dueDate = new Date(parseInt(fullYear), parseInt(month) - 1, parseInt(day));
      dueDate.setHours(hours, minutes, 0, 0);
      return dueDate.toISOString();
    }
    
    // Default to tomorrow at 6 PM if we can't parse
    const dueDate = new Date(today);
    dueDate.setDate(dueDate.getDate() + 1);
    dueDate.setHours(18, 0, 0, 0);
    return dueDate.toISOString();
  }
  
  private extractTime(text: string): string | null {
    // Look for time patterns like "5 pm", "17:00", "5:30", etc.
    const timePatterns = [
      /(\d{1,2}):(\d{2})\s*(am|pm)?/i,
      /(\d{1,2})\s*(am|pm)/i,
      /(\d{1,2})\s*(am|pm)/i
    ];
    
    for (const pattern of timePatterns) {
      const match = text.match(pattern);
      if (match) {
        let hours = parseInt(match[1]);
        const minutes = match[2] ? parseInt(match[2]) : 0;
        const ampm = match[3]?.toLowerCase();
        
        if (ampm === 'pm' && hours !== 12) {
          hours += 12;
        } else if (ampm === 'am' && hours === 12) {
          hours = 0;
        }
        
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
      }
    }
    
    return null;
  }
}

export const dateNormalizer = new DateNormalizer();
