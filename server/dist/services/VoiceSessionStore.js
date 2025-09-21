"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.voiceSessionStore = void 0;
class VoiceSessionStore {
    constructor() {
        this.sessions = new Map();
        this.TTL_MINUTES = 15;
    }
    createSession(sessionId, childrenRoster, userId) {
        const now = new Date();
        const expiresAt = new Date(now.getTime() + this.TTL_MINUTES * 60 * 1000);
        const session = {
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
    getSession(sessionId) {
        const session = this.sessions.get(sessionId);
        if (!session)
            return undefined;
        // Check if expired
        if (new Date() > session.expiresAt) {
            this.sessions.delete(sessionId);
            return undefined;
        }
        return session;
    }
    updateSession(sessionId, updates) {
        const session = this.getSession(sessionId);
        if (!session)
            return undefined;
        const updatedSession = { ...session, ...updates };
        this.sessions.set(sessionId, updatedSession);
        return updatedSession;
    }
    deleteSession(sessionId) {
        return this.sessions.delete(sessionId);
    }
    // Clean up expired sessions
    cleanup() {
        const now = new Date();
        for (const [sessionId, session] of this.sessions.entries()) {
            if (now > session.expiresAt) {
                this.sessions.delete(sessionId);
            }
        }
    }
    // Get session count for monitoring
    getSessionCount() {
        return this.sessions.size;
    }
    // Get sessions by user ID
    getSessionsByUser(userId) {
        const userSessions = [];
        for (const session of this.sessions.values()) {
            if (session.userId === userId) {
                userSessions.push(session);
            }
        }
        return userSessions;
    }
    // Get active sessions by user ID
    getActiveSessionsByUser(userId) {
        return this.getSessionsByUser(userId).filter(session => session.status === 'in_progress');
    }
}
exports.voiceSessionStore = new VoiceSessionStore();
// Clean up expired sessions every 5 minutes
setInterval(() => {
    exports.voiceSessionStore.cleanup();
}, 5 * 60 * 1000);
//# sourceMappingURL=VoiceSessionStore.js.map