const { VertexAI } = require('@google-cloud/vertexai');

// Load environment variables
require('dotenv').config();

const projectId = process.env.GCP_PROJECT_ID || 'chorepal-ios-app-472321';
const location = process.env.VERTEX_LOCATION || 'us-central1';
const model = process.env.GEMINI_MODEL || 'gemini-1.5-flash';

console.log('🔧 Debug Configuration:');
console.log(`   Project ID: ${projectId}`);
console.log(`   Location: ${location}`);
console.log(`   Model: ${model}`);
console.log(`   Credentials: ${process.env.GOOGLE_APPLICATION_CREDENTIALS || 'Not set'}`);

// Initialize Vertex AI
const vertexAI = new VertexAI({ 
  project: projectId, 
  location: location 
});

async function testGemini() {
  try {
    console.log('\n🧪 Testing Gemini model...');
    
    const generativeModel = vertexAI.getGenerativeModel({ 
      model,
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.1,
        maxOutputTokens: 1000
      }
    });
    
    const result = await generativeModel.generateContent([
      { role: 'user', parts: [{ text: 'Say "Hello World" in JSON format: {"message": "Hello World"}' }] }
    ]);
    
    const response = await result.response;
    const text = response.text();
    
    console.log('✅ Success! Response:', text);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Full error:', error);
  }
}

testGemini();

