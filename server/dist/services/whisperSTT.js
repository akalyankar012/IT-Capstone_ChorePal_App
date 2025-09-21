"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.speechToText = speechToText;
const node_fetch_1 = __importDefault(require("node-fetch"));
require('dotenv').config();
/**
 * Convert speech to text using OpenAI Whisper API
 */
async function speechToText(request) {
    try {
        console.log('🎤 Sending audio to OpenAI Whisper...');
        // Create FormData for multipart upload
        const formData = new FormData();
        const audioBlob = new Blob([request.audio], { type: 'audio/wav' });
        formData.append('file', audioBlob, 'audio.wav');
        formData.append('model', 'whisper-1');
        formData.append('language', 'en');
        formData.append('response_format', 'json');
        // Make request to OpenAI Whisper API
        const response = await (0, node_fetch_1.default)('https://api.openai.com/v1/audio/transcriptions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
            },
            body: formData
        });
        if (!response.ok) {
            const errorText = await response.text();
            console.error('❌ Whisper API error:', response.status, errorText);
            throw new Error(`Whisper API failed: ${response.status} - ${errorText}`);
        }
        const result = await response.json();
        const transcript = result.text || '';
        console.log('✅ Whisper transcript:', transcript);
        return { transcript };
    }
    catch (error) {
        console.error('❌ Whisper STT error:', error);
        throw new Error(`Speech-to-Text failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
}
//# sourceMappingURL=whisperSTT.js.map