import { STTRequest, STTResponse } from '../lib/schema';
import fetch from 'node-fetch';

require('dotenv').config();

/**
 * Convert speech to text using OpenAI Whisper API
 */
export async function speechToText(request: STTRequest): Promise<STTResponse> {
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
    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
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

    const result = await response.json() as any;
    const transcript = result.text || '';
    
    console.log('✅ Whisper transcript:', transcript);
    
    return { transcript };
    
  } catch (error) {
    console.error('❌ Whisper STT error:', error);
    throw new Error(`Speech-to-Text failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
