"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.dateNormalizer = exports.DateNormalizer = void 0;
class DateNormalizer {
    normalizeDueText(dueText) {
        if (!dueText)
            return '';
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        console.log(`🗓️ DateNormalizer input: "${dueText}"`);
        console.log(`🗓️ Current date: ${now.toISOString()}`);
        console.log(`🗓️ Today: ${today.toISOString()}`);
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
            // Debug logging
            console.log(`🗓️ Tomorrow calculation:`, {
                input: dueText,
                extractedTime: time,
                hours,
                minutes,
                dueDate: dueDate.toISOString(),
                localDate: dueDate.toLocaleString()
            });
            // Validate the date
            if (isNaN(dueDate.getTime())) {
                console.error(`❌ Invalid date created: ${dueDate}`);
                // Fallback to tomorrow at 6 PM
                const fallbackDate = new Date(today);
                fallbackDate.setDate(fallbackDate.getDate() + 1);
                fallbackDate.setHours(18, 0, 0, 0);
                return fallbackDate.toISOString();
            }
            return dueDate.toISOString();
        }
        // This week days
        const dayMap = {
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
        // Handle "September 18th at 5 p.m." format
        const monthNames = ['january', 'february', 'march', 'april', 'may', 'june',
            'july', 'august', 'september', 'october', 'november', 'december'];
        for (let i = 0; i < monthNames.length; i++) {
            const monthName = monthNames[i];
            if (lowerText.includes(monthName)) {
                const dayMatch = dueText.match(new RegExp(`${monthName}\\s+(\\d{1,2})(?:st|nd|rd|th)?`, 'i'));
                if (dayMatch) {
                    const day = parseInt(dayMatch[1]);
                    const time = this.extractTime(dueText) || '18:00';
                    const [hours, minutes] = time.split(':').map(Number);
                    // Create date directly in UTC to avoid timezone conversion issues
                    const dueDate = new Date(Date.UTC(now.getFullYear(), i, day, hours, minutes, 0, 0));
                    console.log(`🗓️ Month name parsing:`, {
                        input: dueText,
                        monthName,
                        day,
                        time,
                        hours,
                        minutes,
                        dueDate: dueDate.toISOString(),
                        localDate: dueDate.toLocaleString()
                    });
                    return dueDate.toISOString();
                }
            }
        }
        // Handle specific dates (basic parsing)
        const dateMatch = dueText.match(/(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?/);
        if (dateMatch) {
            const [, month, day, year] = dateMatch;
            const fullYear = year ? (year.length === 2 ? `20${year}` : year) : now.getFullYear().toString();
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
    extractTime(text) {
        const lowerText = text.toLowerCase();
        console.log(`🕐 Extracting time from: "${text}"`);
        // Handle special times
        if (lowerText.includes('midnight')) {
            console.log(`🕐 Found midnight`);
            return '00:00';
        }
        if (lowerText.includes('noon')) {
            console.log(`🕐 Found noon`);
            return '12:00';
        }
        // Look for time patterns like "5 pm", "17:00", "5:30", "10.09 p.m.", etc.
        // Order matters - more specific patterns first
        const timePatterns = [
            /(\d{1,2})\.(\d{2})\s*(am|pm|a\.m\.|p\.m\.|a\.m|p\.m)/i, // Decimal time first: "10.09 p.m."
            /(\d{1,2}):(\d{2})\s*(am|pm)?/i, // Standard time: "11:30 am"
            /(\d{1,2})\s+(\d{1,2})\s*(am|pm|a\.m\.|p\.m\.|a\.m|p\.m)/i, // Space separated: "5 10 p.m." or "5 10 pm"
            /(\d{1,2})\s*(am|pm)/i, // Simple time: "11 am"
            /(\d{1,2})\s*(a\.m\.|p\.m\.)/i, // Dotted time: "11 a.m."
            /(\d{1,2})\s*(a\.m|p\.m)/i // Partial dotted: "11 a.m"
        ];
        for (const pattern of timePatterns) {
            const match = text.match(pattern);
            if (match) {
                console.log(`🕐 Pattern matched:`, match);
                let hours = parseInt(match[1]);
                let minutes = 0;
                let ampm = '';
                // Handle different regex patterns
                if (match[2] && !isNaN(parseInt(match[2]))) {
                    // Pattern with minutes: "11:30 am", "10.09 p.m.", or "5 10 p.m."
                    minutes = parseInt(match[2]);
                    ampm = match[3]?.toLowerCase().replace(/\./g, '') || '';
                }
                else {
                    // Pattern without minutes: "11 am" or "11 a.m."
                    ampm = match[2]?.toLowerCase().replace(/\./g, '') || '';
                }
                console.log(`🕐 Parsed: hours=${hours}, minutes=${minutes}, ampm="${ampm}"`);
                if (ampm === 'pm' && hours !== 12) {
                    hours += 12;
                }
                else if (ampm === 'am' && hours === 12) {
                    hours = 0;
                }
                const result = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
                console.log(`🕐 Final time: ${result}`);
                return result;
            }
        }
        return null;
    }
}
exports.DateNormalizer = DateNormalizer;
exports.dateNormalizer = new DateNormalizer();
//# sourceMappingURL=DateNormalizer.js.map