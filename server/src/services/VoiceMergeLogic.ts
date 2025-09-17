import { VoiceSession, SlotDelta, VoiceResponse } from '../models/VoiceSession';

export class VoiceMergeLogic {
  // Deterministic slot order
  private readonly SLOT_ORDER = ['assignedChild', 'title', 'due', 'points'];

  mergeSlotUpdates(session: VoiceSession, delta: SlotDelta): VoiceSession {
    console.log('Merging slot updates:', delta);
    console.log('Current session slots:', session.slots);
    
    const updatedSlots = { ...session.slots };
    
    // Merge slot updates
    Object.entries(delta.slot_updates).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        console.log(`Setting ${key} to ${value}`);
        (updatedSlots as any)[key] = value;
      }
    });

    // Handle child name to ID mapping
    if (updatedSlots.assignedChildName && !updatedSlots.assignedChildId) {
      const child = session.childrenRoster.find(c => 
        c.name.toLowerCase() === updatedSlots.assignedChildName!.toLowerCase()
      );
      if (child) {
        console.log(`Mapped child name ${updatedSlots.assignedChildName} to ID ${child.id}`);
        updatedSlots.assignedChildId = child.id;
      } else {
        console.log(`Could not find child with name ${updatedSlots.assignedChildName} in roster`);
      }
    }

    // Recompute missing slots
    const missing = this.computeMissingSlots(updatedSlots);
    
    // Determine next expected slot
    const expectedSlot = this.getNextExpectedSlot(missing, delta.ambiguous);

    return {
      ...session,
      slots: updatedSlots,
      missing,
      expectedSlot,
      status: missing.length === 0 ? 'ready_to_create' : 'in_progress'
    };
  }

  private computeMissingSlots(slots: any): string[] {
    const missing: string[] = [];
    
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

  private getNextExpectedSlot(missing: string[], ambiguous?: string[]): string | undefined {
    if (ambiguous && ambiguous.length > 0) {
      return ambiguous[0];
    }
    
    if (missing.length === 0) return undefined;
    
    // Return first missing slot in deterministic order
    for (const slot of this.SLOT_ORDER) {
      if (missing.includes(slot)) {
        return slot as any;
      }
    }
    
    return undefined;
  }

  generateResponse(session: VoiceSession, delta: SlotDelta): VoiceResponse {
    // Handle cancellation
    if (delta.intent === 'cancel') {
      return {
        type: 'cancelled',
        speak: 'Task creation cancelled.',
        sessionId: session.sessionId
      };
    }

    // Handle ambiguous cases
    if (delta.ambiguous && delta.ambiguous.length > 0) {
      const ambiguousSlot = delta.ambiguous[0];
      let speak = '';
      
      if (ambiguousSlot === 'assignedChild') {
        const matchingChildren = session.childrenRoster.filter(c => 
          c.name.toLowerCase().includes(delta.slot_updates.assignedChildName?.toLowerCase() || '')
        );
        const names = matchingChildren.map(c => c.name).join(', ');
        speak = `Which child: ${names}?`;
      }
      
      return {
        type: 'ambiguous',
        speak,
        sessionId: session.sessionId
      };
    }

    // Handle completion
    if (session.status === 'ready_to_create') {
      const task = this.formatTaskConfirmation(session);
      return {
        type: 'confirmed',
        speak: task,
        parsed: {
          childId: session.slots.assignedChildId,
          title: session.slots.title,
          dueAt: session.slots.dueIso,
          points: session.slots.points
        },
        sessionId: session.sessionId
      };
    }

    // Handle follow-up questions
    if (session.expectedSlot) {
      const question = this.generateFollowUpQuestion(session.expectedSlot);
      return {
        type: 'followup',
        speak: question,
        sessionId: session.sessionId
      };
    }

    // Fallback
    return {
      type: 'followup',
      speak: 'I need more information to create this task.',
      sessionId: session.sessionId
    };
  }

  private generateFollowUpQuestion(expectedSlot: string): string {
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

  private formatTaskConfirmation(session: VoiceSession): string {
    const { slots } = session;
    const childName = session.childrenRoster.find(c => c.id === slots.assignedChildId)?.name || 'Unknown';
    const title = slots.title || 'Unknown task';
    const points = slots.points || 0;
    
    let dueText = '';
    if (slots.dueIso) {
      const dueDate = new Date(slots.dueIso);
      const isToday = dueDate.toDateString() === new Date().toDateString();
      const isTomorrow = dueDate.toDateString() === new Date(Date.now() + 24 * 60 * 60 * 1000).toDateString();
      
      if (isToday) {
        dueText = ' due today';
      } else if (isTomorrow) {
        dueText = ' due tomorrow';
      } else {
        dueText = ` due ${dueDate.toLocaleDateString()}`;
      }
    }
    
    return `Added '${title}' for ${childName}${dueText}, for ${points} points.`;
  }
}

export const voiceMergeLogic = new VoiceMergeLogic();
