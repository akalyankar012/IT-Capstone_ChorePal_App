const { GoogleGenerativeAI } = require('@google/generative-ai');

// Test with Generative AI API directly
async function testGenerativeAI() {
  try {
    console.log('🧪 Testing Generative AI API...');
    
    // This uses the Generative AI API (not Vertex AI)
    const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY || 'test-key');
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    const result = await model.generateContent("Hello, how are you?");
    const response = await result.response;
    const text = response.text();
    
    console.log('✅ Generative AI API response:', text);
    return true;
  } catch (error) {
    console.error('❌ Generative AI API error:', error.message);
    return false;
  }
}

testGenerativeAI();

