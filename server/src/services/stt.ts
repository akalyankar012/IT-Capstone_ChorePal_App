import { SpeechClient } from '@google-cloud/speech';
import { STTRequest, STTResponse } from '../lib/schema';

const speechClient = new SpeechClient();

/**
 * Convert speech to text using Google Cloud Speech-to-Text
 */
export async function speechToText(request: STTRequest): Promise<STTResponse> {
  try {
    // Configure recognition request
    const config = {
      encoding: 'LINEAR16' as const,
      sampleRateHertz: 16000,
      languageCode: 'en-US',
      enableAutomaticPunctuation: true,
      model: 'latest_long', // Best accuracy for short utterances
    };

    // Add phrase hints if provided
    if (request.phraseHints && request.phraseHints.length > 0) {
      (config as any).speechContexts = [{
        phrases: request.phraseHints,
        boost: 20.0 // Boost confidence for these phrases
      }];
    }

    const audio = {
      content: request.audio.toString('base64'),
    };

    const recognitionRequest = {
      config,
      audio,
    };

    console.log('🎤 Sending audio to Google Speech-to-Text...');
    const [response] = await speechClient.recognize(recognitionRequest);
    
    if (!response.results || response.results.length === 0) {
      throw new Error('No speech detected in audio');
    }

    const transcript = response.results
      .map(result => result.alternatives?.[0]?.transcript)
      .filter(Boolean)
      .join(' ');

    if (!transcript) {
      throw new Error('No transcript generated');
    }

    console.log('✅ Transcript:', transcript);
    return { transcript: transcript };

  } catch (error) {
    console.error('❌ Speech-to-Text error:', error);
    throw new Error(`Speech-to-Text failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

