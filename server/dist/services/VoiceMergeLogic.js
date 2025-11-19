"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.voiceMergeLogic = exports.VoiceMergeLogic = void 0;
class VoiceMergeLogic {
    constructor() {
        // Deterministic slot order
        this.SLOT_ORDER = ['assignedChild', 'title', 'due', 'points'];
    }
    mergeSlotUpdates(session, delta) {
        console.log('🔄 Smart merge:', delta.slot_updates);
        const updatedSlots = { ...session.slots };
        // Smart merge - copy updates and handle special cases
        Object.assign(updatedSlots, delta.slot_updates);
        // Map child name to ID if needed
        if (updatedSlots.assignedChildName && !updatedSlots.assignedChildId) {
            const child = session.childrenRoster.find(c => c.name.toLowerCase() === updatedSlots.assignedChildName.toLowerCase());
            if (child) {
                updatedSlots.assignedChildId = child.id;
            }
        }
        // Smart missing field detection
        const missing = [];
        // Check for assigned child - handle both known and unknown children
        if (!updatedSlots.assignedChildId && !updatedSlots.assignedChildName) {
            missing.push('assignedChild');
        }
        else if (updatedSlots.assignedChildName && !updatedSlots.assignedChildId) {
            // Check if the mentioned child exists in the roster
            const childExists = session.childrenRoster.some(c => c.name.toLowerCase() === updatedSlots.assignedChildName.toLowerCase());
            if (!childExists) {
                // Unknown child - we'll handle this in the response
                console.log(`⚠️ Unknown child mentioned: ${updatedSlots.assignedChildName}`);
                // Don't add to missing, but we'll need to handle this in the response
            }
        }
        // Check for title
        if (!updatedSlots.title) {
            missing.push('title');
        }
        // Check for due date
        if (!updatedSlots.dueIso && !updatedSlots.dueText) {
            missing.push('due');
        }
        // Check for points
        if (!updatedSlots.points) {
            missing.push('points');
        }
        return {
            ...session,
            slots: updatedSlots,
            missing,
            expectedSlot: missing[0] || undefined,
            status: missing.length === 0 ? 'ready_to_create' : 'in_progress'
        };
    }
    computeMissingSlots(slots) {
        const missing = [];
        if (!slots.assignedChildId && !slots.assignedChildName) {
            missing.push('assignedChild');
        }
        if (!slots.title) {
            missing.push('title');
        }
        if (!slots.dueIso && !slots.dueText) {
            missing.push('due');
        }
        if (!slots.points) {
            missing.push('points');
        }
        return missing;
    }
    getNextExpectedSlot(missing, ambiguous) {
        if (ambiguous && ambiguous.length > 0) {
            return ambiguous[0];
        }
        if (missing.length === 0)
            return undefined;
        // Return first missing slot in deterministic order
        for (const slot of this.SLOT_ORDER) {
            if (missing.includes(slot)) {
                return slot;
            }
        }
        return undefined;
    }
    generateResponse(session, delta) {
        console.log('🎯 Smart response for:', session.missing);
        // Check for unknown child
        if (session.slots.assignedChildName && !session.slots.assignedChildId) {
            const childExists = session.childrenRoster.some(c => c.name.toLowerCase() === session.slots.assignedChildName.toLowerCase());
            if (!childExists) {
                const availableChildren = session.childrenRoster.map(c => c.name).join(', ');
                return {
                    type: 'followup',
                    speak: `I don't recognize "${session.slots.assignedChildName}". Available children are: ${availableChildren}. Who should I assign this to?`,
                    sessionId: session.sessionId
                };
            }
        }
        // Task is complete
        if (session.missing.length === 0) {
            const childName = session.childrenRoster.find(c => c.id === session.slots.assignedChildId)?.name || 'Unknown';
            const dueText = this.formatDueDate(session.slots.dueIso, session.slots.dueText);
            return {
                type: 'confirmed',
                speak: `Added "${session.slots.title}" for ${childName}, due ${dueText}, for ${session.slots.points} points.`,
                parsed: {
                    childId: session.slots.assignedChildId,
                    title: session.slots.title,
                    dueAt: session.slots.dueIso ? new Date(session.slots.dueIso).getTime().toString() : "0", // Send Unix timestamp as string
                    points: session.slots.points
                },
                sessionId: session.sessionId
            };
        }
        // Ask for missing info with context
        const missing = session.missing[0];
        let question = '';
        if (missing === 'assignedChild') {
            const childNames = session.childrenRoster.map(c => c.name).join(', ');
            question = `Who should I assign this to? (${childNames})`;
        }
        else if (missing === 'title') {
            question = 'What task should I create?';
        }
        else if (missing === 'due') {
            question = 'When is this due?';
        }
        else if (missing === 'points') {
            question = 'How many points is this worth?';
        }
        return {
            type: 'followup',
            speak: question,
            sessionId: session.sessionId
        };
    }
    formatDueDate(dueIso, dueText) {
        // Always use the parsed ISO date for accurate time formatting
        if (!dueIso)
            return dueText || 'today';
        const dueDate = new Date(dueIso);
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
        // Format time in 12-hour format
        const timeString = dueDate.toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZone: 'America/Chicago'
        });
        if (dueDate.toDateString() === today.toDateString()) {
            return `today at ${timeString}`;
        }
        else if (dueDate.toDateString() === tomorrow.toDateString()) {
            return `tomorrow at ${timeString}`;
        }
        else {
            return `${dueDate.toLocaleDateString()} at ${timeString}`;
        }
    }
    generateFollowUpQuestion(expectedSlot) {
        switch (expectedSlot) {
            case 'assignedChild':
                return 'Who should I assign this to?';
            case 'title':
                return 'What task should I create?';
            case 'due':
                return 'When is it due?';
            case 'points':
                return 'How many points?';
            default:
                return 'I need more information.';
        }
    }
    formatTaskConfirmation(session) {
        const { slots } = session;
        const childName = session.childrenRoster.find(c => c.id === slots.assignedChildId)?.name || 'Unknown';
        const title = slots.title || 'Unknown task';
        const points = slots.points || 0;
        let dueText = '';
        if (slots.dueIso) {
            const dueDate = new Date(slots.dueIso);
            const isToday = dueDate.toDateString() === new Date().toDateString();
            const isTomorrow = dueDate.toDateString() === new Date(Date.now() + 24 * 60 * 60 * 1000).toDateString();
            // Format time in 12-hour format
            const timeString = dueDate.toLocaleTimeString('en-US', {
                hour: 'numeric',
                minute: '2-digit',
                hour12: true,
                timeZone: 'America/Chicago'
            });
            if (isToday) {
                dueText = ` due today at ${timeString}`;
            }
            else if (isTomorrow) {
                dueText = ` due tomorrow at ${timeString}`;
            }
            else {
                dueText = ` due ${dueDate.toLocaleDateString()} at ${timeString}`;
            }
        }
        return `Added '${title}' for ${childName}${dueText}, for ${points} points.`;
    }
}
exports.VoiceMergeLogic = VoiceMergeLogic;
exports.voiceMergeLogic = new VoiceMergeLogic();
//# sourceMappingURL=VoiceMergeLogic.js.map