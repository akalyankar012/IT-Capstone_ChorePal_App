# ChorePal Voice Task Creation - Setup Guide

This guide will help you set up the end-to-end voice task creation feature for ChorePal.

## 🏗️ Architecture Overview

```
iOS App (SwiftUI) → Node.js Server → Google Cloud APIs
     ↓                    ↓              ↓
WAV Recording    →  Express Server  →  Speech-to-Text
AVSpeechSynthesizer →  Voice Routes  →  Vertex AI Gemini
```

## 📁 File Structure

```
/server/                          # Node.js backend
├── package.json                  # Dependencies
├── tsconfig.json                 # TypeScript config
├── src/
│   ├── index.ts                  # Express app
│   ├── routes/voice.ts           # Voice endpoints
│   ├── services/stt.ts           # Speech-to-Text
│   ├── services/gemini.ts        # Vertex AI Gemini
│   └── lib/                      # Utilities
├── test/                         # Unit tests
└── gcp/README.md               # GCP setup

/chorepal prototype/Voice/        # iOS voice components
├── WAVRecorder.swift            # Audio recording
├── SpeechBack.swift             # Text-to-speech
├── VoiceService.swift           # API communication
└── VoiceView.swift              # SwiftUI interface

/chorepal prototype/Models/
└── VoiceModels.swift            # Voice data models

/chorepal prototype/Services/
└── VoiceConfig.swift            # Configuration
```

## 🚀 Quick Start

### 1. Server Setup

```bash
# Navigate to server directory
cd server

# Install dependencies
npm install

# Set up environment
cp env.example .env
# Edit .env with your GCP project details

# Start development server
npm run dev
```

### 2. Google Cloud Setup

Follow the detailed guide in `server/gcp/README.md`:

1. Enable Speech-to-Text API
2. Enable Vertex AI API  
3. Create service account with required roles
4. Download JSON key as `gcp-sa.json`
5. Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable

### 3. iOS Integration

1. Add voice components to your Xcode project
2. Update `VoiceConfig.swift` with your server URL
3. Integrate with existing `ChoreService` for task saving

## 🧪 Testing

### Server Health Check

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "project": "chorepal-ios-app-472321",
  "region": "us-central1"
}
```

### Speech-to-Text Test

```bash
# Record a test audio file (WAV, 16kHz, mono)
curl -X POST http://localhost:3000/voice/stt \
  -H "Content-Type: audio/wav" \
  -H "x-phrase-hints: Emma,Zayn,points,tomorrow" \
  --data-binary @test-audio.wav
```

### Parse Test

```bash
curl -X POST http://localhost:3000/voice/parse \
  -H "Content-Type: application/json" \
  -d '{
    "transcript": "Make dishes for Emma tomorrow worth 20 points",
    "children": [
      {"id": "1", "name": "Emma"},
      {"id": "2", "name": "Zayn"}
    ]
  }'
```

## 📱 iOS Testing

### Device Configuration

1. **Simulator**: Use `http://localhost:3000`
2. **Physical Device**: Use your Mac's LAN IP (e.g., `http://192.168.1.100:3000`)

### Find Your Mac's IP

```bash
# On Mac, find your IP address
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Update `VoiceConfig.swift`:
```swift
self.apiBaseURL = "http://192.168.1.100:3000" // Your Mac's IP
```

## 🎯 Test Scenarios

### 1. Single Pass Success
**Input**: "Make dishes for Emma tomorrow worth 20 points"
**Expected**: Task created, confirmation spoken

### 2. Missing Information
**Input**: "Make dishes tomorrow"
**Expected**: Follow-up questions for child and points

### 3. Ambiguous Child
**Input**: "Make dishes for Em tomorrow"
**Expected**: "Did you mean Emma or Emily?"

### 4. Default Time
**Input**: "Take out trash Saturday"
**Expected**: Confirmation of 6 PM default time

## 🔧 Troubleshooting

### Server Issues

1. **"Permission denied"**
   - Check `GOOGLE_APPLICATION_CREDENTIALS` path
   - Verify service account roles

2. **"API not enabled"**
   - Enable Speech-to-Text and Vertex AI APIs
   - Wait 5-10 minutes for propagation

3. **"Billing not enabled"**
   - Link project to billing account
   - Verify $300 credits available

### iOS Issues

1. **"Network connection error"**
   - Check server URL in `VoiceConfig.swift`
   - Ensure server is running
   - Test with `curl` first

2. **"Recording failed"**
   - Check microphone permissions
   - Verify audio session setup

3. **"Speech not working"**
   - Check device volume
   - Verify `AVSpeechSynthesizer` setup

### Common Fixes

```bash
# Restart server
npm run dev

# Check server logs
tail -f server.log

# Test individual endpoints
curl -v http://localhost:3000/health
```

## 💰 Cost Monitoring

- **Speech-to-Text**: ~$0.006 per 15 seconds
- **Vertex AI Gemini**: ~$0.000075 per 1K characters
- **Estimated monthly cost**: $5-15 for moderate usage

## 🔒 Security Notes

- Never commit `gcp-sa.json` to version control
- Use environment variables for credentials
- Monitor API usage and costs
- Rotate service account keys regularly

## 📞 Support

If you encounter issues:

1. Check server logs for errors
2. Verify Google Cloud setup
3. Test individual components
4. Check network connectivity
5. Review iOS permissions

## 🎉 Success Criteria

The voice feature is working when:

- ✅ Server responds to health check
- ✅ Audio uploads and returns transcript
- ✅ Gemini parses transcript correctly
- ✅ iOS app speaks back to user
- ✅ Tasks are saved to Firestore
- ✅ End-to-end flow completes successfully
