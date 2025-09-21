import { VoiceSession, SlotDelta, VoiceResponse } from '../models/VoiceSession';
export declare class VoiceMergeLogic {
    private readonly SLOT_ORDER;
    mergeSlotUpdates(session: VoiceSession, delta: SlotDelta): VoiceSession;
    private computeMissingSlots;
    private getNextExpectedSlot;
    generateResponse(session: VoiceSession, delta: SlotDelta): VoiceResponse;
    private formatDueDate;
    private generateFollowUpQuestion;
    private formatTaskConfirmation;
}
export declare const voiceMergeLogic: VoiceMergeLogic;
//# sourceMappingURL=VoiceMergeLogic.d.ts.map