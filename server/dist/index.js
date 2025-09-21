"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const voice_1 = __importDefault(require("./routes/voice"));
// Load environment variables
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Middleware
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use(express_1.default.raw({ type: 'audio/wav', limit: '10mb' }));
// Routes
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        project: process.env.GCP_PROJECT_ID,
        region: process.env.VERTEX_LOCATION,
        model: process.env.GEMINI_MODEL,
        credentials: process.env.GOOGLE_APPLICATION_CREDENTIALS ? 'Set' : 'Not set'
    });
});
app.use('/voice', voice_1.default);
// Test endpoint for direct Gemini testing
app.post('/test/gemini', async (req, res) => {
    try {
        const { parseTranscript } = await Promise.resolve().then(() => __importStar(require('./services/gemini')));
        const result = await parseTranscript({
            transcript: req.body.transcript || 'Make dishes for Emma tomorrow worth 20 points',
            children: req.body.children || [
                { id: '1', name: 'Emma' },
                { id: '2', name: 'Zayn' }
            ]
        });
        res.json(result);
    }
    catch (error) {
        console.error('Test Gemini error:', error);
        res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
});
// Error handling
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
});
app.listen(PORT, () => {
    console.log(`🚀 Voice server running on port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`🎤 STT endpoint: http://localhost:${PORT}/voice/stt`);
    console.log(`🤖 Parse endpoint: http://localhost:${PORT}/voice/parse`);
});
exports.default = app;
//# sourceMappingURL=index.js.map