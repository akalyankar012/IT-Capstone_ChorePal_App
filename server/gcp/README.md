# Google Cloud Setup for ChorePal Voice Features

This guide will help you set up Google Cloud services for the ChorePal voice task creation feature.

## Prerequisites

- Google Cloud account with $300 credits
- Project ID: `chorepal-ios-app-472321`
- Region: `us-central1`

## Required APIs

Enable the following APIs in your Google Cloud Console:

1. **Cloud Speech-to-Text API**
   - Go to [APIs & Services > Library](https://console.cloud.google.com/apis/library)
   - Search for "Cloud Speech-to-Text API"
   - Click "Enable"

2. **Vertex AI API**
   - Go to [APIs & Services > Library](https://console.cloud.google.com/apis/library)
   - Search for "Vertex AI API"
   - Click "Enable"

## Service Account Setup

1. **Create Service Account**
   - Go to [IAM & Admin > Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
   - Click "Create Service Account"
   - Name: `chorepal-voice-service`
   - Description: `Service account for ChorePal voice features`

2. **Assign Roles**
   Add the following roles to your service account:
   - `Cloud Speech-to-Text Client`
   - `Vertex AI User`
   - `Storage Object Viewer` (if using Cloud Storage)

3. **Create and Download Key**
   - Click on your service account
   - Go to "Keys" tab
   - Click "Add Key" > "Create new key"
   - Choose "JSON" format
   - Download and save as `gcp-sa.json` in the server directory

## Environment Setup

1. **Set Environment Variable**
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/gcp-sa.json"
   ```

2. **Verify Setup**
   ```bash
   # Test Speech-to-Text
   curl -X POST "https://speech.googleapis.com/v1/speech:recognize" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d '{"config":{"encoding":"LINEAR16","sampleRateHertz":16000,"languageCode":"en-US"},"audio":{"content":"base64-encoded-audio"}}'

   # Test Vertex AI
   curl -X POST "https://us-central1-aiplatform.googleapis.com/v1/projects/chorepal-ios-app-472321/locations/us-central1/publishers/google/models/gemini-1.5-flash:generateContent"
   ```

## Billing Configuration

1. **Enable Billing**
   - Go to [Billing](https://console.cloud.google.com/billing)
   - Link your project to a billing account
   - Ensure you have $300 credits available

2. **Set Budget Alerts**
   - Go to [Billing > Budgets & Alerts](https://console.cloud.google.com/billing/budgets)
   - Create a budget for $250 (leaving $50 buffer)
   - Set up email alerts at 50%, 75%, and 90% usage

## Testing the Setup

1. **Start the Server**
   ```bash
   cd server
   npm install
   npm run dev
   ```

2. **Test Health Endpoint**
   ```bash
   curl http://localhost:3000/health
   ```

3. **Test STT Endpoint**
   ```bash
   curl -X POST http://localhost:3000/voice/stt \
     -H "Content-Type: audio/wav" \
     -H "x-phrase-hints: Emma,Zayn,points,tomorrow" \
     --data-binary @test-audio.wav
   ```

## Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   - Verify service account has correct roles
   - Check `GOOGLE_APPLICATION_CREDENTIALS` path
   - Ensure JSON key is valid

2. **"API not enabled" errors**
   - Enable required APIs in Google Cloud Console
   - Wait 5-10 minutes for propagation

3. **"Billing not enabled" errors**
   - Link project to billing account
   - Verify credits are available

4. **"Quota exceeded" errors**
   - Check API quotas in Google Cloud Console
   - Request quota increases if needed

### Cost Monitoring

- **Speech-to-Text**: ~$0.006 per 15 seconds
- **Vertex AI Gemini**: ~$0.000075 per 1K characters
- **Estimated monthly cost**: $5-15 for moderate usage

### Security Notes

- Never commit `gcp-sa.json` to version control
- Use environment variables for credentials
- Rotate service account keys regularly
- Monitor API usage and costs

## Next Steps

1. Test the server endpoints
2. Configure iOS app with correct server URL
3. Test end-to-end voice flow
4. Monitor costs and usage
