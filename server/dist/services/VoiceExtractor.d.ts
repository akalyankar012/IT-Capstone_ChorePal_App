import { SlotDelta } from '../models/VoiceSession';
export declare class VoiceExtractor {
    private model;
    extractSlotDelta(utterance: string, currentSlots: any, expectedSlot: string | undefined, childrenRoster: Array<{
        id: string;
        name: string;
    }>): Promise<SlotDelta>;
}
export declare const voiceExtractor: VoiceExtractor;
//# sourceMappingURL=VoiceExtractor.d.ts.map