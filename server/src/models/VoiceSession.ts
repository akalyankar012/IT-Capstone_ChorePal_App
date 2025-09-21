export interface VoiceSession {
  sessionId: string;
  slots: {
    assignedChildId?: string;
    assignedChildName?: string;
    title?: string;
    dueText?: string;
    dueIso?: string;
    points?: number;
  };
  missing: string[];
  expectedSlot?: 'assignedChild' | 'title' | 'due' | 'points';
  childrenRoster: Array<{id: string; name: string}>;
  lastAiPrompt?: string;
  status: 'in_progress' | 'ready_to_create' | 'completed' | 'cancelled';
  createdAt: Date;
  expiresAt: Date;
  userId?: string;
  lastTurnIndex: number;
  lastTurnId?: string;
}

export interface SlotDelta {
  intent: 'answer' | 'revise' | 'new_task' | 'cancel' | 'noop';
  slot_updates: Partial<{
    assignedChildId?: string;
    assignedChildName?: string;
    title?: string;
    dueText?: string;
    points?: number;
  }>;
  ambiguous?: string[];
  notes?: string;
}

export interface VoiceResponse {
  type: 'followup' | 'confirmed' | 'cancelled' | 'ambiguous';
  speak: string;
  parsed?: {
    childId?: string;
    title?: string;
    dueAt?: string;
    points?: number;
  };
  sessionId: string;
}
