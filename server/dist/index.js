"use strict";
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