import { VoiceSession } from '../models/VoiceSession';

class VoiceSessionStore {
  private sessions: Map<string, VoiceSession> = new Map();
  private readonly TTL_MINUTES = 15;

  createSession(sessionId: string, childrenRoster: Array<{id: string; name: string}>, userId?: string): VoiceSession {
    const now = new Date();
    const expiresAt = new Date(now.getTime() + this.TTL_MINUTES * 60 * 1000);
    
    const session: VoiceSession = {
      sessionId,
      slots: {},
      missing: ['assignedChild', 'title', 'due', 'points'],
      childrenRoster,
      status: 'in_progress',
      createdAt: now,
      expiresAt,
      userId: userId,
      lastTurnIndex: -1,
      lastTurnId: undefined
    };

    this.sessions.set(sessionId, session);
    return session;
  }

  getSession(sessionId: string): VoiceSession | undefined {
    const session = this.sessions.get(sessionId);
    if (!session) return undefined;
    
    // Check if expired
    if (new Date() > session.expiresAt) {
      this.sessions.delete(sessionId);
      return undefined;
    }
    
    return session;
  }

  updateSession(sessionId: string, updates: Partial<VoiceSession>): VoiceSession | undefined {
    const session = this.getSession(sessionId);
    if (!session) return undefined;

    const updatedSession = { ...session, ...updates };
    this.sessions.set(sessionId, updatedSession);
    return updatedSession;
  }

  deleteSession(sessionId: string): boolean {
    return this.sessions.delete(sessionId);
  }

  // Clean up expired sessions
  cleanup(): void {
    const now = new Date();
    for (const [sessionId, session] of this.sessions.entries()) {
      if (now > session.expiresAt) {
        this.sessions.delete(sessionId);
      }
    }
  }

  // Get session count for monitoring
  getSessionCount(): number {
    return this.sessions.size;
  }

  // Get sessions by user ID
  getSessionsByUser(userId: string): VoiceSession[] {
    const userSessions: VoiceSession[] = [];
    for (const session of this.sessions.values()) {
      if (session.userId === userId) {
        userSessions.push(session);
      }
    }
    return userSessions;
  }

  // Get active sessions by user ID
  getActiveSessionsByUser(userId: string): VoiceSession[] {
    return this.getSessionsByUser(userId).filter(session => session.status === 'in_progress');
  }
}

export const voiceSessionStore = new VoiceSessionStore();

// Clean up expired sessions every 5 minutes
setInterval(() => {
  voiceSessionStore.cleanup();
}, 5 * 60 * 1000);
