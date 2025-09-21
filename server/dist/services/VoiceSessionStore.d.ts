import { VoiceSession } from '../models/VoiceSession';
declare class VoiceSessionStore {
    private sessions;
    private readonly TTL_MINUTES;
    createSession(sessionId: string, childrenRoster: Array<{
        id: string;
        name: string;
    }>, userId?: string): VoiceSession;
    getSession(sessionId: string): VoiceSession | undefined;
    updateSession(sessionId: string, updates: Partial<VoiceSession>): VoiceSession | undefined;
    deleteSession(sessionId: string): boolean;
    cleanup(): void;
    getSessionCount(): number;
    getSessionsByUser(userId: string): VoiceSession[];
    getActiveSessionsByUser(userId: string): VoiceSession[];
}
export declare const voiceSessionStore: VoiceSessionStore;
export {};
//# sourceMappingURL=VoiceSessionStore.d.ts.map